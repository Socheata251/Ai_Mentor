import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { conflict, HttpError, unauthorized, wrap } from '../middleware/errors.js';
import { audit } from '../utils/audit.js';
import { config } from '../config.js';
import * as sb from '../services/supabaseAuth.js';
import { publicUser, USER_SELECT } from './users.js';

/**
 * Same endpoints and answers as routes/auth.js, but Supabase Auth keeps the
 * accounts, checks the passwords and sends the OTP emails. The Flutter app
 * does not change. Our `users` table stays as the student profile
 * (users.id = the Supabase user id).
 */
export const authSupabaseRouter = Router();

const password = z.string().min(8, 'At least 8 characters').max(72);
const codeField = z.string().trim().regex(/^\d{6}$/, 'The code has 6 digits');
const emailField = z.string().trim().toLowerCase().email().max(254);
const registerBody = z.object({
  name: z.string().trim().min(1).max(80),
  email: emailField,
  password,
  university: z.string().trim().min(1).max(120).optional(),
  semester: z.number().int().min(1).max(12).optional(),
});
const otpInfo = () => ({ expiresInSeconds: config.otp.ttlMinutes * 60, resendAfterSeconds: config.otp.cooldownSeconds });

const DEFAULT_SESSIONS = [
  ['Daily Coding Brief', 'Personalized morning briefing on Data Structures and clean coding habits.', 'Daily at 7:00 AM', 'DAILY'],
  ['Weekend Long Code Lab', 'Longer guided practice session to build a small project step by step.', 'Sat at 9:00 AM', 'WEEKEND'],
  ['Exam & Assignment Monitor', 'Reminders for upcoming exams and assignment deadlines.', 'Daily at 8:00 PM', 'EXAMS'],
  ['Quiz & Flashcards', 'A short quiz to keep what you learned fresh.', 'Daily at 6:00 PM', 'QUIZ'],
];

/**
 * Make sure the student profile row exists for this Supabase user.
 * Returns the public user, or null when the account was deleted.
 */
export async function ensureProfile(authUser, { name, university, semester } = {}) {
  const email = String(authUser.email ?? '').toLowerCase();
  if (!authUser.id || !email) throw unauthorized('Invalid session');

  await tx(async (c) => {
    const { rows } = await c.query('SELECT id, deleted_at FROM users WHERE id = $1 FOR UPDATE', [authUser.id]);
    if (rows[0]) {
      if (!rows[0].deleted_at && authUser.email_confirmed_at) {
        await c.query('UPDATE users SET email_verified_at = COALESCE(email_verified_at, $2) WHERE id = $1', [authUser.id, authUser.email_confirmed_at]);
      }
      return;
    }
    const display = name ?? authUser.user_metadata?.name ?? email.split('@')[0];
    try {
      await c.query(
        `INSERT INTO users (id, name, email, university, semester, email_verified_at)
         VALUES ($1,$2,$3,COALESCE($4,'ACLEDA University'),COALESCE($5,4),$6)`,
        [authUser.id, String(display).slice(0, 80), email, university ?? null, semester ?? null, authUser.email_confirmed_at ?? null],
      );
    } catch (e) {
      // Same email already belongs to an old local account (see SUPABASE_AUTH_SETUP.md).
      if (e.code === '23505') throw conflict('An account with this email already exists');
      throw e;
    }
    await c.query('INSERT INTO user_settings (user_id) VALUES ($1)', [authUser.id]);
    for (const [title, subtitle, time, tag] of DEFAULT_SESSIONS) {
      await c.query(
        'INSERT INTO schedule_sessions (user_id,title,subtitle,time_label,tag) VALUES ($1,$2,$3,$4,$5)',
        [authUser.id, title, subtitle, time, tag],
      );
    }
    await c.query('INSERT INTO notifications (user_id,title,body) VALUES ($1,$2,$3)', [
      authUser.id, 'Welcome to iLearnCode', 'Ask the AI tutor a question or take your first quiz.',
    ]);
  });

  const { rows } = await query(`${USER_SELECT} WHERE u.id = $1 AND u.deleted_at IS NULL`, [authUser.id]);
  return rows[0] ? publicUser(rows[0]) : null;
}

const sessionResponse = (s, user) => ({ user, accessToken: s.access_token, refreshToken: s.refresh_token });

/** Errors that must stay hidden so nobody can find out which emails have accounts. */
const quiet = async (fn) => {
  try {
    await fn();
  } catch (e) {
    if (e instanceof HttpError && (e.status === 429 || e.status >= 500)) throw e;
  }
};

// Step 1 of sign-up: Supabase creates the (unconfirmed) account and emails a 6-digit code.
authSupabaseRouter.post('/register', wrap(async (req, res) => {
  const b = registerBody.parse(req.body);
  const { user, session } = await sb.signUp({ email: b.email, password: b.password, name: b.name });
  if (session) {
    // "Confirm email" is OFF in Supabase: nobody would be asked for a code.
    console.error('Supabase Auth: turn ON "Confirm email" (Authentication > Sign In / Providers > Email).');
    throw new HttpError(503, 'auth_misconfigured', 'Sign-up is not set up correctly. Please contact support.');
  }
  // Supabase hides existing accounts: it answers with an empty identities list.
  if (Array.isArray(user?.identities) && user.identities.length === 0) {
    throw conflict('An account with this email already exists');
  }
  await ensureProfile(user, { name: b.name, university: b.university, semester: b.semester });
  await audit(req, 'auth.register', { entity: 'user', userId: user.id, meta: { email: b.email } });
  res.status(201).json({ requiresVerification: true, email: b.email, ...otpInfo() });
}));

// Step 2 of sign-up: the code from the email. Success = signed in.
authSupabaseRouter.post('/verify-email', wrap(async (req, res) => {
  const b = z.object({ email: emailField, code: codeField, device: z.string().max(120).optional() }).parse(req.body);
  const s = await sb.verifyCode({ email: b.email, code: b.code, type: 'signup' });
  const user = await ensureProfile(s.user);
  if (!user) throw new HttpError(400, 'invalid_code', 'Invalid or expired code');
  await audit(req, 'auth.verify_email', { userId: user.id });
  res.json(sessionResponse(s, user));
}));

// Send a new code. Same answer whether or not the email exists.
authSupabaseRouter.post('/resend-code', wrap(async (req, res) => {
  const b = z.object({ email: emailField, purpose: z.enum(['verify', 'reset']).default('verify') }).parse(req.body);
  await quiet(() => (b.purpose === 'reset' ? sb.recover(b.email) : sb.resendSignup(b.email)));
  res.json({ message: 'If this email can use a code, a new code was sent.', ...otpInfo() });
}));

authSupabaseRouter.post('/login', wrap(async (req, res) => {
  const b = z.object({ email: emailField, password: z.string().min(1).max(72), device: z.string().max(120).optional() }).parse(req.body);
  let s;
  try {
    s = await sb.signInPassword({ email: b.email, password: b.password });
  } catch (e) {
    if (e instanceof HttpError && e.status === 401) await audit(req, 'auth.login_failed', { meta: { email: b.email } });
    throw e; // 401 wrong password, 403 email_not_verified (the app opens the code screen)
  }
  const user = await ensureProfile(s.user);
  if (!user) throw unauthorized('Invalid email or password'); // account was deleted
  await audit(req, 'auth.login', { userId: user.id });
  res.json(sessionResponse(s, user));
}));

authSupabaseRouter.post('/refresh', wrap(async (req, res) => {
  const { refreshToken } = z.object({ refreshToken: z.string().min(10).max(500) }).parse(req.body);
  const s = await sb.refresh(refreshToken);
  const { rows } = await query(`${USER_SELECT} WHERE u.id = $1 AND u.deleted_at IS NULL`, [s.user.id]);
  if (!rows[0]) throw unauthorized('Invalid refresh token');
  res.json(sessionResponse(s, publicUser(rows[0])));
}));

// The app only sends the refresh token. Supabase signs out by access token, so
// swap the refresh token for a fresh session and end that one (best effort).
authSupabaseRouter.post('/logout', wrap(async (req, res) => {
  const { refreshToken } = z.object({ refreshToken: z.string().min(10).max(500) }).parse(req.body);
  try {
    const s = await sb.refresh(refreshToken);
    await sb.signOut(s.access_token, 'local');
  } catch {
    // Already invalid or expired: nothing left to sign out.
  }
  res.status(204).end();
}));

authSupabaseRouter.post('/forgot-password', wrap(async (req, res) => {
  const { email } = z.object({ email: emailField }).parse(req.body);
  await quiet(() => sb.recover(email));
  res.json({ message: 'If this email has an account, a 6-digit code was sent.', ...otpInfo() });
}));

authSupabaseRouter.post('/reset-password', wrap(async (req, res) => {
  const b = z.object({ email: emailField, code: codeField, newPassword: password }).parse(req.body);
  const s = await sb.verifyCode({ email: b.email, code: b.code, type: 'recovery' });
  await sb.updatePassword(s.access_token, b.newPassword);
  await sb.signOut(s.access_token, 'global').catch(() => {}); // sign out on every device
  await audit(req, 'auth.reset_password', { userId: s.user?.id });
  res.status(204).end();
}));