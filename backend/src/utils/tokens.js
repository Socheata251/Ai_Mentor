import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';

export const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');
export const randomToken = () => crypto.randomBytes(48).toString('base64url');

export const signAccessToken = (user) =>
  jwt.sign({ role: user.role }, config.jwtSecret, {
    subject: user.id,
    expiresIn: config.accessTtl,
    algorithm: 'HS256',
  });

/** Create + store a refresh token (only its hash is saved). */
export async function issueRefreshToken(client, userId, device) {
  const token = randomToken();
  const expires = new Date(Date.now() + config.refreshDays * 86400_000);
  await client.query(
    'INSERT INTO refresh_tokens (user_id, token_hash, device, expires_at) VALUES ($1,$2,$3,$4)',
    [userId, sha256(token), device ?? null, expires],
  );
  return token;
}
