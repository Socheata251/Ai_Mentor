import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pressable.dart';

/// Floating "Ask anything..." bar at the bottom of the home screen.
class HomeChatInputBar extends StatefulWidget {
  const HomeChatInputBar({super.key, required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  State<HomeChatInputBar> createState() => _HomeChatInputBarState();
}

class _HomeChatInputBarState extends State<HomeChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    widget.onAsk(question);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
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
              child: const NavLogo(size: 42, color: Colors.white),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(fontSize: 14, color: colors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: colors.textStrong),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Pressable(
              onTap: value.text.trim().isEmpty ? null : _submit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value.text.trim().isEmpty ? colors.tile : colors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: value.text.trim().isEmpty
                      ? colors.tileIcon
                      : colors.onInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
