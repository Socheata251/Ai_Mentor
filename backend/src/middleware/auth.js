import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { forbidden, unauthorized } from './errors.js';

/** Requires "Authorization: Bearer <access token>". Sets req.user = { id, role }. */
export function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(unauthorized('Missing bearer token'));
  try {
    const payload = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] });
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch (e) {
    next(unauthorized(e.name === 'TokenExpiredError' ? 'Token expired' : 'Invalid token'));
  }
}

/** Roles are read from the signed token, never from the request body. */
export const requireRole = (...roles) => (req, _res, next) =>
  roles.includes(req.user?.role) ? next() : next(forbidden('You do not have access to this resource'));