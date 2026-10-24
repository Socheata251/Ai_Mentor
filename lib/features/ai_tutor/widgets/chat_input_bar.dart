import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

/// Rounded chat composer with a text field and send button.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled; // false while the AI is answering
  final VoidCallback onSend;

  /// Web / desktop keyboard: Enter sends, Shift+Enter adds a new line.
  /// Phones keep the normal on-screen keyboard behaviour.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final isTouchPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (isTouchPlatform ||
        !isEnter ||
        event is! KeyDownEvent ||
        HardwareKeyboard.instance.isShiftPressed ||
        controller.value.composing.isValid) {
      // composing = the user is still choosing a letter (Khmer, Chinese...).
      return KeyEventResult.ignored;
    }
    if (enabled && controller.text.trim().isNotEmpty) onSend();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = ScreenAccent.of(context, AppScreen.tutor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: NavLogo(size: 42, color: colors.onInk),
            ),
          ),
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: colors.textStrong),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(fontSize: 14, color: colors.textMuted),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && enabled;
              return _CircleButton(
                onTap: canSend ? onSend : null,
                color: canSend ? accent.color : accent.soft,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: canSend ? accent.onColor : accent.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, required this.color, this.onTap});

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: child,
      ),
    );
  }
}