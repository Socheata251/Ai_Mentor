import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../data/repositories/user_session.dart';
import '../../../main.dart' show themeMode;
import '../../auth/screens/sign_in_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../providers/settings_controller.dart';
import '../../../core/widgets/app_shell.dart';

/// Orange used for the toggles in your design.
const _accent = Color(0xFFD2693A);

/// Footer text. Edit when you ship a new build.
const kAppVersionLabel = 'IT Mentor AI • Version 2.4 (iOS Build 104)';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.name,
    this.email,
    this.onSignOut,
  });

  /// Optional overrides. By default the signed-in student is shown.
  final String? name;
  final String? email;

  /// Optional override. By default signing out clears the session and opens
  /// the sign-in screen.
  final VoidCallback? onSignOut;
  Future<void> _pick(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: o == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null) onPicked(choice);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to keep learning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign out',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    if (onSignOut != null) {
      onSignOut!();
      return;
    }
    UserSession.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      smoothPageRoute<void>(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final divider = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return AppShell(selectedIndex: 7, child: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? theme.scaffoldBackgroundColor : null,
          gradient: isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE4EEFC),
                    Color(0xFFF2F6FB),
                    Color(0xFFE9F0F8),
                  ],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  _Entrance(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x141B2A4A),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                      ),
                      // Material (not a plain Container) so tap ripples show.
                      child: Material(
                        color: c.card,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ListenableBuilder(
                            listenable: Listenable.merge([appSettings, UserSession.instance]),
                            builder: (context, _) => Column(
                              children: [
                                _ProfileTile(
                                  name: name ?? UserSession.instance.name,
                                  email: email ?? UserSession.instance.email,
                                ),

                                // ---- Appearance ----
                                _Divider(color: divider),
                                const _SectionLabel('Appearance'),
                                _SettingRow(
                                  icon: Icons.dark_mode_outlined,
                                  label: 'Dark mode',
                                  onTap: () => themeMode.value = isDark
                                      ? ThemeMode.light
                                      : ThemeMode.dark,
                                  trailing: _AccentSwitch(
                                    value: isDark,
                                    onChanged: (v) => themeMode.value = v
                                        ? ThemeMode.dark
                                        : ThemeMode.light,
                                  ),
                                ),

                                // ---- Tutor preferences ----
                                _Divider(color: divider),
                                const _SectionLabel('Tutor preferences'),
                                _SettingRow(
                                  icon: Icons.translate_rounded,
                                  label: 'Response language',
                                  value: appSettings.language,
                                  onTap: () => _pick(
                                    context,
                                    title: 'Response language',
                                    options: SettingsController.languages,
                                    current: appSettings.language,
                                    onPicked: appSettings.setLanguage,
                                  ),
                                ),
                                _SettingRow(
                                  icon: Icons.lightbulb_outline_rounded,
                                  label: 'Hints before full answers',
                                  onTap: () => appSettings.setHintsFirst(
                                    !appSettings.hintsFirst,
                                  ),
                                  trailing: _AccentSwitch(
                                    value: appSettings.hintsFirst,
                                    onChanged: appSettings.setHintsFirst,
                                  ),
                                ),

                                // ---- AI Engine & Code ----
                                _Divider(color: divider),
                                const _SectionLabel('AI Engine & Code'),
                                _SettingRow(
                                  icon: Icons.auto_awesome_outlined,
                                  label: 'Default AI Model',
                                  value: appSettings.aiModel,
                                  onTap: () => _pick(
                                    context,
                                    title: 'Default AI Model',
                                    options: SettingsController.aiModels,
                                    current: appSettings.aiModel,
                                    onPicked: appSettings.setAiModel,
                                  ),
                                ),
                                _SettingRow(
                                  icon: Icons.code_rounded,
                                  label: 'Code formatting',
                                  value: appSettings.codeFormat,
                                  onTap: () => _pick(
                                    context,
                                    title: 'Code formatting',
                                    options: SettingsController.codeFormats,
                                    current: appSettings.codeFormat,
                                    onPicked: appSettings.setCodeFormat,
                                  ),
                                ),

                                // ---- Account ----
                                _Divider(color: divider),
                                const _SectionLabel('Account'),
                                InkWell(
                                  onTap: () => _confirmSignOut(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Sign out',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      kAppVersionLabel,
                      style: TextStyle(fontSize: 11.5, color: c.textSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

// =====================================================================
// Pieces
// =====================================================================

/// ☰ menu button + title + "IT MENTOR AI" pill.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        const AppMenuButton(),
        const SizedBox(width: 4),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c.textStrong,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F7CFF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'IT MENTOR AI',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final primary = Theme.of(context).colorScheme.primary;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        smoothPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: c.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: context.colors.textSoft,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, thickness: 1, color: color),
  );
}

/// One settings row: icon, label, and either a value + chevron or a widget.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: trailing is _AccentSwitch ? 6 : 12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: c.textStrong,
                ),
              ),
            ),
            value == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textSoft,
                      ),
                    ],
                  ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// Orange toggle from the design.
class _AccentSwitch extends StatelessWidget {
  const _AccentSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final off = Theme.of(context).colorScheme.outlineVariant;
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? _accent : off,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// Fade + slide-up once when the page opens. The child is built once.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.child});
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final CurvedAnimation _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}