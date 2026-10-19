import { config } from '../config.js';
import { HttpError } from '../middleware/errors.js';
import { aiTextToBlocks } from '../utils/blocks.js';

const TUTOR_PROMPT = `You are Astra Learn, a patient programming tutor for university students.
- Prefer HINTS and guiding questions over complete solutions.
- Never hand over a full solution to an assignment. Explain the concept,
  point to the bug location, and let the student fix it.
- Only show full code for small, generic examples that are not the
  student's assignment, or after the student has tried twice.
- When the student pastes code: explain what it does, name the problem,
  give a debugging hint, then suggest one improvement.
- Keep answers short. Use \`inline code\`, small code blocks, and end with a
  quick check question when it helps learning.
- Put a short helpful tip in its own paragraph that starts with "Tip:".`;

export function buildSystemPrompt({ language, hintsFirst }) {
  let s = TUTOR_PROMPT;
  if (!hintsFirst) s += '\n- The student allows full answers when they ask for them.';
  s += `\n- Reply in ${language}. Keep code and programming identifiers unchanged.`;
  return s;
}

/** Offline stand-in used while AI_API_KEY is empty. */
function mockReply({ userText, language }) {
  const hasCode = userText.includes('```');
  if (language.toLowerCase() === 'khmer') {
    return hasCode
      ? [
          { type: 'text', text: 'អរគុណដែលបានចែករំលែកកូដ។ យើងមកស្វែងរកបញ្ហាជាមួយគ្នា។' },
          { type: 'text', text: '• ពិនិត្យបន្ទាត់ដែលមានកំហុស ហើយសង្កេតតម្លៃរបស់អថេរនីមួយៗ។\n• ដាក់ `print()` ឬ `console.log()` មុនបន្ទាត់នោះ។\n• តើអ្នករំពឹងថានឹងមានអ្វីកើតឡើង ហើយអ្វីបានកើតឡើងពិតប្រាកដ?' },
          { type: 'tip', text: 'សាកល្បងគន្លឹះទាំងនេះជាមុនសិន រួចប្រាប់ខ្ញុំពីលទ្ធផល។' },
        ]
      : [
          { type: 'text', text: 'សំណួរល្អណាស់! មុនពេលខ្ញុំពន្យល់ សូមប្រាប់ថាអ្នកយល់អ្វីខ្លះរួចហើយ។' },
          { type: 'text', text: 'តើផ្នែកណាដែលមិនទាន់ច្បាស់៖ វាធ្វើអ្វី ហេតុអ្វីត្រូវប្រើ ឬរបៀបសរសេរ?' },
          { type: 'tip', text: 'អ្នកអាចផ្ញើកូដ ឬសារកំហុសមក ខ្ញុំនឹងជួយរកបញ្ហាដោយមិនបង្ហាញចម្លើយទាំងមូល។' },
        ];
  }
  return hasCode
    ? [
        { type: 'text', text: "Thanks for sharing your code! Let's debug it together instead of me rewriting it." },
        { type: 'text', text: '• Read the line where the error appears and say what each variable holds.\n• Add a `print()` or `console.log()` right before it to test your assumption.\n• What did you **expect** to happen, and what **actually** happens?' },
        { type: 'tip', text: 'Try these hints first, then tell me what you found.' },
      ]
    : [
        { type: 'text', text: "Good question! Before I explain, let's see what you already know." },
        { type: 'text', text: 'Which part feels unclear: **what** it does, **why** it is needed, or **how** to write it?' },
        { type: 'tip', text: 'You can also paste your code here and I will point out the problem without giving away the full answer.' },
      ];
}

/** Merge consecutive same-role turns so the provider gets a clean alternating list. */
function toProviderMessages(history, userText) {
  const turns = [...history.slice(-20), { role: 'user', text: userText }];
  const merged = [];
  for (const t of turns) {
    const role = t.role === 'ai' ? 'assistant' : 'user';
    if (!t.text?.trim()) continue;
    const prev = merged[merged.length - 1];
    if (prev && prev.role === role) prev.content += '\n\n' + t.text;
    else merged.push({ role, content: t.text });
  }
  while (merged.length && merged[0].role !== 'user') merged.shift();
  return merged;
}

/**
 * history: [{ role: 'user'|'ai', text }]  (oldest first, WITHOUT the new message)
 * returns { blocks, mock }
 */
export async function generateReply({ history, userText, language = 'English', hintsFirst = true }) {
  const { apiKey, model, baseUrl, provider } = config.ai;

  if (!apiKey) return { blocks: mockReply({ userText, language }), mock: true };

  if (provider !== 'anthropic') throw new HttpError(501, 'ai_provider_unsupported', `AI_PROVIDER "${provider}" is not implemented`);
  if (!model) throw new HttpError(503, 'ai_not_configured', 'AI_MODEL is empty');

  let res;
  try {
    res = await fetch(`${baseUrl}/v1/messages`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({
        model,
        max_tokens: 1024,
        system: buildSystemPrompt({ language, hintsFirst }),
        messages: toProviderMessages(history, userText),
      }),
      signal: AbortSignal.timeout(30_000),
    });
  } catch {
    throw new HttpError(502, 'ai_unreachable', 'The AI service could not be reached');
  }
  if (!res.ok) throw new HttpError(502, 'ai_error', `The AI service returned ${res.status}`);

  const data = await res.json();
  const text = (data.content ?? []).filter((c) => c.type === 'text').map((c) => c.text).join('\n\n');
  return { blocks: aiTextToBlocks(text), mock: false };
}
