import '../../../data/models/message.dart';

/// Sample conversation that matches the design. Pass `useDemo: false` to
/// AiTutorScreen to start with an empty chat instead.
List<ChatMessage> demoConversation() {
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));

  return [
    ChatMessage(
      id: 'demo-1',
      role: MessageRole.user,
      sentAt: ago(3),
      blocks: const [
        TextBlock('What happens if the API call fails or times out? How should I handle errors properly?'),
      ],
    ),
    ChatMessage(
      id: 'demo-2',
      role: MessageRole.ai,
      sentAt: ago(2),
      blocks: const [
        TextBlock('Great question! A common beginner bug with `fetch()` is assuming it throws on 404 or 500 errors. **It does not!**'),
        TextBlock('`fetch()` only rejects on actual network failures (e.g., no internet, DNS failure). For HTTP error codes, check `response.ok`.'),
        CodeSnippetBlock(
          fileName: 'safeFetch.js',
          language: 'javascript',
          code: r'''const response = await fetch(url);

// Must verify HTTP status
if (!response.ok) {
  throw new Error(`HTTP error! status: ${response.status}`);
}

return await response.json();''',
        ),
        TipBlock('**Pro Tip:** For timeouts, pass an `AbortSignal.timeout()` directly into `fetch()`.'),
        QuickCheckBlock(
          question: 'What does `await Promise.all([...])` do if any single request fails?',
          correctIndex: 0,
          explanation: 'Promise.all rejects as soon as one promise rejects (fail-fast). Use Promise.allSettled() to wait for every result.',
          options: [
            QuickCheckOption('Rejects immediately (fail-fast)', emoji: '⚡'),
            QuickCheckOption('Waits for all to finish, returns partial data', emoji: '⏳'),
            QuickCheckOption('Returns null for failed items', emoji: '🚫'),
            QuickCheckOption('Silently ignores the error', emoji: '🟠'),
          ],
        ),
      ],
    ),
  ];
}
