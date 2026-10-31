import pg from 'pg';
import { config } from './config.js';

const isLocal =
  !config.databaseUrl ||
  config.databaseUrl.includes('localhost') ||
  config.databaseUrl.includes('127.0.0.1') ||
  config.databaseUrl.includes('@db:'); // docker-compose service name

export const pool = new pg.Pool({
  connectionString: config.databaseUrl,
  max: 10,
  // Supabase requires SSL; local Postgres does not
  ssl: isLocal ? false : { rejectUnauthorized: false },
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
});

pool.on('error', (err) => {
  console.error('Unexpected Postgres error:', err.message);
});

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