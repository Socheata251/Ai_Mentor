import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { config } from '../config.js';
import { query, tx } from '../db.js';
import { badRequest, conflict, unauthorized, wrap } from '../middleware/errors.js';
import { audit } from '../utils/audit.js';
import { issueRefreshToken, randomToken, sha256, signAccessToken } from '../utils/tokens.js';
import { publicUser, USER_SELECT } from './users.js';

export const authRouter = Router();

const password = z.string().min(8, 'At least 8 characters').max(72);
const registerBody = z.object({
  name: z.string().trim().min(1).max(80),
  email: z.string().trim().toLowerCase().email().max(254),
  password,
  university: z.string().trim().min(1).max(120).optional(),
  semester: z.number().int().min(1).max(12).optional(),
});
const loginBody = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1).max(72),
  device: z.string().max(120).optional(),
});

const DEFAULT_SESSIONS = [
  ['Daily Coding Brief', 'Personalized morning briefing on Data Structures and clean coding habits.', 'Daily at 7:00 AM', 'DAILY'],
  ['Weekend Long Code Lab', 'Longer guided practice session to build a small project step by step.', 'Sat at 9:00 AM', 'WEEKEND'],
  ['Exam & Assignment Monitor', 'Reminders for upcoming exams and assignment deadlines.', 'Daily at 8:00 PM', 'EXAMS'],
  ['Quiz & Flashcards', 'A short quiz to keep what you learned fresh.', 'Daily at 6:00 PM', 'QUIZ'],
];

async function startSession(client, user, device) {
  const full = { id: user.id, role: user.role };
  return {
    user: publicUser(user),
    accessToken: signAccessToken(full),
    refreshToken: await issueRefreshToken(client, user.id, device),
  };
}

authRouter.post('/register', wrap(async (req, res) => {
  const b = registerBody.parse(req.body);
  const hash = await bcrypt.hash(b.password, 12);
  let result;
  try {
    result = await tx(async (c) => {
      const { rows } = await c.query(
        `INSERT INTO users (name, email, password_hash, university, semester)
         VALUES ($1,$2,$3,COALESCE($4,'ACLEDA University'),COALESCE($5,4)) RETURNING id`,
        [b.name, b.email, hash, b.university ?? null, b.semester ?? null],
      );
      const id = rows[0].id;
      await c.query('INSERT INTO user_settings (user_id) VALUES ($1)', [id]);
      for (const [title, subtitle, time, tag] of DEFAULT_SESSIONS) {
        await c.query(
          'INSERT INTO schedule_sessions (user_id,title,subtitle,time_label,tag) VALUES ($1,$2,$3,$4,$5)',
          [id, title, subtitle, time, tag],
        );
      }
      await c.query('INSERT INTO notifications (user_id,title,body) VALUES ($1,$2,$3)', [
        id, 'Welcome to Astra Learn', 'Ask the AI tutor a question or take your first quiz.',
      ]);
      const { rows: u } = await c.query(`${USER_SELECT} WHERE u.id = $1`, [id]);
      return startSession(c, u[0], req.body.device);
    });
  } catch (e) {
    if (e.code === '23505') throw conflict('An account with this email already exists');
    throw e;
  }
  await audit(req, 'auth.register', { userId: result.user.id, entity: 'user', entityId: result.user.id });
  res.status(201).json(result);
}));

// Compare against a dummy hash when the user does not exist, so timing does not reveal accounts.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', 12);

authRouter.post('/login', wrap(async (req, res) => {
  const b = loginBody.parse(req.body);
  const { rows } = await query(
    `${USER_SELECT} WHERE lower(u.email) = $1 AND u.deleted_at IS NULL`,
    [b.email],
  );
  const pw = await query('SELECT password_hash FROM users WHERE id = $1', [rows[0]?.id ?? null]);
  const ok = await bcrypt.compare(b.password, pw.rows[0]?.password_hash ?? DUMMY_HASH);
  if (!rows[0] || !ok) {
    await audit(req, 'auth.login_failed', { meta: { email: b.email } });
    throw unauthorized('Invalid email or password');
  }
  const result = await tx((c) => startSession(c, rows[0], b.device));
  await audit(req, 'auth.login', { userId: rows[0].id });
  res.json(result);
}));

const refreshBody = z.object({ refreshToken: z.string().min(20).max(200) });

authRouter.post('/refresh', wrap(async (req, res) => {
  const { refreshToken } = refreshBody.parse(req.body);
  const hash = sha256(refreshToken);
  const result = await tx(async (c) => {
    const { rows } = await c.query('SELECT * FROM refresh_tokens WHERE token_hash = $1 FOR UPDATE', [hash]);
    const t = rows[0];
    if (!t) return null;
    if (t.revoked_at) {
      // A used token came back: assume theft and sign this user out everywhere.
      await c.query('UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL', [t.user_id]);
      return null;
    }
    if (new Date(t.expires_at) < new Date()) return null;
    const { rows: u } = await c.query(`${USER_SELECT} WHERE u.id = $1 AND u.deleted_at IS NULL`, [t.user_id]);
    if (!u[0]) return null;
    await c.query('UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1', [t.id]); // rotate
    return startSession(c, u[0], t.device);
  });
  if (!result) throw unauthorized('Invalid refresh token');
  res.json(result);
}));

authRouter.post('/logout', wrap(async (req, res) => {
  const { refreshToken } = refreshBody.parse(req.body);
  await query('UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL', [sha256(refreshToken)]);
  res.status(204).end();
}));

authRouter.post('/forgot-password', wrap(async (req, res) => {
  const { email } = z.object({ email: z.string().trim().toLowerCase().email() }).parse(req.body);
  const { rows } = await query('SELECT id FROM users WHERE lower(email) = $1 AND deleted_at IS NULL', [email]);
  const body = { message: 'If this email exists, a reset code has been sent.' };
  if (rows[0]) {
    const token = randomToken().slice(0, 32);
    await query('INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES ($1,$2,$3)', [
      rows[0].id, sha256(token), new Date(Date.now() + 3600_000),
    ]);
    await audit(req, 'auth.forgot_password', { userId: rows[0].id });
    // TODO: send `token` by email (SMTP / provider). Until then it is only exposed outside production.
    if (!config.isProd) { body.devToken = token; console.log(`[dev] password reset token for ${email}: ${token}`); }
  }
  res.json(body); // same response either way: no account enumeration
}));

authRouter.post('/reset-password', wrap(async (req, res) => {
  const b = z.object({ token: z.string().min(10).max(200), newPassword: password }).parse(req.body);
  const hash = await bcrypt.hash(b.newPassword, 12);
  const done = await tx(async (c) => {
    const { rows } = await c.query(
      'SELECT * FROM password_resets WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now() FOR UPDATE',
      [sha256(b.token)],
    );
    if (!rows[0]) return null;
    await c.query('UPDATE password_resets SET used_at = now() WHERE id = $1', [rows[0].id]);
    await c.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, rows[0].user_id]);
    await c.query('UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL', [rows[0].user_id]);
    return rows[0].user_id;
  });
  if (!done) throw badRequest('Reset code is invalid or expired');
  await audit(req, 'auth.reset_password', { userId: done });
  res.status(204).end();
}));
