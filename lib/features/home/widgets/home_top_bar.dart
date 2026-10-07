import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_shell.dart';

/// Home header. Uses the shared [AppHeader], so it matches the chat screen.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onNewChat,
    required this.onHistory,
    required this.onSettings,
    this.horizontalPadding = 16,
  });

  final VoidCallback onNewChat;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      horizontalPadding: horizontalPadding,
      leading: AppMenuButton.leadingOf(context),
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