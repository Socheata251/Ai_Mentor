import { config } from '../config.js';
import { conflict, HttpError, unauthorized } from '../middleware/errors.js';

/**
 * Thin client for Supabase Auth (GoTrue) over HTTPS. No extra package needed.
 * Only the public anon/publishable key is used here, never the service-role key.
 */
const base = () => `${config.supabase.url}/auth/v1`;

/** Supabase error body -> the same HttpError shape the Flutter app already understands. */
export function mapError(status, data) {
  const code = String(data?.error_code ?? data?.code ?? '');
  const msg = String(data?.msg ?? data?.message ?? data?.error_description ?? '');

  if (code === 'invalid_credentials' || /invalid login credentials/i.test(msg)) return unauthorized('Invalid email or password');
  if (code === 'email_not_confirmed' || /email not confirmed/i.test(msg)) {
    return new HttpError(403, 'email_not_verified', 'Please verify your email first.');
  }
  if (status === 429 || /rate.?limit|only request this after|once every/i.test(code + ' ' + msg)) {
    return new HttpError(429, 'rate_limited', 'Please wait a minute before asking for another code.');
  }
  if (code === 'weak_password') return new HttpError(400, 'weak_password', 'That password is too weak. Try a longer one.');
  if (code === 'same_password') return new HttpError(400, 'bad_request', 'New password must be different');
  if (code === 'user_already_exists' || code === 'email_exists') return conflict('An account with this email already exists');
  if (['refresh_token_not_found', 'refresh_token_already_used', 'session_not_found', 'bad_jwt', 'session_expired'].includes(code) || status === 401) {
    return unauthorized('Invalid session');
  }
  if (status >= 500) return new HttpError(502, 'auth_unavailable', 'The sign-in service had a problem. Please try again.');
  console.error('supabase auth rejected the request:', status, code, msg);
  return new HttpError(400, 'auth_error', 'The request was rejected. Please check your details and try again.');
}

async function call(method, path, { body, token } = {}) {
  let res;
  try {
    res = await fetch(`${base()}${path}`, {
      method,
      headers: {
        'content-type': 'application/json',
        apikey: config.supabase.anonKey,
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(15_000),
    });
  } catch {
    throw new HttpError(502, 'auth_unreachable', 'The sign-in service could not be reached. Please try again.');
  }
  const text = await res.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { /* not JSON */ }
  if (!res.ok) throw mapError(res.status, data);
  return data;
}

/** Create the account. Supabase emails the confirmation code (Confirm email must be ON). */
export async function signUp({ email, password, name }) {
  const data = await call('POST', '/signup', { body: { email, password, data: { name } } });
  return { user: data?.user ?? data, session: data?.access_token ? data : null };
}

/** type: 'signup' (confirm email) or 'recovery' (reset password). Returns a session. */
export async function verifyCode({ email, code, type }) {
  try {
    return await call('POST', '/verify', { body: { type, email, token: code } });
  } catch (e) {
    if (e instanceof HttpError && e.status >= 400 && e.status < 500 && e.status !== 429) {
      throw new HttpError(400, 'invalid_code', 'Invalid or expired code');
    }
    throw e;
  }
}

export const resendSignup = (email) => call('POST', '/resend', { body: { type: 'signup', email } });
export const recover = (email) => call('POST', '/recover', { body: { email } });
export const signInPassword = ({ email, password }) =>
  call('POST', '/token?grant_type=password', { body: { email, password } });
export const refresh = (refreshToken) =>
  call('POST', '/token?grant_type=refresh_token', { body: { refresh_token: refreshToken } });
export const updatePassword = (accessToken, password) =>
  call('PUT', '/user', { token: accessToken, body: { password } });
/** scope: 'local' (this session), 'others' (all but this one) or 'global' (everywhere). */
export const signOut = (accessToken, scope = 'local') =>
  call('POST', `/logout?scope=${scope}`, { token: accessToken });

/**
 * Check a password without keeping the session it creates.
 * Used before changing the password or deleting the account.
 */
export async function checkPassword({ email, password, message = 'Password is wrong' }) {
  let s;
  try {
    s = await signInPassword({ email, password });
  } catch (e) {
    if (e instanceof HttpError && e.status === 401) throw unauthorized(message);
    throw e;
  }
  signOut(s.access_token, 'local').catch(() => {});
}