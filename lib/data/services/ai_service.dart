import '../models/message.dart';

/// Send this as the system prompt when you connect the real AI API.
/// It makes the tutor give hints instead of finished assignment solutions.
const String tutorSystemPrompt = '''
You are Astra Learn, a patient programming tutor for university students.
- Prefer HINTS and guiding questions over complete solutions.
- Never hand over a full solution to an assignment. Explain the concept,
  point to the bug location, and let the student fix it.
- Only show full code for small, generic examples that are not the
  student's assignment, or after the student has tried twice.
- When the student pastes code: explain what it does, name the problem,
  give a debugging hint, then suggest one improvement.
- Keep answers short. Use `inline code`, small code blocks, and end with a
  quick check question when it helps learning.
''';

String tutorSystemPromptFor(String language) =>
    '$tutorSystemPrompt\n- Reply in $language. Keep the response in that language, while leaving code and programming identifiers unchanged.';

abstract interface class AiService {
  Future<ChatMessage> reply({
    required List<ChatMessage> history,
    required String userText,
    required String responseLanguage,
  });
}

/// Offline stand-in so the UI works today. Replace with an implementation that
/// calls your backend / the Claude API (send [tutorSystemPrompt] + [history]).
class MockAiService implements AiService {
  const MockAiService();

  @override
  Future<ChatMessage> reply({
    required List<ChatMessage> history,
    required String userText,
    required String responseLanguage,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    if (responseLanguage.toLowerCase() == 'khmer') {
      if (userText.contains('```')) {
        return ChatMessage.ai(const [
          TextBlock('អរគុណដែលបានចែករំលែកកូដ។ យើងមកស្វែងរកបញ្ហាជាមួយគ្នា។'),
          TextBlock(
            '• ពិនិត្យបន្ទាត់ដែលមានកំហុស ហើយសង្កេតតម្លៃរបស់អថេរនីមួយៗ។\n'
            '• ដាក់ `print()` ឬ `console.log()` មុនបន្ទាត់នោះ ដើម្បីសាកល្បងការសន្មត់។\n'
            '• តើអ្នករំពឹងថានឹងមានអ្វីកើតឡើង ហើយអ្វីបានកើតឡើងពិតប្រាកដ?',
          ),
          TipBlock('សាកល្បងគន្លឹះទាំងនេះជាមុនសិន រួចប្រាប់ខ្ញុំពីលទ្ធផល។'),
        ]);
      }
      return ChatMessage.ai(const [
        TextBlock(
          'សំណួរល្អណាស់! មុនពេលខ្ញុំពន្យល់ សូមប្រាប់ថាអ្នកយល់អ្វីខ្លះរួចហើយ។',
        ),
        TextBlock(
          'តើផ្នែកណាដែលមិនទាន់ច្បាស់៖ វាធ្វើអ្វី ហេតុអ្វីត្រូវប្រើ ឬរបៀបសរសេរ? ខ្ញុំនឹងជួយណែនាំជាជំហានៗ។',
        ),
        TipBlock(
          'អ្នកអាចផ្ញើកូដ ឬសារកំហុសមក ខ្ញុំនឹងជួយរកបញ្ហាដោយមិនបង្ហាញចម្លើយទាំងមូល។',
        ),
      ]);
    }

    if (userText.contains('```')) {
      return ChatMessage.ai(const [
        TextBlock(
          "Thanks for sharing your code! Let's debug it together instead of me rewriting it.",
        ),
        TextBlock(
          '• Read the line where the error appears and say what each variable holds.\n'
          '• Add a `print()` or `console.log()` right before it to test your assumption.\n'
          '• What did you **expect** to happen, and what **actually** happens?',
        ),
        TipBlock(
          'Try these hints first, then tell me what you found. If you are still stuck, I will give a bigger hint.',
        ),
      ]);
    }

    return ChatMessage.ai(const [
      TextBlock(
        "Good question! Before I explain, let's see what you already know.",
      ),
      TextBlock(
        'Which part feels unclear: **what** it does, **why** it is needed, or **how** to write it? Tell me, and I will give you a hint to get started.',
      ),
      TipBlock(
        'You can also paste your code here and I will point out the problem without giving away the full answer.',
      ),
    ]);
  }
}
