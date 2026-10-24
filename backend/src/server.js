import { createApp } from './app.js';
import { config } from './config.js';
import { pool, dbLabel } from './db.js';
import { aiMode } from './services/aiService.js';

const server = createApp().listen(config.port, () => {
  console.log(`Astra Learn API on :${config.port} (AI: ${aiMode()})`);
  console.log(`Database: ${dbLabel}`);
  // Test the database right away so a wrong password / address is obvious.
  pool
    .query('SELECT 1')
    .then(() => console.log('Database connected OK'))
    .catch((e) =>
      console.error(`DATABASE CONNECTION FAILED: ${e.code || ''} ${e.message}`),
    );
});

const stop = () => server.close(() => pool.end().then(() => process.exit(0)));
process.on('SIGTERM', stop);
process.on('SIGINT', stop);