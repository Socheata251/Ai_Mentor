import { Router } from 'express';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { wrap } from '../middleware/errors.js';

export const progressRouter = Router();
progressRouter.use(requireAuth);

/** Consecutive UTC days with a quiz, counted back from today (or yesterday). */
export function streakFrom(dayStrings) {
  const days = new Set(dayStrings);
  const fmt = (d) => d.toISOString().slice(0, 10);
  const cur = new Date();
  if (!days.has(fmt(cur))) cur.setUTCDate(cur.getUTCDate() - 1);
  let n = 0;
  while (days.has(fmt(cur))) { n++; cur.setUTCDate(cur.getUTCDate() - 1); }
  return n;
}

progressRouter.get('/summary', wrap(async (req, res) => {
  const uid = req.user.id;
  const [totals, topics, days, courses] = await Promise.all([
    query(
      `SELECT count(*)::int AS quizzes, COALESCE(sum(xp),0)::int AS xp,
              COALESCE(max(score::float/total),0) AS best, COALESCE(avg(score::float/total),0) AS avg
       FROM quiz_attempts WHERE user_id = $1`, [uid]),
    query(
      `SELECT t.id, t.title, count(*)::int AS attempts, avg(a.score::float/a.total) AS avg, max(a.score::float/a.total) AS best
       FROM quiz_attempts a JOIN quiz_topics t ON t.id = a.topic_id WHERE a.user_id = $1
       GROUP BY t.id, t.title ORDER BY t.title`, [uid]),
    query("SELECT DISTINCT to_char(created_at AT TIME ZONE 'UTC','YYYY-MM-DD') AS d FROM quiz_attempts WHERE user_id = $1", [uid]),
    query('SELECT COALESCE(avg(progress),0)::float AS avg FROM user_course_progress WHERE user_id = $1', [uid]),
  ]);
  const t = totals.rows[0];
  const pct = (x) => Math.round(x * 100);
  res.json({
    quizzesTaken: t.quizzes,
    totalXp: t.xp,
    bestPercent: pct(t.best),
    averagePercent: t.quizzes ? pct(t.avg) : null,
    streakDays: streakFrom(days.rows.map((r) => r.d)),
    courseProgressPercent: pct(courses.rows[0].avg),
    topics: topics.rows.map((r) => ({
      topicId: r.id, title: r.title, attempts: r.attempts, averagePercent: pct(r.avg), bestPercent: pct(r.best),
    })),
  });
}));
