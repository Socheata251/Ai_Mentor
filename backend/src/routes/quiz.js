import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

export const quizRouter = Router();
quizRouter.use(requireAuth);

const topicOut = (t, count) => ({
  id: t.id, title: t.title, subtitle: t.subtitle, category: t.category, level: t.level,
  fileName: t.file_name, langBadge: t.lang_badge, questionCount: Number(count ?? 0),
});

quizRouter.get('/topics', wrap(async (_req, res) => {
  const { rows } = await query(
    `SELECT t.*, (SELECT count(*) FROM quiz_questions q WHERE q.topic_id = t.id) AS n
     FROM quiz_topics t ORDER BY t.position`,
  );
  res.json({ topics: rows.map((t) => topicOut(t, t.n)) });
}));

quizRouter.get('/topics/:id', wrap(async (req, res) => {
  const { rows: t } = await query('SELECT * FROM quiz_topics WHERE id = $1', [req.params.id]);
  if (!t[0]) throw notFound('Quiz topic not found');
  const { rows: q } = await query('SELECT * FROM quiz_questions WHERE topic_id = $1 ORDER BY position', [req.params.id]);
  res.json({
    topic: {
      ...topicOut(t[0], q.length),
      // correctIndex is included because the app grades instantly and offline (practice quiz).
      questions: q.map((x) => ({
        tag: x.tag, prompt: x.prompt, code: x.code, options: x.options, correctIndex: x.correct_index,
        hint: x.hint, explanation: x.explanation, optionsAreCode: x.options_are_code,
      })),
    },
  });
}));

const attemptBody = z.object({
  topicId: z.string().min(1).max(40),
  // one entry per question: chosen option index, null = time ran out
  answers: z.array(z.number().int().min(0).max(9).nullable()).min(1).max(100),
  clientRef: z.string().min(8).max(80).optional(), // idempotency key: same key = same attempt
});

const XP_PER_CORRECT = 10;

const attemptOut = (a) => ({
  id: a.id, topicId: a.topic_id, topicTitle: a.topic_title, category: a.category,
  score: a.score, total: a.total, xp: a.xp, date: a.created_at,
});

quizRouter.post('/attempts', wrap(async (req, res) => {
  const b = attemptBody.parse(req.body);

  if (b.clientRef) {
    const dup = await query(
      `SELECT a.*, t.title AS topic_title, t.category FROM quiz_attempts a JOIN quiz_topics t ON t.id = a.topic_id
       WHERE a.user_id = $1 AND a.client_ref = $2`,
      [req.user.id, b.clientRef],
    );
    if (dup.rows[0]) return res.status(200).json({ attempt: attemptOut(dup.rows[0]), duplicate: true });
  }

  const { rows: qs } = await query('SELECT correct_index FROM quiz_questions WHERE topic_id = $1 ORDER BY position', [b.topicId]);
  if (!qs.length) throw notFound('Quiz topic not found');
  // The SERVER grades the answers, so the client cannot send a fake score.
  const total = qs.length;
  const answers = Array.from({ length: total }, (_, i) => b.answers[i] ?? null);
  const score = answers.filter((a, i) => a === qs[i].correct_index).length;
  const xp = score * XP_PER_CORRECT;

  const ins = await query(
    `INSERT INTO quiz_attempts (user_id, topic_id, score, total, xp, answers, client_ref)
     VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT DO NOTHING RETURNING id`,
    [req.user.id, b.topicId, score, total, xp, JSON.stringify(answers), b.clientRef ?? null],
  );
  const id = ins.rows[0]?.id;
  const { rows } = await query(
    `SELECT a.*, t.title AS topic_title, t.category FROM quiz_attempts a JOIN quiz_topics t ON t.id = a.topic_id
     WHERE ${id ? 'a.id = $1' : 'a.user_id = $2 AND a.client_ref = $1'}`,
    id ? [id] : [b.clientRef, req.user.id],
  );
  res.status(id ? 201 : 200).json({ attempt: attemptOut(rows[0]) });
}));

quizRouter.get('/attempts', wrap(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 50, 200);
  const { rows } = await query(
    `SELECT a.*, t.title AS topic_title, t.category FROM quiz_attempts a JOIN quiz_topics t ON t.id = a.topic_id
     WHERE a.user_id = $1 ORDER BY a.created_at DESC LIMIT $2`,
    [req.user.id, limit],
  );
  res.json({ attempts: rows.map(attemptOut) });
}));