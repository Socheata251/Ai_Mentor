import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { mockHintQuiz, parseHintQuiz } from '../src/utils/hintQuiz.js';

const good = {
  type: 'hint_quiz',
  hint: 'Think about what happens on each call.',
  question: 'What stops the recursion?',
  options: ['A) The base case', 'The return keyword', 'A for loop'],
  correctIndex: 0,
  why: 'The base case does not call itself.',
  answer: 'The **base case** stops it.\n\n```py\nif n == 0:\n    return 1\n```\n\nTip: always write the base case first.',
};
const noShuffle = () => 0.999; // keeps the original order

describe('parseHintQuiz', () => {
  it('turns a hint_quiz reply into hint + quick_check with answerBlocks', () => {
    const b = parseHintQuiz(JSON.stringify(good), noShuffle);
    assert.equal(b[0].type, 'text');
    const q = b.find((x) => x.type === 'quick_check');
    assert.equal(q.options[0].label, 'The base case'); // "A)" prefix removed
    assert.equal(q.options[q.correctIndex].label, 'The base case');
    assert.equal(q.explanation, good.why);
    assert.ok(q.answerBlocks.some((x) => x.type === 'code'));
    assert.ok(q.answerBlocks.some((x) => x.type === 'tip'));
  });

  it('shuffles options but keeps correctIndex pointing at the right one', () => {
    for (let i = 0; i < 30; i++) {
      const q = parseHintQuiz(JSON.stringify(good)).find((x) => x.type === 'quick_check');
      assert.equal(q.options[q.correctIndex].label, 'The base case');
    }
  });

  it('accepts JSON wrapped in fences or extra words', () => {
    const wrapped = 'Sure!\n```json\n' + JSON.stringify(good) + '\n```';
    assert.ok(parseHintQuiz(wrapped).some((x) => x.type === 'quick_check'));
  });

  it('direct replies become plain blocks', () => {
    const b = parseHintQuiz(JSON.stringify({ type: 'direct', answer: 'Hello!\n\nTip: ask me anything.' }));
    assert.equal(b.some((x) => x.type === 'quick_check'), false);
    assert.equal(b[1].type, 'tip');
  });

  it('bad quiz data falls back to the answer text, or null', () => {
    const bad = { ...good, correctIndex: 9 };
    const b = parseHintQuiz(JSON.stringify(bad));
    assert.equal(b.some((x) => x.type === 'quick_check'), false);
    assert.equal(parseHintQuiz(JSON.stringify({ ...bad, answer: '' })), null);
    assert.equal(parseHintQuiz('not json at all'), null);
    assert.equal(parseHintQuiz(''), null);
  });

  it('mock quizzes are valid in both languages', () => {
    for (const lang of ['English', 'Khmer']) {
      const q = mockHintQuiz(lang).find((x) => x.type === 'quick_check');
      assert.ok(q.options.length >= 2 && q.answerBlocks.length > 0);
      assert.ok(q.correctIndex < q.options.length);
    }
  });
});