import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_session.dart';

/// Edit the student profile. This is a step INSIDE Settings, so it keeps a
/// back arrow (the main screens use the ☰ menu instead).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppUser _original =
      UserSession.instance.user ??
      const AppUser(name: UserSession.fallbackName, email: '');
  late final _name = TextEditingController(text: _original.name);
  late final _email = TextEditingController(text: _original.email);
  late final _university = TextEditingController(text: _original.university);
  late int _semester = _original.semester;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _university.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    UserSession.instance.updateProfile(
      _original.copyWith(
        name: _name.text.trim(),
        email: _email.text.trim(),
        university: _university.text.trim(),
        semester: _semester,
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final initial = _name.text.trim().isEmpty
        ? '?'
        : _name.text.trim()[0].toUpperCase();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  AppHeader(
                    leading: HeaderButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 17,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    title: Text(
                      'Edit profile',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: c.gradientStart.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: c.gradientStart,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _label('Name'),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name cannot be empty'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _label('Email'),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              final ok = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value);
                              return ok ? null : 'Enter a valid email address';
                            },
                          ),
                          const SizedBox(height: 16),
                          _label('University'),
                          TextFormField(controller: _university),
                          const SizedBox(height: 16),
                          _label('Semester'),
                          DropdownButtonFormField<int>(
                            initialValue: _semester,
                            items: [
                              for (var i = 1; i <= 8; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('Semester $i'),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _semester = v ?? _semester),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      s,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colors.textMuted,
      ),
    ),
  );
}