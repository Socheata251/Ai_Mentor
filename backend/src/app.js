import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { config } from './config.js';
import { query } from './db.js';
import { aiMode } from './services/aiService.js';
import { errorHandler, notFoundHandler, wrap } from './middleware/errors.js';
import { adminRouter } from './routes/admin.js';
import { aiRouter } from './routes/ai.js';
import { authRouter } from './routes/auth.js';
import { chatsRouter } from './routes/chats.js';
import { coursesRouter } from './routes/courses.js';
import { notificationsRouter } from './routes/notifications.js';
import { progressRouter } from './routes/progress.js';
import { quizRouter } from './routes/quiz.js';
import { scheduleRouter } from './routes/schedule.js';
import { settingsRouter } from './routes/settings.js';
import { usersRouter } from './routes/users.js';

export function createApp() {
  const app = express();
  if (config.trustProxy) app.set('trust proxy', 1);
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: config.corsOrigins.includes('*') ? true : config.corsOrigins }));
  app.use(express.json({ limit: '256kb' }));
  app.use(rateLimit({ windowMs: 15 * 60_000, limit: 600, standardHeaders: true, legacyHeaders: false }));

  app.get('/api/health', wrap(async (_req, res) => {
    await query('SELECT 1');
    res.json({ status: 'ok', ai: aiMode() });
  }));

  // Stricter limit on login / register / reset (brute-force protection)
  app.use('/api/auth', rateLimit({ windowMs: 15 * 60_000, limit: config.authRateMax, standardHeaders: true, legacyHeaders: false }), authRouter);
  app.use('/api/users', usersRouter);
  app.use('/api/settings', settingsRouter);
  app.use('/api/courses', coursesRouter);
  app.use('/api/quiz', quizRouter);
  app.use('/api/chats', chatsRouter);
  app.use('/api/ai', aiRouter);
  app.use('/api/schedule', scheduleRouter);
  app.use('/api/progress', progressRouter);
  app.use('/api/notifications', notificationsRouter);
  app.use('/api/admin', adminRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}