import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../data/services/auth_service.dart';
import '../../home/screens/home_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

enum _Mode { login, register }

/// First screen after onboarding (and after "Sign out").
/// Sign in with email + password, or create a new account.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.login;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  bool get _isLogin => _mode == _Mode.login;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter your name' : null;

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Please enter your password';
    if (!_isLogin && value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  void _switchMode() => setState(() {
        _mode = _isLogin ? _Mode.register : _Mode.login;
        _error = null;
      });

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      final auth = AuthService.instance;
      if (_isLogin) {
        final user = await auth.login(email: email, password: _password.text);
        _goHome(user.name);
      } else {
        final result = await auth.register(
          name: _name.text.trim(),
          email: email,
          password: _password.text,
        );
        if (result.user != null) {
          _goHome(result.user!.name); // offline mode: no code needed
        } else {
          _openCodeScreen(email, devCode: result.devCode);
        }
      }
    } on ApiException catch (e) {
      if (e.code == 'email_not_verified') {
        // Correct password, but the email was never confirmed.
        _openCodeScreen(email, sendOnOpen: true);
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goHome(String userName) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => DashboardScreen(userName: userName)),
      (route) => false,
    );
  }

  void _openCodeScreen(String email, {String? devCode, bool sendOnOpen = false}) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerifyEmailScreen(
          email: email,
          devCode: devCode,
          sendOnOpen: sendOnOpen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandLogo(size: 88)),
                      const SizedBox(height: 20),
                      Text(
                        _isLogin ? 'Welcome back' : 'Create your account',
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Sign in to continue learning with your AI tutor.'
                            : 'Tell us who you are so your AI tutor can personalise your lessons.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: c.textMuted),
                      ),
                      const SizedBox(height: 28),
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            hintText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'Student email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _isLogin
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: _isLogin ? 'Password' : 'Password (8+ characters)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ForgotPasswordScreen(
                                          initialEmail: _email.text.trim(),
                                        ),
                                      ),
                                    ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: errorColor),
                        ),
                      ],
                      SizedBox(height: _isLogin ? 8 : 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isLogin ? 'Sign in' : 'Create account'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy ? null : _switchMode,
                        child: Text(
                          _isLogin
                              ? "New here? Create an account"
                              : 'Already have an account? Sign in',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}