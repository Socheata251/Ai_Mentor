import jwt from 'jsonwebtoken';
import { createRemoteJWKSet, decodeProtectedHeader, jwtVerify } from 'jose';
import { config } from '../config.js';
import { query } from '../db.js';
import { forbidden, unauthorized } from './errors.js';

let jwks;
const hsKey = () => (config.supabase.jwtSecret ? new TextEncoder().encode(config.supabase.jwtSecret) : null);

/** Check a Supabase access token (signature, issuer, audience, expiry). Returns its payload. */
export async function verifySupabaseToken(token) {
  const issuer = `${config.supabase.url}/auth/v1`;
  const opts = { issuer, audience: 'authenticated' };
  const { alg } = decodeProtectedHeader(token);
  if (alg === 'HS256') {
    const key = hsKey();
    if (!key) throw new Error('SUPABASE_JWT_SECRET is needed for HS256 tokens');
    return (await jwtVerify(token, key, { ...opts, algorithms: ['HS256'] })).payload;
  }
  // Newer projects sign with an asymmetric key: fetch the public keys (cached by jose).
  jwks ??= createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`));
  return (await jwtVerify(token, jwks, { ...opts, algorithms: ['ES256', 'RS256'] })).payload;
}

<<<<<<< HEAD
// The student/instructor/admin role lives in our own table, not in the Supabase token.
const roleCache = new Map(); // userId -> { role, until }
const ROLE_TTL_MS = 30_000;
async function roleOf(userId) {
  const hit = roleCache.get(userId);
  if (hit && hit.until > Date.now()) return hit.role;
=======
const codeField = z.string().trim().regex(/^\d{6}$/, 'The code has 6 digits');
const emailField = z.string().trim().toLowerCase().email().max(254);
const otpInfo = () => ({ expiresInSeconds: config.otp.ttlMinutes * 60, resendAfterSeconds: config.otp.cooldownSeconds });

// Step 1 of sign-up: create the account (not verified yet) and email a 6-digit code.
authRouter.post('/register', wrap(async (req, res) => {
  const b = registerBody.parse(req.body);
  const hash = await bcrypt.hash(b.password, 12);
  try {
    await tx(async (c) => {
      const { rows: old } = await c.query(
        'SELECT id, email_verified_at FROM users WHERE lower(email) = $1 AND deleted_at IS NULL FOR UPDATE', [b.email],
      );
      if (old[0]) {
        if (old[0].email_verified_at) throw conflict('An account with this email already exists');
        // An unverified sign-up that was never finished: let the person start again.
        await c.query(
          `UPDATE users SET name = $2, password_hash = $3, university = COALESCE($4,university), semester = COALESCE($5,semester) WHERE id = $1`,
          [old[0].id, b.name, hash, b.university ?? null, b.semester ?? null],
        );
        return;
      }
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
        id, 'Welcome to iLearnCode', 'Ask the AI tutor a question or take your first quiz.',
      ]);
    });
  } catch (e) {
    if (e.code === '23505') throw conflict('An account with this email already exists');
    throw e;
  }
  const sent = await issueOtp({ email: b.email, purpose: 'verify' });
  await audit(req, 'auth.register', { entity: 'user', meta: { email: b.email } });
  res.status(201).json({ requiresVerification: true, email: b.email, ...otpInfo(), ...(sent.devCode ? { devCode: sent.devCode } : {}) });
}));

// Step 2 of sign-up: the code from the email. Success = signed in.
authRouter.post('/verify-email', wrap(async (req, res) => {
  const b = z.object({ email: emailField, code: codeField, device: z.string().max(120).optional() }).parse(req.body);
  await verifyOtp({ email: b.email, purpose: 'verify', code: b.code });
  const result = await tx(async (c) => {
    const { rows } = await c.query(
      'UPDATE users SET email_verified_at = COALESCE(email_verified_at, now()) WHERE lower(email) = $1 AND deleted_at IS NULL RETURNING id', [b.email],
    );
    if (!rows[0]) throw new HttpError(400, 'invalid_code', 'Invalid or expired code');
    const { rows: u } = await c.query(`${USER_SELECT} WHERE u.id = $1`, [rows[0].id]);
    return startSession(c, u[0], b.device);
  });
  await audit(req, 'auth.verify_email', { userId: result.user.id });
  res.json(result);
}));

// Send a new code. Same answer whether or not the email exists (no account guessing).
authRouter.post('/resend-code', wrap(async (req, res) => {
  const b = z.object({ email: emailField, purpose: z.enum(['verify', 'reset']).default('verify') }).parse(req.body);
  const { rows } = await query('SELECT email_verified_at FROM users WHERE lower(email) = $1 AND deleted_at IS NULL', [b.email]);
  const body = { message: 'If this email can use a code, a new code was sent.', ...otpInfo() };
  const allowed = rows[0] && (b.purpose === 'reset' || !rows[0].email_verified_at);
  if (allowed) {
    const sent = await issueOtp({ email: b.email, purpose: b.purpose });
    if (sent.devCode) body.devCode = sent.devCode;
  }
  res.json(body);
}));

// Compare against a dummy hash when the user does not exist, so timing does not reveal accounts.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', 12);

authRouter.post('/login', wrap(async (req, res) => {
  const b = loginBody.parse(req.body);
>>>>>>> c63214814ad55bba326332e22af94b7d700ab650
  const { rows } = await query(
    'SELECT r.name AS role FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = $1 AND u.deleted_at IS NULL',
    [userId],
  );
  const role = rows[0]?.role ?? null;
  if (roleCache.size > 5000) roleCache.clear();
  roleCache.set(userId, { role, until: Date.now() + ROLE_TTL_MS });
  return role;
}

/** Call after deleting an account so its token stops working at once. */
export const forgetRole = (userId) => roleCache.delete(userId);

/** Requires "Authorization: Bearer <access token>". Sets req.user = { id, role }. */
export async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(unauthorized('Missing bearer token'));
  try {
    if (config.authProvider === 'supabase') {
      const payload = await verifySupabaseToken(token);
      const role = await roleOf(payload.sub);
      if (!role) return next(unauthorized('Account not found'));
      req.user = { id: payload.sub, role };
      req.accessToken = token; // needed to change the password at Supabase
    } else {
      const payload = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] });
      req.user = { id: payload.sub, role: payload.role };
    }
    next();
  } catch (e) {
    const expired = e.name === 'TokenExpiredError' || e.code === 'ERR_JWT_EXPIRED';
    next(unauthorized(expired ? 'Token expired' : 'Invalid token'));
  }
}

/** Roles are read from the signed token / our own table, never from the request body. */
export const requireRole = (...roles) => (req, _res, next) =>
  roles.includes(req.user?.role) ? next() : next(forbidden('You do not have access to this resource'));