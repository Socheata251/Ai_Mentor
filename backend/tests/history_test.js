// Run: npm test   (needs the database; skipped when DATABASE_URL is not set).
// Users are created straight in the database and given a signed token, so this works
// with either login mode and sends no email.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import { after, before, describe, it } from 'node:test';
import jwt from 'jsonwebtoken';

const haveDb = Boolean(process.env.DATABASE_URL) || fs.existsSync(new URL('../.env', import.meta.url));
let server, base, pool, tokenA, tokenB, idA, idB;
const mail = (n) => `histtest+${n}${Date.now()}@mail.dev`;

async function api(method, path, { body, token } = {}) {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, json: text ? JSON.parse(text) : null };
}
const msgs = (n = 2) => [
  { role: 'user', blocks: [{ type: 'text', text: 'What is a closure?' }], sentAt: new Date(Date.now() - 5000).toISOString() },
  { role: 'ai', blocks: [{ type: 'text', text: 'A function plus its scope.' }, { type: 'tip', text: 'Try it' }], sentAt: new Date(Date.now() - 4000).toISOString() },
  ...Array.from({ length: n - 2 }, (_, i) => ({ role: 'user', blocks: [{ type: 'text', text: `more ${i}` }] })),
];

before(async () => {
  if (!haveDb) return;
  process.env.AUTH_PROVIDER = 'local'; // tokens below are signed with our own secret
  process.env.JWT_SECRET ||= 'x'.repeat(40);
  const { createApp } = await import('../src/app.js');
  const { config } = await import('../src/config.js');
  ({ pool } = await import('../src/db.js'));
  server = createApp().listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
  const make = async (n) => {
    const { rows } = await pool.query(
      "INSERT INTO users (name, email, password_hash, email_verified_at) VALUES ($1,$2,'x',now()) RETURNING id",
      [`Hist ${n}`, mail(n)],
    );
    return [rows[0].id, jwt.sign({ role: 'student' }, config.jwtSecret, { subject: rows[0].id, expiresIn: '10m', algorithm: 'HS256' })];
  };
  [idA, tokenA] = await make('a');
  [idB, tokenB] = await make('b');
});
after(async () => {
  if (!haveDb) return;
  await pool.query('DELETE FROM users WHERE email LIKE $1', ['histtest+%@mail.dev']);
  server.close();
  await pool.end();
});

describe('chat & quiz history', { skip: !haveDb && 'no DATABASE_URL' }, () => {
  const chatId = crypto.randomUUID();

  it('needs sign-in', async () => {
    assert.equal((await api('GET', '/api/history')).status, 401);
    assert.equal((await api('PUT', `/api/history/chats/${chatId}`, { body: { messages: msgs() } })).status, 401);
  });

  it('starts empty', async () => {
    const r = await api('GET', '/api/history', { token: tokenA });
    assert.equal(r.status, 200);
    assert.deepEqual(r.json, { chats: [], attempts: [] });
  });

  it('saves a chat and loads it back with blocks and order intact', async () => {
    const put = await api('PUT', `/api/history/chats/${chatId}`, { token: tokenA, body: { title: 'What is a closure?', messages: msgs() } });
    assert.equal(put.status, 204);
    const r = await api('GET', '/api/history', { token: tokenA });
    assert.equal(r.json.chats.length, 1);
    const c = r.json.chats[0];
    assert.equal(c.id, chatId);
    assert.equal(c.title, 'What is a closure?');
    assert.deepEqual(c.messages.map((m) => m.role), ['user', 'ai']);
    assert.equal(c.messages[1].blocks[1].type, 'tip');
  });

  it('saving again replaces the messages (no duplicates) and keeps order', async () => {
    const put = await api('PUT', `/api/history/chats/${chatId}`, { token: tokenA, body: { title: 'What is a closure?', messages: msgs(4) } });
    assert.equal(put.status, 204);
    const c = (await api('GET', '/api/history', { token: tokenA })).json.chats;
    assert.equal(c.length, 1);
    assert.deepEqual(c[0].messages.map((m) => m.blocks[0].text), ['What is a closure?', 'A function plus its scope.', 'more 0', 'more 1']);
  });

  it("another student cannot read or overwrite this chat", async () => {
    assert.deepEqual((await api('GET', '/api/history', { token: tokenB })).json.chats, []);
    const put = await api('PUT', `/api/history/chats/${chatId}`, { token: tokenB, body: { messages: msgs() } });
    assert.equal(put.status, 404);
    const mine = (await api('GET', '/api/history', { token: tokenA })).json.chats[0];
    assert.equal(mine.messages.length, 4); // untouched
  });

  it('rejects bad input', async () => {
    assert.equal((await api('PUT', '/api/history/chats/not-a-uuid', { token: tokenA, body: { messages: msgs() } })).status, 404);
    assert.equal((await api('PUT', `/api/history/chats/${crypto.randomUUID()}`, { token: tokenA, body: { messages: [] } })).status, 400);
    assert.equal((await api('PUT', `/api/history/chats/${crypto.randomUUID()}`, { token: tokenA, body: { messages: [{ role: 'bot', blocks: [{}] }] } })).status, 400);
  });

  it('deleting a chat removes it from history', async () => {
    assert.equal((await api('DELETE', `/api/chats/${chatId}`, { token: tokenA })).status, 204);
    assert.deepEqual((await api('GET', '/api/history', { token: tokenA })).json.chats, []);
  });

  it('quiz attempts are saved once (clientRef) and show in history', async () => {
    const body = { topicId: 'js', answers: [0, 1, 2, 3, null], clientRef: `test-${Date.now()}` };
    const a = await api('POST', '/api/quiz/attempts', { token: tokenA, body });
    assert.equal(a.status, 201);
    const again = await api('POST', '/api/quiz/attempts', { token: tokenA, body });
    assert.equal(again.status, 200);
    const h = (await api('GET', '/api/history', { token: tokenA })).json.attempts;
    assert.equal(h.length, 1);
    assert.equal(h[0].topicId, 'js');
    assert.equal(h[0].total, a.json.attempt.total);
    assert.deepEqual((await api('GET', '/api/history', { token: tokenB })).json.attempts, []);
  });

  it('unknown quiz topic (mixed / generated quizzes) -> 404, not a crash', async () => {
    const r = await api('POST', '/api/quiz/attempts', { token: tokenA, body: { topicId: 'course-xyz', answers: [0] } });
    assert.equal(r.status, 404);
  });
});