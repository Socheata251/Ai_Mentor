import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

export const scheduleRouter = Router();
scheduleRouter.use(requireAuth);

const out = (s) => ({ id: s.id, title: s.title, subtitle: s.subtitle, time: s.time_label, tag: s.tag, enabled: s.enabled });
const UUID = /^[0-9a-f-]{36}$/i;

scheduleRouter.get('/', wrap(async (req, res) => {
  const { rows } = await query('SELECT * FROM schedule_sessions WHERE user_id = $1 ORDER BY created_at, id', [req.user.id]);
  res.json({ sessions: rows.map(out) });
}));

const create = z.object({
  title: z.string().trim().min(1).max(80),
  subtitle: z.string().trim().max(240).default(''),
  time: z.string().trim().min(1).max(40),
  tag: z.string().trim().max(20).default(''),
});

scheduleRouter.post('/', wrap(async (req, res) => {
  const b = create.parse(req.body);
  const { rows } = await query(
    'INSERT INTO schedule_sessions (user_id,title,subtitle,time_label,tag) VALUES ($1,$2,$3,$4,$5) RETURNING *',
    [req.user.id, b.title, b.subtitle, b.time, b.tag],
  );
  res.status(201).json({ session: out(rows[0]) });
}));

const patch = create.partial().extend({ enabled: z.boolean().optional() })
  .refine((b) => Object.keys(b).length > 0, 'Nothing to update');

scheduleRouter.patch('/:id', wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) throw notFound('Session not found');
  const b = patch.parse(req.body);
  const { rows } = await query(
    `UPDATE schedule_sessions SET title = COALESCE($3,title), subtitle = COALESCE($4,subtitle),
       time_label = COALESCE($5,time_label), tag = COALESCE($6,tag), enabled = COALESCE($7,enabled)
     WHERE id = $1 AND user_id = $2 RETURNING *`,
    [req.params.id, req.user.id, b.title ?? null, b.subtitle ?? null, b.time ?? null, b.tag ?? null, b.enabled ?? null],
  );
  if (!rows[0]) throw notFound('Session not found');
  res.json({ session: out(rows[0]) });
}));

scheduleRouter.delete('/:id', wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) throw notFound('Session not found');
  const r = await query('DELETE FROM schedule_sessions WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
  if (!r.rowCount) throw notFound('Session not found');
  res.status(204).end();
}));
