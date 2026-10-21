import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../home/screens/home_screen.dart';

/// Step 2 of sign-up: type the 6-digit code that was emailed.
///
/// While the server has no email set up (development) it returns the code and
/// this screen fills it in; the code is also printed in the backend terminal.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.devCode,
    this.sendOnOpen = false,
  });

  final String email;
  final String? devCode;

  /// true when the student came from "Sign in" with an unverified email:
  /// no code was sent yet, so ask the server for one now.
  final bool sendOnOpen;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _message;
  int _cooldown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.devCode != null) _code.text = widget.devCode!;
    _startCooldown();
    if (widget.sendOnOpen) _resend(force: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final user = await AuthService.instance.verifyEmail(
        email: widget.email,
        code: _code.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => DashboardScreen(userName: user.name)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend({bool force = false}) async {
    if (_busy || (!force && _cooldown > 0)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final devCode = await AuthService.instance.resendCode(widget.email);
      if (!mounted) return;
      setState(() {
        _message = 'We sent a new code to ${widget.email}.';
        if (devCode != null) _code.text = devCode;
      });
      _startCooldown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verify your email'),
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
                      Icon(Icons.mark_email_read_outlined, size: 56, color: c.gradientStart),
                      const SizedBox(height: 16),
                      Text(
                        'We sent a 6-digit code to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The code works for 10 minutes.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: c.textMuted),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _code,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        autofillHints: const [AutofillHints.oneTimeCode],
                        style: text.headlineSmall?.copyWith(letterSpacing: 10, fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(hintText: '······', counterText: ''),
                        onFieldSubmitted: (_) => _verify(),
                        validator: (v) =>
                            RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'Enter the 6-digit code',
                      ),
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
                        onPressed: _busy ? null : _verify,
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: (_busy || _cooldown > 0) ? null : _resend,
                        child: Text(
                          _cooldown > 0 ? 'Send a new code in ${_cooldown}s' : 'Send a new code',
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
