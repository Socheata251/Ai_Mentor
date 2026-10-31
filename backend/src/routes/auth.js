import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { config } from '../config.js';
import { pool, query } from '../db.js';
import { conflict, HttpError, unauthorized, wrap } from '../middleware/errors.js';
import { canExposeDevCode } from '../services/mailer.js';
import { issueOtp, verifyOtp } from '../services/otp.js';
import { audit } from '../utils/audit.js';
import { issueRefreshToken, sha256, signAccessToken } from '../utils/tokens.js';
import { publicUser, USER_SELECT } from './users.js';

/**
 * Local auth (AUTH_PROVIDER=local): this server keeps the accounts and emails the
 * 6-digit OTP codes itself (SMTP / Brevo / Resend). Same endpoints and answers as
 * routes/authSupabase.js, so the Flutter app does not change.
 */
export const authRouter = Router();

const password = z.string().min(8, 'At least 8 characters').max(72);
const codeField = z.string().trim().regex(/^\d{6}$/, 'The code has 6 digits');
const emailField = z.string().trim().toLowerCase().email().max(254);
const otpInfo = () => ({ expiresInSeconds: config.otp.ttlMinutes * 60, resendAfterSeconds: config.otp.cooldownSeconds });

// Compared when the email does not exist, so the answer takes the same time.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', 10);

const DEFAULT_SESSIONS = [
  ['Daily Coding Brief', 'Personalized morning briefing on Data Structures and clean coding habits.', 'Daily at 7:00 AM', 'DAILY'],
  ['Weekend Long Code Lab', 'Longer guided practice session to build a small project step by step.', 'Sat at 9:00 AM', 'WEEKEND'],
  ['Exam & Assignment Monitor', 'Reminders for upcoming exams and assignment deadlines.', 'Daily at 8:00 PM', 'EXAMS'],
  ['Quiz & Flashcards', 'A short quiz to keep what you learned fresh.', 'Daily at 6:00 PM', 'QUIZ'],
];

const registerBody = z.object({
  name: z.string().trim().min(1).max(80),
  email: emailField,
  password,
  university: z.string().trim().min(1).max(120).optional(),
  semester: z.number().int().min(1).max(12).optional(),
});

async function findUser(email) {
  const { rows } = await query(
    'SELECT id, password_hash, email_verified_at FROM users WHERE lower(email) = $1 AND deleted_at IS NULL',
    [email],
  );
  return rows[0] ?? null;
}

async function startSession(userId, device) {
  const { rows } = await query(`${USER_SELECT} WHERE u.id = $1 AND u.deleted_at IS NULL`, [userId]);
  if (!rows[0]) throw unauthorized('Invalid email or password');
  const user = publicUser(rows[0]);
  const client = await pool.connect();
  try {
    const refreshToken = await issueRefreshToken(client, user.id, device);
    return { user, accessToken: signAccessToken(user), refreshToken };
  } finally {
    client.release();
  }
}

// Step 1 of sign-up: create the (unverified) account and email a 6-digit code.
authRouter.post('/register', wrap(async (req, res) => {
  const b = registerBody.parse(req.body);
  const hash = await bcrypt.hash(b.password, 12);
  const existing = await findUser(b.email);

  if (existing?.email_verified_at) throw conflict('An account with this email already exists');

  if (existing) {
    // Signed up before but never typed the code: let them try again with the new details.
    await query('UPDATE users SET name = $2, password_hash = $3 WHERE id = $1', [existing.id, b.name, hash]);
  } else {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { rows } = await client.query(
        `INSERT INTO users (name, email, password_hash, university, semester)
         VALUES ($1,$2,$3,COALESCE($4,'ACLEDA University'),COALESCE($5,4)) RETURNING id`,
        [b.name, b.email, hash, b.university ?? null, b.semester ?? null],
      );
      const id = rows[0].id;
      await client.query('INSERT INTO user_settings (user_id) VALUES ($1)', [id]);
      for (const [title, subtitle, time, tag] of DEFAULT_SESSIONS) {
        await client.query(
          'INSERT INTO schedule_sessions (user_id,title,subtitle,time_label,tag) VALUES ($1,$2,$3,$4,$5)',
          [id, title, subtitle, time, tag],
        );
      }
      await client.query('INSERT INTO notifications (user_id,title,body) VALUES ($1,$2,$3)', [
        id, 'Welcome to iLearnCode', 'Ask the AI tutor a question or take your first quiz.',
      ]);
      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK').catch(() => {});
      if (e.code === '23505') throw conflict('An account with this email already exists');
      throw e;
    } finally {
      client.release();
    }
  }

  const { devCode } = await issueOtp({ email: b.email, purpose: 'verify' });
  await audit(req, 'auth.register', { entity: 'user', meta: { email: b.email } });
  res.status(201).json({ requiresVerification: true, email: b.email, ...otpInfo(), ...(devCode ? { devCode } : {}) });
}));

// Step 2 of sign-up: the code from the email. Success = signed in.
authRouter.post('/verify-email', wrap(async (req, res) => {
  const b = z.object({ email: emailField, code: codeField, device: z.string().max(120).optional() }).parse(req.body);
  await verifyOtp({ email: b.email, purpose: 'verify', code: b.code });
  const u = await findUser(b.email);
  if (!u) throw new HttpError(400, 'invalid_code', 'Invalid or expired code');
  await query('UPDATE users SET email_verified_at = COALESCE(email_verified_at, now()) WHERE id = $1', [u.id]);
  const session = await startSession(u.id, b.device);
  await audit(req, 'auth.verify_email', { userId: u.id });
  res.json(session);
}));

// Send a new code. Same answer whether or not the email exists.
authRouter.post('/resend-code', wrap(async (req, res) => {
  const b = z.object({ email: emailField, purpose: z.enum(['verify', 'reset']).default('verify') }).parse(req.body);
  const u = await findUser(b.email);
  let devCode;
  if (u && (b.purpose === 'reset' || !u.email_verified_at)) {
    ({ devCode } = await issueOtp({ email: b.email, purpose: b.purpose }));
  }
  res.json({ message: 'If this email can use a code, a new code was sent.', ...otpInfo(), ...(devCode ? { devCode } : {}) });
}));

authRouter.post('/login', wrap(async (req, res) => {
  const b = z.object({ email: emailField, password: z.string().min(1).max(72), device: z.string().max(120).optional() }).parse(req.body);
  const u = await findUser(b.email);
  const ok = await bcrypt.compare(b.password, u?.password_hash ?? DUMMY_HASH);
  if (!u || !u.password_hash || !ok) {
    await audit(req, 'auth.login_failed', { meta: { email: b.email } });
    throw unauthorized('Invalid email or password');
  }
  // The app opens the code screen when it sees this error.
  if (!u.email_verified_at) throw new HttpError(403, 'email_not_verified', 'Please verify your email first.');
  const session = await startSession(u.id, b.device);
  await audit(req, 'auth.login', { userId: u.id });
  res.json(session);
}));

// Refresh tokens are used once: the old one is revoked and a new pair is returned.
authRouter.post('/refresh', wrap(async (req, res) => {
  const { refreshToken } = z.object({ refreshToken: z.string().min(10).max(500) }).parse(req.body);
  const { rows } = await query(
    `UPDATE refresh_tokens SET revoked_at = now()
     WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > now() RETURNING user_id, device`,
    [sha256(refreshToken)],
  );
  if (!rows[0]) throw unauthorized('Invalid refresh token');
  res.json(await startSession(rows[0].user_id, rows[0].device));
}));

authRouter.post('/logout', wrap(async (req, res) => {
  const { refreshToken } = z.object({ refreshToken: z.string().min(10).max(500) }).parse(req.body);
  await query('UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL', [sha256(refreshToken)]);
  res.status(204).end();
}));

authRouter.post('/forgot-password', wrap(async (req, res) => {
  const { email } = z.object({ email: emailField }).parse(req.body);
  const u = await findUser(email);
  let devCode;
  if (u) ({ devCode } = await issueOtp({ email, purpose: 'reset' }));
  res.json({ message: 'If this email has an account, a 6-digit code was sent.', ...otpInfo(), ...(devCode && canExposeDevCode() ? { devCode } : {}) });
}));

authRouter.post('/reset-password', wrap(async (req, res) => {
  const b = z.object({ email: emailField, code: codeField, newPassword: password }).parse(req.body);
  await verifyOtp({ email: b.email, purpose: 'reset', code: b.code });
  const u = await findUser(b.email);
  if (!u) throw new HttpError(400, 'invalid_code', 'Invalid or expired code');
  const hash = await bcrypt.hash(b.newPassword, 12);
  await query(
    'UPDATE users SET password_hash = $2, email_verified_at = COALESCE(email_verified_at, now()) WHERE id = $1',
    [u.id, hash],
  );
  // Sign out on every device.
  await query('UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL', [u.id]);
  await audit(req, 'auth.reset_password', { userId: u.id });
  res.status(204).end();
}));