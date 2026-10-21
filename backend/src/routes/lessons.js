import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

// Mounted at /api. Routes call requireAuth one by one so unknown URLs still return 404.
export const lessonsRouter = Router();

const ID = /^\d+$/;

// All lessons of one course, with a "completed" flag for this student.
lessonsRouter.get('/courses/:code/lessons', requireAuth, wrap(async (req, res) => {
  const { rows: c } = await query('SELECT code, title FROM courses WHERE code = $1', [req.params.code]);
  if (!c[0]) throw notFound('Course not found');
  const { rows } = await query(
    `SELECT l.id, l.position, l.slug, l.title, l.summary, (p.lesson_id IS NOT NULL) AS completed
     FROM lessons l
     LEFT JOIN user_lesson_progress p ON p.lesson_id = l.id AND p.user_id = $2
     WHERE l.course_code = $1 ORDER BY l.position`,
    [req.params.code, req.user.id],
  );
  res.json({
    course: c[0],
    lessons: rows,
    total: rows.length,
    completedCount: rows.filter((r) => r.completed).length,
  });
}));

// One lesson with all its blocks, plus previous / next lesson links.
lessonsRouter.get('/lessons/:id', requireAuth, wrap(async (req, res) => {
  if (!ID.test(req.params.id)) throw notFound('Lesson not found');
  const { rows } = await query(
    `SELECT l.*, c.title AS course_title,
            EXISTS (SELECT 1 FROM user_lesson_progress p WHERE p.lesson_id = l.id AND p.user_id = $2) AS completed,
            (SELECT count(*)::int FROM lessons x WHERE x.course_code = l.course_code) AS total
     FROM lessons l JOIN courses c ON c.code = l.course_code WHERE l.id = $1`,
    [req.params.id, req.user.id],
  );
  const l = rows[0];
  if (!l) throw notFound('Lesson not found');
  const { rows: nb } = await query(
    `(SELECT 'prev' AS dir, id, title FROM lessons WHERE course_code = $1 AND position < $2 ORDER BY position DESC LIMIT 1)
     UNION ALL
     (SELECT 'next' AS dir, id, title FROM lessons WHERE course_code = $1 AND position > $2 ORDER BY position ASC LIMIT 1)`,
    [l.course_code, l.position],
  );
  const pick = (d) => {
    const r = nb.find((x) => x.dir === d);
    return r ? { id: r.id, title: r.title } : null;
  };
  res.json({
    lesson: {
      id: l.id, courseCode: l.course_code, courseTitle: l.course_title, position: l.position, total: l.total,
      slug: l.slug, title: l.title, summary: l.summary, blocks: l.content, completed: l.completed,
    },
    prev: pick('prev'),
    next: pick('next'),
  });
}));

// Mark a lesson done (or not done).
lessonsRouter.put('/lessons/:id/progress', requireAuth, wrap(async (req, res) => {
  if (!ID.test(req.params.id)) throw notFound('Lesson not found');
  const { completed } = z.object({ completed: z.boolean() }).parse(req.body);
  const { rows } = await query('SELECT course_code FROM lessons WHERE id = $1', [req.params.id]);
  if (!rows[0]) throw notFound('Lesson not found');
  if (completed) {
    await query(
      'INSERT INTO user_lesson_progress (user_id, lesson_id) VALUES ($1,$2) ON CONFLICT DO NOTHING',
      [req.user.id, req.params.id],
    );
  } else {
    await query('DELETE FROM user_lesson_progress WHERE user_id = $1 AND lesson_id = $2', [req.user.id, req.params.id]);
  }
  const { rows: s } = await query(
    `SELECT count(*)::int AS total, count(p.lesson_id)::int AS done
     FROM lessons l LEFT JOIN user_lesson_progress p ON p.lesson_id = l.id AND p.user_id = $2
     WHERE l.course_code = $1`,
    [rows[0].course_code, req.user.id],
  );
  res.json({ completed, courseDone: s[0].done, courseTotal: s[0].total });
}));