import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

export const coursesRouter = Router();
coursesRouter.use(requireAuth);

// progress = finished lessons / all lessons. Courses without lessons use the saved manual value.
const SELECT = `SELECT c.code, c.title, c.topics, c.semester, c.credits, c.category,
  (CASE WHEN lt.total > 0 THEN lt.done::float / lt.total ELSE COALESCE(p.progress, 0)::float END) AS progress,
  lt.total AS "lessonCount", lt.done AS "lessonsDone"
  FROM courses c
  LEFT JOIN user_course_progress p ON p.course_code = c.code AND p.user_id = $1
  LEFT JOIN LATERAL (
    SELECT count(*)::int AS total, count(ulp.lesson_id)::int AS done
    FROM lessons l LEFT JOIN user_lesson_progress ulp ON ulp.lesson_id = l.id AND ulp.user_id = $1
    WHERE l.course_code = c.code
  ) lt ON true`;

coursesRouter.get('/', wrap(async (req, res) => {
  const sem = req.query.semester ? Number(req.query.semester) : null;
  const search = String(req.query.q ?? '').trim().toLowerCase();
  const { rows } = await query(
    `${SELECT} WHERE ($2::int IS NULL OR c.semester = $2)
       AND ($3 = '' OR lower(c.title) LIKE '%'||$3||'%' OR lower(c.code) LIKE '%'||$3||'%' OR lower(c.topics) LIKE '%'||$3||'%')
     ORDER BY c.semester, c.code`,
    [req.user.id, Number.isInteger(sem) ? sem : null, search],
  );
  res.json({ courses: rows });
}));

coursesRouter.get('/:code', wrap(async (req, res) => {
  const { rows } = await query(`${SELECT} WHERE c.code = $2`, [req.user.id, req.params.code]);
  if (!rows[0]) throw notFound('Course not found');
  res.json({ course: rows[0] });
}));

coursesRouter.put('/:code/progress', wrap(async (req, res) => {
  const { progress } = z.object({ progress: z.number().min(0).max(1) }).parse(req.body);
  const c = await query('SELECT 1 FROM courses WHERE code = $1', [req.params.code]);
  if (!c.rowCount) throw notFound('Course not found');
  await query(
    `INSERT INTO user_course_progress (user_id, course_code, progress) VALUES ($1,$2,$3)
     ON CONFLICT (user_id, course_code) DO UPDATE SET progress = EXCLUDED.progress, updated_at = now()`,
    [req.user.id, req.params.code, progress],
  );
  res.json({ code: req.params.code, progress });
}));