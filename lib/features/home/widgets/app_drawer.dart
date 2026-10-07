import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/repositories/chat_conversation_history.dart';

/// Slide-in drawer (phone + tablet).
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.userName,
    required this.selected,
    required this.onSelect,
    required this.onNewChat,
    required this.onOpenChat,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<ChatConversation> onOpenChat;

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
        onNewChat: onNewChat,
        onOpenChat: onOpenChat,
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
    required this.onNewChat,
    required this.onOpenChat,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<ChatConversation> onOpenChat;

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
        onNewChat: onNewChat,
        onOpenChat: onOpenChat,
      ),
    );
  }
}

/// The menu itself: header, New chat, items, recent chats, version.
/// Used by both [AppDrawer] and [HomeSideBar], so edit the menu here once.
class DrawerMenu extends StatelessWidget {
  const DrawerMenu({
    super.key,
    required this.userName,
    required this.selected,
    required this.onSelect,
    required this.onNewChat,
    required this.onOpenChat,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<ChatConversation> onOpenChat;

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

          // New chat button (like ChatGPT)
          Pressable(
            scale: 0.97,
            onTap: onNewChat,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_square, size: 18, color: colors.onInk),
                  const SizedBox(width: 8),
                  Text(
                    'New chat',
                    style: TextStyle(
                      color: colors.onInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items + recent chats
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (context, sel, _) => ListenableBuilder(
                listenable: ChatConversationHistory.instance,
                builder: (context, _) {
                  final recent = ChatConversationHistory.instance.conversations
                      .take(8)
                      .toList();

                  Widget tile(int i) => DrawerTile(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == sel,
                    onTap: () => onSelect(i),
                  );

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    children: [
                      for (var i = 0; i < _items.length - 1; i++) tile(i),

                      // Recent chats
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
                        child: Text(
                          'RECENT CHATS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                          child: Text(
                            'No chats yet. Tap New chat to start.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      else
                        for (final chat in recent)
                          DrawerChatRow(
                            title: chat.title,
                            onTap: () => onOpenChat(chat),
                          ),

                      // thin divider before Settings
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: colors.border),
                      ),
                      tile(_items.length - 1),
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

/// One recent chat in the drawer.
class DrawerChatRow extends StatelessWidget {
  const DrawerChatRow({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: colors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: colors.textStrong),
              ),
            ),
          ],
        ),
      ),
    );
  }
}