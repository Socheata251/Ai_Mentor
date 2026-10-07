import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ONE header used by every screen:  [leading]  [title]  [actions...]
/// Change the look here and all screens change together.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.leading,
    required this.title,
    this.actions = const [],
    this.horizontalPadding = 16,
  });

  final Widget? leading;
  final Widget title;
  final List<Widget> actions;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: title),
          for (final action in actions) ...[const SizedBox(width: 6), action],
        ],
      ),
    );
  }
}

/// Round 40px button for headers. Give it an [icon] or your own [child].
class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    this.icon,
    this.child,
    required this.onTap,
    this.tooltip,
    this.iconSize = 20,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final String? tooltip;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip ?? '',
      child: DecoratedBox(
        decoration: headerButtonDecoration(context),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child:
                    child ?? Icon(icon, size: iconSize, color: c.textStrong),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same round look, used for every header button (and the popup button).
BoxDecoration headerButtonDecoration(BuildContext context) {
  final c = context.colors;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: c.surface,
    shape: BoxShape.circle,
    border: Border.all(color: c.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// The "⋮" popup menu. The same on every screen; a screen only passes the
/// actions it supports (an item is hidden when its callback is null).
class HeaderMoreMenu extends StatelessWidget {
  const HeaderMoreMenu({super.key, this.onSettings, this.onClear});

  final VoidCallback? onSettings;
  final VoidCallback? onClear;

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: headerButtonDecoration(context),
      child: SizedBox(
        width: 40,
        height: 40,
        child: PopupMenuButton<String>(
          tooltip: 'More',
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert_rounded, size: 20, color: c.textStrong),
          onSelected: (value) {
            if (value == 'settings') onSettings?.call();
            if (value == 'clear') onClear?.call();
          },
          itemBuilder: (_) => [
            if (onSettings != null)
              _item('settings', Icons.settings_outlined, 'Settings'),
            if (onClear != null)
              _item('clear', Icons.delete_outline_rounded, 'Clear chat'),
          ],
        ),
      ),
    );
  }
}