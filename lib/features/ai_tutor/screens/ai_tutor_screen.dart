import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/message.dart';
import '../../settings/providers/settings_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/ai_tutor_controller.dart';
import '../providers/demo_conversation.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/ai_message_card.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/user_bubble.dart';
import 'chat_prompt_history_screen.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../data/repositories/user_session.dart';

/// AI Tutor chat. Open it with:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const AiTutorScreen()));
class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({
    super.key,
    this.userName,
    this.topic = 'JavaScript & Async Programming',
    this.useDemo = true,
    this.initialPrompt,
    this.conversationId,
    this.initialMessages = const [],
  });

  final String? userName;

  /// The name to show: the one passed in, else the signed-in student.
  String get displayName => userName ?? UserSession.instance.name;
  final String topic;
  final bool useDemo;
  final String? initialPrompt;
  final String? conversationId;
  final List<ChatMessage> initialMessages;

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  static const _askModes = ['Ask', 'Explain', 'Summarize', 'Solve', 'Quiz'];

  late final AiTutorController _chat = AiTutorController(
    initial: widget.initialMessages.isNotEmpty
        ? widget.initialMessages
        : widget.useDemo
        ? demoConversation()
        : const [],
    conversationId: widget.conversationId,
  );
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();

  int _lastItemCount = 0;
  String _askMode = 'Ask';

  @override
  void initState() {
    super.initState();
    _chat.addListener(_onChatChanged);
    _lastItemCount = _itemCount;
    _scrollToEnd(animate: false);
    final initialPrompt = widget.initialPrompt?.trim();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send(initialPrompt);
      });
    }
  }

  int get _itemCount => _chat.messages.length + (_chat.isTyping ? 1 : 0);

  void _onChatChanged() {
    // Scroll only when a message / the typing dots appeared (not on a quiz tap).
    if (_itemCount != _lastItemCount) {
      _lastItemCount = _itemCount;
      _scrollToEnd();
    }
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    _chat.dispose();
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    if (text == null) _input.clear();
    final prompt = switch (_askMode) {
      'Explain' => 'Explain this clearly with an example: $value',
      'Summarize' => 'Summarize this in concise key points: $value',
      'Solve' => 'Solve this step by step and explain the reasoning: $value',
      'Quiz' => 'Create a short quiz about this topic: $value',
      _ => value,
    };
    _chat.send(prompt, responseLanguage: appSettings.language);
  }

  /// New chat (like ChatGPT): the old chat stays saved in history and a
  /// fresh empty chat opens.
  void _newChat() {
    if (_chat.messages.isEmpty) return; // already a new chat
    Navigator.pushReplacement(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(
          userName: widget.displayName,
          topic: widget.topic,
          useDemo: false,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      smoothPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _showPromptHistory() {
    Navigator.push(
      context,
      smoothPageRoute<void>(builder: (_) => const ChatPromptHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      selectedIndex: 1,
      userName: widget.displayName,
      child: Scaffold(
      backgroundColor: isDark ? c.page : const Color(0xFFEAF0F7),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? c.pageGradient
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF2F6FB), Color(0xFFEAF0F7)],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? c.surface
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? c.border : const Color(0xFFE4E8F1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0x1A1F2E4A))
                          .withValues(alpha: isDark ? 0.35 : 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AppHeader(
                      horizontalPadding: 12,
                      leading: AppMenuButton.leadingOf(context),
                      title: _ChatTitle(topic: widget.topic),
                      actions: [
                        HeaderButton(
                          icon: Icons.edit_square,
                          tooltip: 'New chat',
                          onTap: _newChat,
                        ),
                        HeaderButton(
                          icon: Icons.history_rounded,
                          tooltip: 'Your questions',
                          onTap: _showPromptHistory,
                        ),
                        HeaderMoreMenu(
                          onSettings: _openSettings,
                          onClear: _chat.clear,
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _chat,
                        builder: (context, _) => _buildList(),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _chat,
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _chat.isTyping
                            ? const SizedBox(height: 38)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        for (final mode in _askModes) ...[
                                          if (mode != _askModes.first)
                                            const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: Text(mode),
                                            selected: _askMode == mode,
                                            onSelected: (_) =>
                                                setState(() => _askMode = mode),
                                            visualDensity:
                                                VisualDensity.compact,
                                            backgroundColor: isDark
                                                ? c.tile
                                                : const Color(0xFFF6F8FC),
                                            selectedColor: isDark
                                                ? c.gradientStart.withValues(
                                                    alpha: 0.18,
                                                  )
                                                : const Color(0xFFE9EDFF),
                                            side: BorderSide(
                                              color: _askMode == mode
                                                  ? (isDark
                                                        ? c.gradientStart
                                                        : const Color(
                                                            0xFFCBD5FF,
                                                          ))
                                                  : Colors.transparent,
                                            ),
                                            labelStyle: TextStyle(
                                              color: _askMode == mode
                                                  ? (isDark
                                                        ? c.textStrong
                                                        : const Color(
                                                            0xFF2E2B6E,
                                                          ))
                                                  : (isDark
                                                        ? c.textMuted
                                                        : const Color(
                                                            0xFF49506B,
                                                          )),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SuggestionChips(
                                    items: AiTutorController.suggestions,
                                    onTap: _send,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ListenableBuilder(
                        listenable: _chat,
                        builder: (context, _) => ChatInputBar(
                          controller: _input,
                          focusNode: _focus,
                          enabled: !_chat.isTyping,
                          onSend: _send,
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
    ),
    );
  }

  Widget _buildList() {
    final messages = _chat.messages;
    if (messages.isEmpty && !_chat.isTyping) {
      return _EmptyState(name: widget.displayName);
    }

    final typing = _chat.isTyping;
    return ListView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: messages.length + 1 + (typing ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _DateLabel(
            text: messages.isEmpty
                ? 'Today'
                : 'Today, ${formatTime(messages.first.sentAt)}',
          );
        }
        if (typing && i == messages.length + 1) return const TypingIndicator();

        final m = messages[i - 1];
        return KeyedSubtree(
          key: ValueKey(m.id),
          child: m.role == MessageRole.user
              ? UserBubble(message: m, userName: widget.displayName)
              : AiMessageCard(
                  message: m,
                  userName: widget.displayName,
                  quickAnswer: _chat.quickAnswerFor(m.id),
                  onQuickAnswer: (index) => _chat.answerQuickCheck(m.id, index),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Header title (the buttons come from the shared AppHeader)
// ---------------------------------------------------------------------
class _ChatTitle extends StatelessWidget {
  const _ChatTitle({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'IT Mentor AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF95D58C),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        Text(
          topic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall!.copyWith(fontSize: 11, color: c.textMuted),
        ),
      ],
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AiAvatar(size: 68),
            const SizedBox(height: 16),
            Text(
              'Hi $name, ask me anything about code',
              textAlign: TextAlign.center,
              style: t.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your code or an error and I will guide you with hints, so you learn it yourself.',
              textAlign: TextAlign.center,
              style: t.bodySmall!.copyWith(fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}