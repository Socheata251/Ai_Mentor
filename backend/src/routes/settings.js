import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { wrap } from '../middleware/errors.js';

export const settingsRouter = Router();
settingsRouter.use(requireAuth);

const out = (r) => ({
  language: r.language, hintsFirst: r.hints_first, aiModel: r.ai_model, codeFormat: r.code_format, darkMode: r.dark_mode,
});

settingsRouter.get('/', wrap(async (req, res) => {
  await query('INSERT INTO user_settings (user_id) VALUES ($1) ON CONFLICT DO NOTHING', [req.user.id]);
  const { rows } = await query('SELECT * FROM user_settings WHERE user_id = $1', [req.user.id]);
  res.json({ settings: out(rows[0]) });
}));

const body = z.object({
  language: z.enum(['English', 'Khmer']).optional(),
  hintsFirst: z.boolean().optional(),
  aiModel: z.string().max(60).optional(),
  codeFormat: z.enum(['Auto', '2 spaces', '4 spaces', 'Tabs']).optional(),
  darkMode: z.enum(['system', 'light', 'dark']).optional(),
});

settingsRouter.put('/', wrap(async (req, res) => {
  const b = body.parse(req.body);
  await query('INSERT INTO user_settings (user_id) VALUES ($1) ON CONFLICT DO NOTHING', [req.user.id]);
  const { rows } = await query(
    `UPDATE user_settings SET language = COALESCE($2,language), hints_first = COALESCE($3,hints_first),
       ai_model = COALESCE($4,ai_model), code_format = COALESCE($5,code_format), dark_mode = COALESCE($6,dark_mode)
     WHERE user_id = $1 RETURNING *`,
    [req.user.id, b.language ?? null, b.hintsFirst ?? null, b.aiModel ?? null, b.codeFormat ?? null, b.darkMode ?? null],
  );
  res.json({ settings: out(rows[0]) });
}));