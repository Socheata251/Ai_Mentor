import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';

/// Two steps on one screen:
///   1) enter your email  ->  the server creates a reset code
///   2) enter the code + a new password
///
/// TODO(backend): the server must email the code. Until an email provider is
/// connected, the server (outside production) returns the code in its
/// response and this screen fills it in for you, which is fine for a class demo.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        final devToken = await AuthService.instance.forgotPassword(_email.text.trim());
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _message = 'If this email has an account, a reset code was sent.';
          if (devToken != null) _code.text = devToken;
        });
      });

  Future<void> _reset() => _run(() async {
        await AuthService.instance.resetPassword(
          token: _code.text.trim(),
          newPassword: _password.text,
        );
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Password changed. Please sign in.')),
        );
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reset password'),
      ),
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
                      Text(
                        _codeSent
                            ? 'Enter the code and choose a new password.'
                            : 'Enter your student email and we will send you a reset code.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: c.textMuted),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Student email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                          return ok ? null : 'Enter a valid email address';
                        },
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _code,
                          decoration: const InputDecoration(
                            hintText: 'Reset code',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 10) ? 'Enter the reset code' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'New password (8+ characters)',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!, textAlign: TextAlign.center, style: text.bodyMedium),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: errorColor),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_codeSent ? 'Change password' : 'Send reset code'),
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