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

// The student/instructor/admin role lives in our own table, not in the Supabase token.
const roleCache = new Map(); // userId -> { role, until }
const ROLE_TTL_MS = 30_000;
async function roleOf(userId) {
  const hit = roleCache.get(userId);
  if (hit && hit.until > Date.now()) return hit.role;
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