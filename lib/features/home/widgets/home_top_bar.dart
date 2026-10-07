import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_header.dart';

/// Home header. Uses the shared [AppHeader], so it matches the chat screen.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onMenu,
    required this.onNewChat,
    required this.onHistory,
    required this.onSettings,
    this.showMenu = true,
    this.horizontalPadding = 16,
  });

  /// Opens the drawer.
  final VoidCallback onMenu;
  final VoidCallback onNewChat;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  /// Hide the menu button when a permanent sidebar is shown (desktop).
  final bool showMenu;
  final double horizontalPadding;

  Widget _bar(double w, Color color) => Container(
    width: w,
    height: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppHeader(
      horizontalPadding: horizontalPadding,
      leading: showMenu
          ? Semantics(
              key: const ValueKey('navigation-menu'),
              button: true,
              label: 'Open navigation menu',
              child: HeaderButton(
                onTap: onMenu,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(16, colors.textStrong),
                    const SizedBox(height: 4),
                    _bar(10, colors.textStrong),
                  ],
                ),
              ),
            )
          : null,
      title: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(fit: BoxFit.scaleDown, child: _StudyModePill()),
      ),
      actions: [
        HeaderButton(
          icon: Icons.edit_square,
          tooltip: 'New chat',
          onTap: onNewChat,
        ),
        HeaderButton(
          icon: Icons.history_rounded,
          tooltip: 'Your questions',
          onTap: onHistory,
        ),
        HeaderMoreMenu(onSettings: onSettings),
      ],
    );
  }
}

/// "AI STUDY MODE" pill
class _StudyModePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI STUDY MODE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}