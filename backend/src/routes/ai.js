import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { wrap } from '../middleware/errors.js';
import { generateReply } from '../services/aiService.js';

export const aiRouter = Router();
aiRouter.use(requireAuth);
// AI calls cost money: limit them per IP.
aiRouter.use(rateLimit({ windowMs: 60_000, limit: 30, standardHeaders: true, legacyHeaders: false }));

const body = z.object({
  messages: z.array(z.object({ role: z.enum(['user', 'ai']), text: z.string().max(8000) })).min(1).max(40),
  language: z.enum(['English', 'Khmer']).optional(),
  hintsFirst: z.boolean().optional(),
});

/** Stateless tutor call (the app keeps its own history). Last message must be from the user. */
aiRouter.post('/chat', wrap(async (req, res) => {
  const b = body.parse(req.body);
  const last = b.messages[b.messages.length - 1];
  const { rows } = await query('SELECT language, hints_first FROM user_settings WHERE user_id = $1', [req.user.id]);
  const out = await generateReply({
    history: b.messages.slice(0, -1),
    userText: last.text,
    language: b.language ?? rows[0]?.language ?? 'English',
    hintsFirst: b.hintsFirst ?? rows[0]?.hints_first ?? true,
  });
  res.json({ blocks: out.blocks, mock: out.mock });
}));