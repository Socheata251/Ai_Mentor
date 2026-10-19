import { query } from '../db.js';

/** Fire-and-forget audit record. Never throws. */
export async function audit(req, action, { userId, entity, entityId, meta } = {}) {
  try {
    await query(
      'INSERT INTO audit_logs (user_id, action, entity, entity_id, ip, meta) VALUES ($1,$2,$3,$4,$5,$6)',
      [userId ?? req.user?.id ?? null, action, entity ?? null, entityId ?? null, req.ip, meta ? JSON.stringify(meta) : null],
    );
  } catch (e) {
    console.error('audit failed', e.message);
  }
}
