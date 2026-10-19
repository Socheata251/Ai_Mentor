import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notFound, wrap } from '../middleware/errors.js';
import { generateReply } from '../services/aiService.js';
import { blocksToText, userTextToBlocks } from '../utils/blocks.js';

export const chatsRouter = Router();
chatsRouter.use(requireAuth);

const msgOut = (m) => ({ id: m.id, role: m.role, blocks: m.blocks, sentAt: m.created_at });
const chatOut = (c) => ({ id: c.id, title: c.title, createdAt: c.created_at, updatedAt: c.updated_at });

async function ownChat(userId, id) {
  if (!/^[0-9a-f-]{36}$/i.test(id)) throw notFound('Chat not found');
  const { rows } = await query('SELECT * FROM conversations WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL', [id, userId]);
  if (!rows[0]) throw notFound('Chat not found');
  return rows[0];
}

chatsRouter.get('/', wrap(async (req, res) => {
  const { rows } = await query(
    'SELECT * FROM conversations WHERE user_id = $1 AND deleted_at IS NULL ORDER BY updated_at DESC LIMIT 100',
    [req.user.id],
  );
  res.json({ chats: rows.map(chatOut) });
}));

chatsRouter.post('/', wrap(async (req, res) => {
  const { title } = z.object({ title: z.string().trim().min(1).max(120).optional() }).parse(req.body ?? {});
  const { rows } = await query('INSERT INTO conversations (user_id, title) VALUES ($1,$2) RETURNING *', [req.user.id, title ?? 'New chat']);
  res.status(201).json({ chat: chatOut(rows[0]) });
}));

chatsRouter.get('/:id', wrap(async (req, res) => {
  const chat = await ownChat(req.user.id, req.params.id);
  const { rows } = await query('SELECT * FROM messages WHERE conversation_id = $1 ORDER BY created_at, id', [chat.id]);
  res.json({ chat: chatOut(chat), messages: rows.map(msgOut) });
}));

chatsRouter.delete('/:id', wrap(async (req, res) => {
  const chat = await ownChat(req.user.id, req.params.id);
  await query('UPDATE conversations SET deleted_at = now() WHERE id = $1', [chat.id]);
  res.status(204).end();
}));

const sendBody = z.object({
  text: z.string().trim().min(1).max(8000),
  language: z.enum(['English', 'Khmer']).optional(), // default: the saved setting
});

// Save the student's message, ask the AI, save + return the reply.
chatsRouter.post('/:id/messages', wrap(async (req, res) => {
  const chat = await ownChat(req.user.id, req.params.id);
  const b = sendBody.parse(req.body);

  const { rows: st } = await query('SELECT language, hints_first FROM user_settings WHERE user_id = $1', [req.user.id]);
  const language = b.language ?? st[0]?.language ?? 'English';
  const hintsFirst = st[0]?.hints_first ?? true;

  const { rows: past } = await query('SELECT role, blocks FROM messages WHERE conversation_id = $1 ORDER BY created_at, id', [chat.id]);
  const history = past.map((m) => ({ role: m.role, text: blocksToText(m.blocks) }));

  const userBlocks = userTextToBlocks(b.text);
  const { rows: um } = await query(
    "INSERT INTO messages (conversation_id, role, blocks) VALUES ($1,'user',$2) RETURNING *",
    [chat.id, JSON.stringify(userBlocks)],
  );

  const { blocks, mock } = await generateReply({ history, userText: b.text, language, hintsFirst });

  const reply = await tx(async (c) => {
    const { rows } = await c.query(
      "INSERT INTO messages (conversation_id, role, blocks) VALUES ($1,'ai',$2) RETURNING *",
      [chat.id, JSON.stringify(blocks)],
    );
    // First message names the chat, like "New chat" in ChatGPT.
    await c.query(
      `UPDATE conversations SET updated_at = now(),
         title = CASE WHEN title = 'New chat' THEN left($2, 60) ELSE title END WHERE id = $1`,
      [chat.id, b.text.replace(/\s+/g, ' ')],
    );
    return rows[0];
  });
  res.status(201).json({ userMessage: msgOut(um[0]), reply: msgOut(reply), mock });
}));
