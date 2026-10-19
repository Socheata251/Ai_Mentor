import { Router } from 'express';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

export const notificationsRouter = Router();
notificationsRouter.use(requireAuth);

const out = (n) => ({ id: n.id, title: n.title, body: n.body, read: n.read_at !== null, createdAt: n.created_at });

notificationsRouter.get('/', wrap(async (req, res) => {
  const { rows } = await query('SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100', [req.user.id]);
  res.json({ notifications: rows.map(out), unread: rows.filter((r) => !r.read_at).length });
}));

notificationsRouter.post('/read-all', wrap(async (req, res) => {
  await query('UPDATE notifications SET read_at = now() WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  res.status(204).end();
}));

notificationsRouter.patch('/:id/read', wrap(async (req, res) => {
  if (!/^[0-9a-f-]{36}$/i.test(req.params.id)) throw notFound('Notification not found');
  const { rows } = await query(
    'UPDATE notifications SET read_at = COALESCE(read_at, now()) WHERE id = $1 AND user_id = $2 RETURNING *',
    [req.params.id, req.user.id],
  );
  if (!rows[0]) throw notFound('Notification not found');
  res.json({ notification: out(rows[0]) });
}));
