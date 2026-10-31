import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';

/**
 * "Chat & Practice History": everything the app needs after sign-in in ONE call,
 * plus a save endpoint for a whole chat. Chats are saved by the app with its own
 * UUID, so saving is safe to repeat (it always replaces that chat's messages).
 */
export const historyRouter = Router();
historyRouter.use(requireAuth);

const MAX_CHATS = 50;
const MAX_MESSAGES = 60;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const attemptOut = (a) => ({
  id: a.id, topicId: a.topic_id, topicTitle: a.topic_title, category: a.category,
  score: a.score, total: a.total, xp: a.xp, date: a.created_at,
});

historyRouter.get('/', wrap(async (req, res) => {
  const { rows: chats } = await query(
    `SELECT id, title, created_at, updated_at FROM conversations
     WHERE user_id = $1 AND deleted_at IS NULL
       AND EXISTS (SELECT 1 FROM messages m WHERE m.conversation_id = conversations.id)
     ORDER BY updated_at DESC LIMIT $2`,
    [req.user.id, MAX_CHATS],
  );
  const byChat = new Map(chats.map((c) => [c.id, []]));
  if (chats.length) {
    const { rows: msgs } = await query(
      'SELECT conversation_id, role, blocks, created_at FROM messages WHERE conversation_id = ANY($1::uuid[]) ORDER BY created_at, id',
      [chats.map((c) => c.id)],
    );
    for (const m of msgs) byChat.get(m.conversation_id)?.push({ role: m.role, blocks: m.blocks, sentAt: m.created_at });
  }
  const { rows: attempts } = await query(
    `SELECT a.*, t.title AS topic_title, t.category FROM quiz_attempts a JOIN quiz_topics t ON t.id = a.topic_id
     WHERE a.user_id = $1 ORDER BY a.created_at DESC LIMIT 100`,
    [req.user.id],
  );
  res.json({
    chats: chats.map((c) => ({ id: c.id, title: c.title, updatedAt: c.updated_at, messages: byChat.get(c.id) })),
    attempts: attempts.map(attemptOut),
  });
}));

const saveBody = z.object({
  title: z.string().trim().min(1).max(120).optional(),
  messages: z.array(z.object({
    role: z.enum(['user', 'ai']),
    blocks: z.array(z.record(z.unknown())).min(1).max(30),
    sentAt: z.string().datetime({ offset: true }).optional(),
  })).min(1).max(MAX_MESSAGES),
});

// Save (create or update) one whole chat.
historyRouter.put('/chats/:id', wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) throw notFound('Chat not found');
  const b = saveBody.parse(req.body);
  const title = (b.title ?? 'New chat').slice(0, 120);

  const saved = await tx(async (c) => {
    // Only the owner can write to a chat. Another user's id is treated as "not found".
    const up = await c.query(
      `INSERT INTO conversations (id, user_id, title) VALUES ($1,$2,$3)
       ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, updated_at = now(), deleted_at = NULL
       WHERE conversations.user_id = EXCLUDED.user_id
       RETURNING id`,
      [req.params.id, req.user.id, title],
    );
    if (!up.rows[0]) return false;
    await c.query('DELETE FROM messages WHERE conversation_id = $1', [req.params.id]);
    const base = Date.now() - b.messages.length;
    for (const [i, m] of b.messages.entries()) {
      const sent = m.sentAt ? Date.parse(m.sentAt) : base + i;
      // +i keeps the order even when two messages share the same millisecond
      await c.query(
        'INSERT INTO messages (conversation_id, role, blocks, created_at) VALUES ($1,$2,$3,$4)',
        [req.params.id, m.role, JSON.stringify(m.blocks), new Date(sent + i)],
      );
    }
    return true;
  });
  if (!saved) throw notFound('Chat not found');
  res.status(204).end();
}));