import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pressable.dart';

/// Slide-in drawer (phone + tablet).
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.selected,
    required this.onSelect,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Drawer(
      width: 304,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: DrawerMenu(
        userName: userName,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }
}

/// Permanent left sidebar (desktop / wide windows).
class HomeSideBar extends StatelessWidget {
  const HomeSideBar({
    super.key,
    required this.userName,
    required this.selected,
    required this.onSelect,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: DrawerMenu(
        userName: userName,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }
}

/// The menu itself: header, items, version. Used by both [AppDrawer] and
/// [HomeSideBar], so edit the menu here once.
class DrawerMenu extends StatelessWidget {
  const DrawerMenu({
    super.key,
    required this.userName,
    required this.selected,
    required this.onSelect,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (Icons.home_outlined, 'Home'),
    (Icons.auto_awesome_outlined, 'AI Tutor'),
    (Icons.quiz_outlined, 'Quiz'),
    (Icons.history_rounded, 'History'),
    (Icons.local_library_outlined, 'Library'),
    (Icons.insights_outlined, 'Progress'),
    (Icons.event_note_outlined, 'Scheduled'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F7CFF), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: NavLogo(size: 74, color: colors.gradientStart),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Astra Learn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hi, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items (ListView.builder: built lazily)
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (context, sel, _) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final (icon, label) = _items[i];
                  return Column(
                    children: [
                      // thin divider before Settings
                      if (i == _items.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1, color: colors.border),
                        ),
                      DrawerTile(
                        icon: icon,
                        label: label,
                        selected: i == sel,
                        onTap: () => onSelect(i),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              'Astra Learn  ·  v1.0.0',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerTile extends StatelessWidget {
  const DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? colors.onInk.withValues(alpha: 0.16)
                    : colors.tile,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? colors.onInk : colors.tileIcon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.onInk : colors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
