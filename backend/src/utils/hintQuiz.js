import { aiTextToBlocks } from './blocks.js';

/**
 * "Hint -> choose -> real answer" mode.
 * The AI returns ONE JSON object. We turn it into chat blocks:
 *   - text blocks with the hint
 *   - one quick_check block (the multiple-choice question)
 *       explanation  = short "why" shown right after the student chooses
 *       answerBlocks = the full real answer; the app adds it to the chat after the student chooses
 */

export function buildHintQuizPrompt({ language }) {
  return [
    'You are iLearnCode, a patient programming tutor for university students.',
    'You teach in 3 steps: HINT, then the student CHOOSES an option, then the REAL ANSWER.',
    'Reply with ONE JSON object and nothing else (no markdown fences around it, no extra text).',
    '',
    'If the student asks a learning question, or pastes code that has a problem, reply:',
    '{"type":"hint_quiz",',
    ' "hint":"1-3 short sentences that guide the student WITHOUT giving the answer",',
    ' "question":"one multiple-choice question that makes the student think about the answer",',
    ' "options":["...","...","..."],',
    ' "correctIndex":0,',
    ' "why":"1-2 sentences: why the correct option is right",',
    ' "answer":"the full, real answer. Markdown allowed: `inline code`, fenced code blocks, **bold**. Keep it clear and short. You may end with a paragraph that starts with Tip:"}',
    '',
    'Use "direct" ONLY for a greeting, thanks or small talk, or when the student clearly asks to SEE the full answer ("show the answer", "full answer", "give me the solution").',
    'Requests such as explain, solve, summarize, compare, quiz me, or any coding question are learning questions: they MUST use hint_quiz, never direct.',
    '{"type":"direct","answer":"..."}',
    '',
    'Rules:',
    '- The hint must NOT contain the final answer.',
    '- Use 3 or 4 short options. Exactly one is correct. Wrong options must look believable.',
    '- Do not always make the first option the correct one.',
    `- Write hint, question, options, why and answer in ${language}. Keep code and programming identifiers unchanged.`,
    '- Output valid JSON only: write new lines inside strings as \\n and double quotes as \\".',
  ].join('\n');
}

export const HINT_RETRY_NOTE =
  'You skipped the hint step. This is a learning question, so reply again with ONLY a hint_quiz JSON object: a hint that does not give the answer, one multiple-choice question with 3 or 4 options, correctIndex, why, and the full answer in "answer".';

/** true when the blocks contain the hint question (the student will see the hint first). */
export const hasQuickCheck = (blocks) => Array.isArray(blocks) && blocks.some((b) => b.type === 'quick_check');

/** Greetings, thanks and explicit "show me the answer" requests may skip the hint. */
export function mayAnswerDirectly(userText) {
  const t = String(userText ?? '').trim();
  if (t.length === 0) return true;
  if (/(full|real|whole)\s+(answer|solution)|show\s+(me\s+)?the\s+(answer|solution)|give\s+me\s+the\s+(answer|solution)/i.test(t)) return true;
  return t.length <= 25 && !t.includes('?') && !t.includes('```') &&
    /^(hi|hello|hey|thanks|thank you|thx|ok|okay|cool|bye|good (morning|afternoon|evening))\b/i.test(t);
}

export const JSON_RETRY_NOTE =
  'Your last reply was not valid JSON. Reply again with ONLY the JSON object described in the instructions.';

function extractJson(raw) {
  const s = String(raw ?? '').trim().replace(/^```(?:json)?\s*/i, '');
  const a = s.indexOf('{');
  const b = s.lastIndexOf('}');
  if (a < 0 || b <= a) return null;
  try {
    return JSON.parse(s.slice(a, b + 1));
  } catch {
    return null;
  }
}

const cleanLabel = (o) => String(o ?? '').trim().replace(/^[A-Ea-e][).:]\s+/, '');

function shuffled(items, rand = Math.random) {
  const a = [...items];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/**
 * raw AI text -> blocks, or null when the reply cannot be used.
 * Options are shuffled here because AI models like to put the right answer first.
 */
export function parseHintQuiz(raw, rand = Math.random) {
  const obj = extractJson(raw);
  if (!obj || typeof obj !== 'object') return null;

  const answerText = typeof obj.answer === 'string' ? obj.answer.trim() : '';
  const hint = typeof obj.hint === 'string' ? obj.hint.trim() : '';
  const question = typeof obj.question === 'string' ? obj.question.trim() : '';
  const options = Array.isArray(obj.options) ? obj.options.map(cleanLabel).filter(Boolean) : [];
  const correct = Number(obj.correctIndex);

  const quizOk =
    obj.type !== 'direct' && hint && question && options.length >= 2 && options.length <= 5 &&
    Number.isInteger(correct) && correct >= 0 && correct < options.length;

  if (!quizOk) return answerText ? aiTextToBlocks(answerText) : null; // plain answer

  const order = shuffled(options.map((label, i) => ({ label, right: i === correct })), rand);
  const why = typeof obj.why === 'string' && obj.why.trim() ? obj.why.trim() : undefined;

  return [
    ...aiTextToBlocks(hint),
    {
      type: 'quick_check',
      question,
      options: order.map((o) => ({ label: o.label })),
      correctIndex: order.findIndex((o) => o.right),
      ...(why ? { explanation: why } : {}),
      answerBlocks: answerText ? aiTextToBlocks(answerText) : [],
    },
  ];
}

/** Offline stand-in for hint mode (used while no AI is configured). */
export function mockHintQuiz(language) {
  if (String(language).toLowerCase() === 'khmer') {
    return [
      { type: 'text', text: 'គន្លឹះ៖ មុនពេលកែកូដ សូមអានសារកំហុស ហើយមើលលេខបន្ទាត់ដែលវាបង្ហាញ។' },
      {
        type: 'quick_check',
        question: 'តើអ្នកគួរធ្វើអ្វីមុនគេ នៅពេលកូដមានកំហុស?',
        options: [
          { label: 'អានសារកំហុស និងលេខបន្ទាត់' },
          { label: 'លុបកូដទាំងអស់ ហើយសរសេរថ្មី' },
          { label: 'មិនអើពើ ហើយដំណើរការម្តងទៀត' },
        ],
        correctIndex: 0,
        explanation: 'សារកំហុសប្រាប់ពីប្រភេទ និងទីតាំងនៃបញ្ហា ដូច្នេះវាជាជំហានដំបូងដ៏ល្អបំផុត។',
        answerBlocks: [
          { type: 'text', text: 'ចម្លើយពិត៖ សូមអានសារកំហុសពីលើចុះក្រោម រកបន្ទាត់ដែលបង្ហាញ រួចដាក់ `print()` ដើម្បីពិនិត្យតម្លៃអថេរ។' },
          { type: 'tip', text: 'នេះជាចម្លើយសាកល្បង។ ដាក់ AI_MODEL ដើម្បីទទួលចម្លើយពិតពី AI។' },
        ],
      },
    ];
  }
  return [
    { type: 'text', text: 'Hint: before you change any code, read the error message and look at the line number it shows.' },
    {
      type: 'quick_check',
      question: 'What should you do FIRST when your code has a bug?',
      options: [
        { label: 'Read the error message and the line number' },
        { label: 'Delete everything and start again' },
        { label: 'Ignore it and run the code again' },
      ],
      correctIndex: 0,
      explanation: 'The error message tells you the type and the place of the problem, so it is the best first step.',
      answerBlocks: [
        { type: 'text', text: 'Real answer: read the error from top to bottom, find the line it points to, then add a `print()` before that line to check your variables.' },
        { type: 'tip', text: 'This is a demo answer. Set AI_MODEL to get real answers from the AI.' },
      ],
    },
  ];
}