import crypto from 'node:crypto';
import { config } from '../config.js';
import { query } from '../db.js';
import { HttpError } from '../middleware/errors.js';
import { canExposeDevCode, sendOtpEmail } from './mailer.js';

const hashCode = (email, purpose, code) =>
  crypto.createHmac('sha256', config.jwtSecret).update(`${email}:${purpose}:${code}`).digest('hex');

export const newCode = () => String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');

/**
 * Create and email a 6-digit code. purpose = 'verify' | 'reset'.
 * Too soon after the last code (cooldown) or too many in one hour: nothing is sent.
 * Returns { sent, devCode? }. devCode only exists while developing without SMTP.
 */
export async function issueOtp({ email, purpose }) {
  const o = config.otp;
  const recent = await query(
    `SELECT 1 FROM email_otps WHERE email = $1 AND purpose = $2 AND created_at > now() - make_interval(secs => $3) LIMIT 1`,
    [email, purpose, o.cooldownSeconds],
  );
  if (recent.rowCount) return { sent: false };
  const hour = await query(
    `SELECT count(*)::int AS n FROM email_otps WHERE email = $1 AND purpose = $2 AND created_at > now() - interval '1 hour'`,
    [email, purpose],
  );
  if (hour.rows[0].n >= o.hourlyLimit) return { sent: false };

  await query('UPDATE email_otps SET used_at = now() WHERE email = $1 AND purpose = $2 AND used_at IS NULL', [email, purpose]);
  const code = newCode();
  const ins = await query(
    `INSERT INTO email_otps (email, purpose, code_hash, expires_at) VALUES ($1,$2,$3, now() + make_interval(mins => $4)) RETURNING id`,
    [email, purpose, hashCode(email, purpose, code), o.ttlMinutes],
  );
  query("DELETE FROM email_otps WHERE created_at < now() - interval '1 day'").catch(() => {});
  try {
    await sendOtpEmail({ to: email, code, purpose, ttlMinutes: o.ttlMinutes });
  } catch (e) {
    await query('DELETE FROM email_otps WHERE id = $1', [ins.rows[0].id]); // so the person can try again at once
    throw e;
  }
  return { sent: true, ...(canExposeDevCode() ? { devCode: code } : {}) };
}

const invalid = () => new HttpError(400, 'invalid_code', 'Invalid or expired code');

/** Throws unless [code] is right. A good code works once; 5 wrong tries lock it. */
export async function verifyOtp({ email, purpose, code }) {
  const { rows } = await query(
    `SELECT id, code_hash, attempts FROM email_otps
     WHERE email = $1 AND purpose = $2 AND used_at IS NULL AND expires_at > now()
     ORDER BY created_at DESC LIMIT 1`,
    [email, purpose],
  );
  const row = rows[0];
  if (!row) throw invalid();
  const max = config.otp.maxAttempts;
  if (row.attempts >= max) throw new HttpError(400, 'too_many_attempts', 'Too many wrong tries. Please ask for a new code.');

  const a = Buffer.from(hashCode(email, purpose, code));
  const b = Buffer.from(row.code_hash);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    const u = await query('UPDATE email_otps SET attempts = attempts + 1 WHERE id = $1 RETURNING attempts', [row.id]);
    const left = max - u.rows[0].attempts;
    throw new HttpError(
      400,
      left > 0 ? 'invalid_code' : 'too_many_attempts',
      left > 0 ? `Wrong code. ${left} ${left === 1 ? 'try' : 'tries'} left.` : 'Too many wrong tries. Please ask for a new code.',
    );
  }
  const used = await query('UPDATE email_otps SET used_at = now() WHERE id = $1 AND used_at IS NULL RETURNING id', [row.id]);
  if (!used.rowCount) throw invalid();
}
