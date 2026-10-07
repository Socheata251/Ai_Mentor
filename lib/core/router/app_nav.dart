import 'package:flutter/material.dart';

import '../../data/repositories/chat_conversation_history.dart';
import '../../data/repositories/user_session.dart';
import '../../features/ai_tutor/screens/ai_tutor_screen.dart';
import '../../features/ai_tutor/screens/chat_prompt_history_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'smooth_page_route.dart';

/// Menu navigation. Picking a menu item SWITCHES screens (it does not stack
/// them), so the back stack is never longer than: Home + current screen.
///
/// Menu indexes (same as the drawer list):
///   0 Home · 1 AI Tutor · 2 Quiz · 3 History · 4 Library · 5 Progress
///   6 Scheduled · 7 Settings
class AppNav {
  AppNav._();

  static Widget? _screenFor(int index, String userName) => switch (index) {
    1 => AiTutorScreen(userName: userName),
    2 => const QuizScreen(),
    3 => const ChatPromptHistoryScreen(),
    4 => const LibraryScreen(),
    5 => ProgressScreen(userName: userName),
    6 => const ScheduleScreen(),
    7 => const SettingsScreen(),
    _ => null,
  };

  /// Show [screen] on top of Home, replacing whatever was above Home.
  static void _show(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      smoothPageRoute<void>(builder: (_) => screen),
      (route) => route.isFirst,
    );
  }

  static void goTo(
    BuildContext context,
    int index, {
    String? userName,
  }) {
    final screen = _screenFor(index, userName ?? UserSession.instance.name);
    if (screen == null) {
      // Home is the first route: just go back to it.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    _show(context, screen);
  }

  /// Start a fresh, empty chat (like "New chat" in ChatGPT).
  static void newChat(
    BuildContext context, {
    String? userName,
  }) {
    _show(
      context,
      AiTutorScreen(
        userName: userName ?? UserSession.instance.name,
        useDemo: false,
      ),
    );
  }

  /// Re-open a saved chat from the "Recent chats" list.
  static void openChat(
    BuildContext context,
    ChatConversation chat, {
    String? userName,
  }) {
    _show(
      context,
      AiTutorScreen(
        userName: userName ?? UserSession.instance.name,
        useDemo: false,
        conversationId: chat.id,
        initialMessages: chat.messages,
      ),
    );
  }
}