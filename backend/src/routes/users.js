import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { badRequest, notFound, unauthorized, wrap } from '../middleware/errors.js';
import { audit } from '../utils/audit.js';

export const USER_SELECT =
  'SELECT u.id, u.name, u.email, u.university, u.semester, r.name AS role FROM users u JOIN roles r ON r.id = u.role_id';

export const publicUser = (u) => ({
  id: u.id, name: u.name, email: u.email, university: u.university, semester: u.semester, role: u.role,
});

export const usersRouter = Router();
usersRouter.use(requireAuth);

usersRouter.get('/me', wrap(async (req, res) => {
  const { rows } = await query(`${USER_SELECT} WHERE u.id = $1 AND u.deleted_at IS NULL`, [req.user.id]);
  if (!rows[0]) throw notFound('User not found');
  res.json({ user: publicUser(rows[0]) });
}));

const patchBody = z.object({
  name: z.string().trim().min(1).max(80).optional(),
  university: z.string().trim().min(1).max(120).optional(),
  semester: z.number().int().min(1).max(12).optional(),
}).refine((b) => Object.keys(b).length > 0, 'Nothing to update');

usersRouter.patch('/me', wrap(async (req, res) => {
  const b = patchBody.parse(req.body);
  await query(
    `UPDATE users SET name = COALESCE($2,name), university = COALESCE($3,university), semester = COALESCE($4,semester)
     WHERE id = $1 AND deleted_at IS NULL`,
    [req.user.id, b.name ?? null, b.university ?? null, b.semester ?? null],
  );
  const { rows } = await query(`${USER_SELECT} WHERE u.id = $1`, [req.user.id]);
  await audit(req, 'user.update', { entity: 'user', entityId: req.user.id });
  res.json({ user: publicUser(rows[0]) });
}));

usersRouter.post('/me/password', wrap(async (req, res) => {
  const b = z.object({ currentPassword: z.string().min(1).max(72), newPassword: z.string().min(8).max(72) }).parse(req.body);
  const { rows } = await query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
  if (!rows[0] || !(await bcrypt.compare(b.currentPassword, rows[0].password_hash))) throw unauthorized('Current password is wrong');
  if (b.currentPassword === b.newPassword) throw badRequest('New password must be different');
  await query('UPDATE users SET password_hash = $2 WHERE id = $1', [req.user.id, await bcrypt.hash(b.newPassword, 12)]);
  await query('UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL', [req.user.id]);
  await audit(req, 'user.change_password');
  res.status(204).end();
}));

// Soft delete: keeps rows for audit, frees the email, signs out every device.
usersRouter.delete('/me', wrap(async (req, res) => {
  const b = z.object({ password: z.string().min(1).max(72) }).parse(req.body);
  const { rows } = await query('SELECT password_hash FROM users WHERE id = $1 AND deleted_at IS NULL', [req.user.id]);
  if (!rows[0] || !(await bcrypt.compare(b.password, rows[0].password_hash))) throw unauthorized('Password is wrong');
  await query('UPDATE users SET deleted_at = now() WHERE id = $1', [req.user.id]);
  await query('UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL', [req.user.id]);
  await audit(req, 'user.delete', { entity: 'user', entityId: req.user.id });
  res.status(204).end();
}));