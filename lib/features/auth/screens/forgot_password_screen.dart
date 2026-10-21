import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';

/// Two steps on one screen:
///   1) enter your email  ->  the server creates a reset code
///   2) enter the code + a new password
///
/// The server emails a 6-digit code (valid 10 minutes). While the server has no
/// email set up (development), it returns the code and this screen fills it in.
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
  int _cooldown = 0;
  Timer? _timer;
  String? _message;
  String? _error;

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          _message = 'If this email has an account, a 6-digit code was sent.';
          if (devToken != null) _code.text = devToken;
        });
        _startCooldown();
      });

  Future<void> _resend() async {
    if (_busy || _cooldown > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final devCode = await AuthService.instance.resendCode(_email.text.trim(), purpose: 'reset');
      if (!mounted) return;
      setState(() {
        _message = 'A new code was sent.';
        if (devCode != null) _code.text = devCode;
      });
      _startCooldown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() => _run(() async {
        await AuthService.instance.resetPassword(
          email: _email.text.trim(),
          code: _code.text.trim(),
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
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          autofillHints: const [AutofillHints.oneTimeCode],
                          decoration: const InputDecoration(
                            hintText: '6-digit code',
                            counterText: '',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (v) =>
                              RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'Enter the 6-digit code',
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
                      if (_codeSent)
                        TextButton(
                          onPressed: (_busy || _cooldown > 0) ? null : _resend,
                          child: Text(_cooldown > 0 ? 'Send a new code in ${_cooldown}s' : 'Send a new code'),
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