import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/chat_prompt_history.dart';

class ChatPromptHistoryScreen extends StatelessWidget {
  const ChatPromptHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.page,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to chat',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Your questions'),
      ),
      body: AnimatedBuilder(
        animation: ChatPromptHistory.instance,
        builder: (context, _) {
          final prompts = ChatPromptHistory.instance.prompts;
          if (prompts.isEmpty) {
            return Center(
              child: Text(
                'Questions you ask will appear here.',
                style: text.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: prompts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prompt = prompts[prompts.length - index - 1];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.plainText,
                      style: text.bodyMedium?.copyWith(
                        color: colors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(prompt.sentAt),
                      style: text.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day/${local.year} · $hour:$minute';
  }
}
