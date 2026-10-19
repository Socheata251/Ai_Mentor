import { createApp } from './app.js';
import { config } from './config.js';
import { pool } from './db.js';

const server = createApp().listen(config.port, () => {
  console.log(`Astra Learn API on :${config.port} (AI: ${config.ai.apiKey ? 'configured' : 'mock, AI_API_KEY is empty'})`);
});

const stop = () => server.close(() => pool.end().then(() => process.exit(0)));
process.on('SIGTERM', stop);
process.on('SIGINT', stop);
