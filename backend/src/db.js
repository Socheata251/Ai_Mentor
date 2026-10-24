import pg from 'pg';
import { config } from './config.js';

// Supabase (and any online PostgreSQL) needs an encrypted connection.
// Local databases (localhost / docker "db") stay unencrypted.
// Override with DB_SSL=1 (force on) or DB_SSL=0 (force off).
const url = config.databaseUrl;
const isLocal = /@(localhost|127\.0\.0\.1|db)(:|\/)/.test(url);
const useSsl = process.env.DB_SSL ? process.env.DB_SSL === '1' : !isLocal;

// Which database are we using? (host only, never the password)
export const dbHost = (url.match(/@([^/:?]+)/) || [])[1] || 'unknown';
export const dbLabel = `${dbHost} (${isLocal ? 'LOCAL' : 'ONLINE'}, SSL ${useSsl ? 'on' : 'off'})`;

export const pool = new pg.Pool({
  // Remove ?sslmode=... from the URL: the `ssl` option below decides instead,
  // so Supabase's certificate chain does not cause "self-signed certificate".
  connectionString: url.replace(/([?&])sslmode=[^&]*&?/, '$1').replace(/[?&]$/, ''),
  ssl: useSsl ? { rejectUnauthorized: false } : undefined,
  max: Number(process.env.DB_POOL_MAX || 10),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// A dropped idle connection must not crash the server.
pool.on('error', (err) => console.error('Postgres pool error:', err.message));

export const query = (text, params) => pool.query(text, params);

/** Run [fn] inside one transaction. */
export async function tx(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}