import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Ask anything',
              hintStyle: t.bodyMedium!.copyWith(color: c.textMuted),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && enabled;
              return Align(
                alignment: Alignment.centerRight,
                child: _CircleButton(
                  onTap: canSend ? onSend : null,
                  gradient: c.buttonGradient,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 22,
                    color: Colors.white.withValues(alpha: canSend ? 1 : 0.5),
                  ),
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
  const _CircleButton({required this.child, this.onTap, this.gradient});

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: child,
      ),
    );
  }
}
