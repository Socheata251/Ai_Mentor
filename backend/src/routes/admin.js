import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';
import { audit } from '../utils/audit.js';

export const adminRouter = Router();
adminRouter.use(requireAuth, requireRole('admin'));

adminRouter.get('/users', wrap(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 50, 200);
  const offset = Math.max(Number(req.query.offset) || 0, 0);
  const { rows } = await query(
    `SELECT u.id, u.name, u.email, u.university, u.semester, r.name AS role, u.created_at, u.deleted_at
     FROM users u JOIN roles r ON r.id = u.role_id ORDER BY u.created_at DESC LIMIT $1 OFFSET $2`,
    [limit, offset],
  );
  res.json({ users: rows });
}));

adminRouter.patch('/users/:id/role', wrap(async (req, res) => {
  const { role } = z.object({ role: z.enum(['student', 'instructor', 'admin']) }).parse(req.body);
  if (!/^[0-9a-f-]{36}$/i.test(req.params.id)) throw notFound('User not found');
  const r = await query('UPDATE users SET role_id = (SELECT id FROM roles WHERE name = $2) WHERE id = $1 AND deleted_at IS NULL', [req.params.id, role]);
  if (!r.rowCount) throw notFound('User not found');
  await audit(req, 'admin.set_role', { entity: 'user', entityId: req.params.id, meta: { role } });
  res.json({ id: req.params.id, role });
}));

adminRouter.get('/audit-logs', wrap(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 100, 500);
  const { rows } = await query('SELECT * FROM audit_logs ORDER BY created_at DESC, id DESC LIMIT $1', [limit]);
  res.json({ logs: rows });
}));
