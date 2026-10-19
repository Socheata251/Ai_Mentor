// Runs every sql/*.sql file in order (safe to run again), then optionally creates an admin.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import { pool } from '../db.js';

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), '../../sql');
for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.sql')).sort()) {
  await pool.query(fs.readFileSync(path.join(dir, f), 'utf8'));
  console.log('ran', f);
}

const { ADMIN_EMAIL, ADMIN_PASSWORD } = process.env;
if (ADMIN_EMAIL && ADMIN_PASSWORD) {
  if (ADMIN_PASSWORD.length < 8) throw new Error('ADMIN_PASSWORD must have at least 8 characters');
  const hash = await bcrypt.hash(ADMIN_PASSWORD, 12);
  const r = await pool.query(
    `INSERT INTO users (name, email, password_hash, role_id)
     SELECT 'Admin', $1, $2, (SELECT id FROM roles WHERE name = 'admin')
     WHERE NOT EXISTS (SELECT 1 FROM users WHERE lower(email) = lower($1) AND deleted_at IS NULL) RETURNING id`,
    [ADMIN_EMAIL, hash],
  );
  if (r.rows[0]) await pool.query('INSERT INTO user_settings (user_id) VALUES ($1) ON CONFLICT DO NOTHING', [r.rows[0].id]);
  console.log(r.rows[0] ? 'admin created' : 'admin already exists');
}
await pool.end();
