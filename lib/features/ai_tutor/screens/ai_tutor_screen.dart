import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
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
    this.initialMode = 'Ask',
    this.conversationId,
    this.initialMessages = const [],
  });

  final String? userName;

  /// The name to show: the one passed in, else the signed-in student.
  String get displayName => userName ?? UserSession.instance.name;
  final String topic;
  final bool useDemo;
  final String? initialPrompt;

  /// Which tab is selected when the chat opens: Ask, Explain, Summarize,
  /// Solve or Quiz.
  final String initialMode;
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
    if (_askModes.contains(widget.initialMode)) _askMode = widget.initialMode;
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
    final a = ScreenAccent.of(context, AppScreen.tutor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final size = context.screenSize;
    final media = MediaQuery.of(context);
    final compact = size.isCompact;
    // Landscape phones or an open keyboard leave little height: drop the
    // suggestion chips so the conversation keeps the space.
    final tight = media.size.height < 560 || media.viewInsets.bottom > 0;

    // Phone  -> full screen, no floating card (like every other screen).
    // Tablet / desktop -> centred card that grows with the window.
    final maxWidth = size.pick(
      compact: double.infinity,
      medium: 760.0,
      expanded: 920.0,
    );
    final outer = size.pick(compact: 0.0, medium: 16.0, expanded: 24.0);
    final side = size.pick(compact: 16.0, medium: 20.0, expanded: 24.0);

    final chat = Column(
      children: [
        AppHeader(
          horizontalPadding: side - 4,
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
            HeaderMoreMenu(onSettings: _openSettings, onClear: _chat.clear),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _chat,
            builder: (context, _) => _buildList(side),
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
                      SizedBox(
                        height: 46,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: side),
                          itemCount: _askModes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final mode = _askModes[i];
                            final selected = _askMode == mode;
                            return Center(
                              child: ChoiceChip(
                                label: Text(mode),
                                selected: selected,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _askMode = mode),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: isDark ? c.tile : Colors.white,
                                selectedColor: a.color,
                                side: BorderSide(
                                  color: selected ? a.color : a.border,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? a.onColor
                                      : (isDark ? c.textMuted : a.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (!tight)
                        SuggestionChips(
                          items: AiTutorController.suggestions,
                          onTap: _send,
                        ),
                    ],
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, compact ? 10 : 14),
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
    );

    return AppShell(
      selectedIndex: 1,
      userName: widget.displayName,
      child: Scaffold(
        backgroundColor: a.page,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: a.pageGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: compact
                    ? chat
                    : Container(
                        margin: EdgeInsets.all(outer),
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? c.surface
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: a.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: a.color.withValues(
                                alpha: isDark ? 0.18 : 0.10,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: chat,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(double side) {
    final messages = _chat.messages;
    if (messages.isEmpty && !_chat.isTyping) {
      return _EmptyState(name: widget.displayName);
    }

    final typing = _chat.isTyping;
    return ListView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(side, 4, side, 12),
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
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
          ),
        ),
      ),
    );
  }
}