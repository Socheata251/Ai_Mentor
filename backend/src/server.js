import { createApp } from './app.js';
import { config } from './config.js';
import { pool } from './db.js';
import { aiMode } from './services/aiService.js';

const server = createApp().listen(config.port, () => {
  console.log(`Astra Learn API on :${config.port} (AI: ${aiMode()})`);
});

const stop = () => server.close(() => pool.end().then(() => process.exit(0)));
process.on('SIGTERM', stop);
process.on('SIGINT', stop);