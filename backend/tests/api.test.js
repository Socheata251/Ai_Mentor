// Run: npm test   (needs the database from .env, already created with `npm run db:init`)
import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import jwt from 'jsonwebtoken';
import { createApp } from '../src/app.js';
import { config } from '../src/config.js';
import { pool } from '../src/db.js';

let server, base;
const email = `test+${Date.now()}@mail.dev`;
const pw = 'Passw0rd!x';
let access, refresh, userId;

async function api(method, path, { body, token, headers } = {}) {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}), ...headers },
    body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, json: text ? JSON.parse(text) : null };
}

/** Register + confirm the email code (the API returns devCode while no SMTP is set up). */
async function signUp(name, mail, password = pw) {
  const r = await api('POST', '/api/auth/register', { body: { name, email: mail, password } });
  assert.equal(r.status, 201);
  assert.ok(r.json.devCode, 'devCode is returned in development without SMTP');
  const v = await api('POST', '/api/auth/verify-email', { body: { email: mail, code: r.json.devCode } });
  assert.equal(v.status, 200);
  return v.json;
}

before(async () => {
  server = createApp().listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
});
after(async () => {
  await pool.query('DELETE FROM users WHERE email LIKE $1', ['test+%@mail.dev']);
  server.close();
  await pool.end();
});

describe('health + auth', () => {
  it('health works and reports mock AI while key is empty', async () => {
    const r = await api('GET', '/api/health');
    assert.equal(r.status, 200);
    assert.equal(r.json.ai, 'mock');
  });

  it('rejects invalid input (400)', async () => {
    const r = await api('POST', '/api/auth/register', { body: { name: '', email: 'bad', password: '123' } });
    assert.equal(r.status, 400);
    assert.equal(r.json.error.code, 'validation_error');
  });

  it('rejects malformed JSON (400)', async () => {
    const r = await api('POST', '/api/auth/login', { body: '{oops' });
    assert.equal(r.status, 400);
  });

  let regCode;
  it('register (201) needs an email code and returns NO tokens', async () => {
    const r = await api('POST', '/api/auth/register', { body: { name: 'Test User', email, password: pw } });
    assert.equal(r.status, 201);
    assert.equal(r.json.requiresVerification, true);
    assert.equal(r.json.accessToken, undefined);
    assert.match(r.json.devCode, /^\d{6}$/);
    assert.ok(!JSON.stringify(r.json).includes('password'));
    regCode = r.json.devCode;
  });

  it('login before the email is verified -> 403 email_not_verified', async () => {
    const r = await api('POST', '/api/auth/login', { body: { email, password: pw } });
    assert.equal(r.status, 403);
    assert.equal(r.json.error.code, 'email_not_verified');
    const bad = await api('POST', '/api/auth/login', { body: { email, password: 'wrong-password' } });
    assert.equal(bad.status, 401); // a wrong password never reveals the verification state
  });

  it('wrong code -> 400 with tries left; code must have 6 digits', async () => {
    const wrong = regCode === '000000' ? '111111' : '000000';
    const r = await api('POST', '/api/auth/verify-email', { body: { email, code: wrong } });
    assert.equal(r.status, 400);
    assert.match(r.json.error.message, /4 tries left/);
    assert.equal((await api('POST', '/api/auth/verify-email', { body: { email, code: '12ab' } })).status, 400);
  });

  it('right code signs you in (200) and works only once', async () => {
    const r = await api('POST', '/api/auth/verify-email', { body: { email, code: regCode } });
    assert.equal(r.status, 200);
    assert.ok(r.json.accessToken && r.json.refreshToken);
    assert.equal(r.json.user.role, 'student');
    assert.ok(!JSON.stringify(r.json).includes('password'));
    ({ accessToken: access, refreshToken: refresh } = r.json);
    userId = r.json.user.id;
    const again = await api('POST', '/api/auth/verify-email', { body: { email, code: regCode } });
    assert.equal(again.status, 400);
  });

  it('duplicate email -> 409', async () => {
    const r = await api('POST', '/api/auth/register', { body: { name: 'Again', email: email.toUpperCase(), password: pw } });
    assert.equal(r.status, 409);
  });

  it('invalid login -> 401 (same message for wrong password and unknown email)', async () => {
    const a = await api('POST', '/api/auth/login', { body: { email, password: 'wrong-password' } });
    const b = await api('POST', '/api/auth/login', { body: { email: 'nobody@mail.dev', password: 'wrong-password' } });
    assert.equal(a.status, 401);
    assert.equal(b.status, 401);
    assert.equal(a.json.error.message, b.json.error.message);
  });

  it('login ok', async () => {
    const r = await api('POST', '/api/auth/login', { body: { email, password: pw } });
    assert.equal(r.status, 200);
  });
});

describe('authorization', () => {
  it('no token -> 401', async () => assert.equal((await api('GET', '/api/users/me')).status, 401));
  it('garbage token -> 401', async () => assert.equal((await api('GET', '/api/users/me', { token: 'abc.def.ghi' })).status, 401));

  it('expired token -> 401', async () => {
    const old = jwt.sign({ role: 'student' }, config.jwtSecret, { subject: userId, expiresIn: -10 });
    const r = await api('GET', '/api/users/me', { token: old });
    assert.equal(r.status, 401);
    assert.equal(r.json.error.message, 'Token expired');
  });

  it('token signed with another secret -> 401', async () => {
    const fake = jwt.sign({ role: 'admin' }, 'another-secret', { subject: userId });
    assert.equal((await api('GET', '/api/admin/users', { token: fake })).status, 401);
  });

  it('student cannot use admin API -> 403', async () => {
    assert.equal((await api('GET', '/api/admin/users', { token: access })).status, 403);
    assert.equal((await api('GET', '/api/admin/audit-logs', { token: access })).status, 403);
  });

  it('admin can read audit logs', async () => {
    const login = await api('POST', '/api/auth/login', { body: { email: 'admin@test.dev', password: 'Admin12345' } });
    assert.equal(login.status, 200);
    const r = await api('GET', '/api/admin/audit-logs', { token: login.json.accessToken });
    assert.equal(r.status, 200);
    assert.ok(r.json.logs.some((l) => l.action === 'auth.login_failed'));
  });

  it('unknown route -> 404 JSON', async () => {
    const r = await api('GET', '/api/nope');
    assert.equal(r.status, 404);
  });
});

describe('profile + settings', () => {
  it('GET/PATCH me', async () => {
    assert.equal((await api('GET', '/api/users/me', { token: access })).json.user.email, email);
    const r = await api('PATCH', '/api/users/me', { token: access, body: { name: 'New Name', semester: 5 } });
    assert.equal(r.json.user.name, 'New Name');
    assert.equal(r.json.user.semester, 5);
    assert.equal((await api('PATCH', '/api/users/me', { token: access, body: { semester: 99 } })).status, 400);
  });

  it('role cannot be changed through profile update', async () => {
    const r = await api('PATCH', '/api/users/me', { token: access, body: { name: 'X', role: 'admin' } });
    assert.equal(r.json.user.role, 'student');
  });

  it('settings default + update', async () => {
    const g = await api('GET', '/api/settings', { token: access });
    assert.equal(g.json.settings.language, 'Khmer');
    const p = await api('PUT', '/api/settings', { token: access, body: { language: 'English', hintsFirst: false } });
    assert.equal(p.json.settings.language, 'English');
    assert.equal(p.json.settings.hintsFirst, false);
    assert.equal((await api('PUT', '/api/settings', { token: access, body: { language: 'French' } })).status, 400);
  });
});

describe('courses, quiz, progress', () => {
  it('courses list/filter/progress', async () => {
    const all = await api('GET', '/api/courses', { token: access });
    assert.equal(all.json.courses.length, 8);
    const s4 = await api('GET', '/api/courses?semester=4', { token: access });
    assert.ok(s4.json.courses.every((c) => c.semester === 4));
    const q = await api('GET', '/api/courses?q=flutter', { token: access });
    assert.equal(q.json.courses[0].code, 'CS 361');
    // CS 230 has no lessons, so its progress is the manual value
    assert.equal((await api('PUT', '/api/courses/CS%20230/progress', { token: access, body: { progress: 0.5 } })).status, 200);
    assert.equal((await api('PUT', '/api/courses/CS%20230/progress', { token: access, body: { progress: 2 } })).status, 400);
    assert.equal((await api('GET', '/api/courses/CS%20230', { token: access })).json.course.progress, 0.5);
    assert.equal((await api('GET', '/api/courses/NOPE', { token: access })).status, 404);
  });

  it('quiz topics + questions', async () => {
    const t = await api('GET', '/api/quiz/topics', { token: access });
    assert.equal(t.json.topics.length, 5);
    const js = await api('GET', '/api/quiz/topics/js', { token: access });
    assert.equal(js.json.topic.questions.length, 6);
    assert.equal(js.json.topic.questions[0].options[0], 'push()');
  });

  it('server grades the attempt and is idempotent', async () => {
    const js = (await api('GET', '/api/quiz/topics/js', { token: access })).json.topic;
    const answers = js.questions.map((q, i) => (i < 4 ? q.correctIndex : (q.correctIndex + 1) % q.options.length));
    const body = { topicId: 'js', answers, clientRef: 'attempt-12345678' };
    const a = await api('POST', '/api/quiz/attempts', { token: access, body });
    assert.equal(a.status, 201);
    assert.equal(a.json.attempt.score, 4);
    assert.equal(a.json.attempt.xp, 40);
    const dup = await api('POST', '/api/quiz/attempts', { token: access, body });
    assert.equal(dup.status, 200);
    assert.equal(dup.json.attempt.id, a.json.attempt.id);
    const list = await api('GET', '/api/quiz/attempts', { token: access });
    assert.equal(list.json.attempts.length, 1); // no duplicate saved
    assert.equal((await api('POST', '/api/quiz/attempts', { token: access, body: { topicId: 'nope', answers: [0] } })).status, 404);
  });

  it('progress summary', async () => {
    const s = (await api('GET', '/api/progress/summary', { token: access })).json;
    assert.equal(s.quizzesTaken, 1);
    assert.equal(s.totalXp, 40);
    assert.equal(s.bestPercent, 67);
    assert.equal(s.streakDays, 1);
  });
});

describe('lessons (library, no AI)', () => {
  let lessons;
  it('requires login', async () => {
    assert.equal((await api('GET', '/api/courses/CS%20262/lessons')).status, 401);
    assert.equal((await api('GET', '/api/lessons/1')).status, 401);
  });

  it('lists the lessons of a course in order', async () => {
    const r = await api('GET', '/api/courses/CS%20262/lessons', { token: access });
    assert.equal(r.status, 200);
    assert.equal(r.json.total, 5);
    assert.equal(r.json.completedCount, 0);
    assert.deepEqual(r.json.lessons.map((l) => l.position), [1, 2, 3, 4, 5]);
    assert.equal(r.json.lessons[0].slug, 'html-structure');
    lessons = r.json.lessons;
  });

  it('a course without lessons returns an empty list; unknown course is 404', async () => {
    const r = await api('GET', '/api/courses/CS%20230/lessons', { token: access });
    assert.equal(r.status, 200);
    assert.equal(r.json.total, 0);
    assert.equal((await api('GET', '/api/courses/NOPE/lessons', { token: access })).status, 404);
  });

  it('lesson detail has blocks, prev and next', async () => {
    const mid = await api('GET', `/api/lessons/${lessons[1].id}`, { token: access });
    assert.equal(mid.status, 200);
    assert.equal(mid.json.lesson.courseTitle, 'Adv. Web Development');
    assert.ok(mid.json.lesson.blocks.some((b) => b.type === 'code'));
    assert.equal(mid.json.prev.id, lessons[0].id);
    assert.equal(mid.json.next.id, lessons[2].id);
    const first = await api('GET', `/api/lessons/${lessons[0].id}`, { token: access });
    assert.equal(first.json.prev, null);
    assert.equal((await api('GET', '/api/lessons/999999', { token: access })).status, 404);
    assert.equal((await api('GET', '/api/lessons/abc', { token: access })).status, 404);
  });

  it('marking lessons done updates the course progress', async () => {
    const a = await api('PUT', `/api/lessons/${lessons[0].id}/progress`, { token: access, body: { completed: true } });
    assert.deepEqual([a.json.courseDone, a.json.courseTotal], [1, 5]);
    await api('PUT', `/api/lessons/${lessons[0].id}/progress`, { token: access, body: { completed: true } }); // twice = still 1
    await api('PUT', `/api/lessons/${lessons[1].id}/progress`, { token: access, body: { completed: true } });
    const c = await api('GET', '/api/courses/CS%20262', { token: access });
    assert.equal(c.json.course.progress, 0.4);
    assert.equal(c.json.course.lessonsDone, 2);
    const d = await api('GET', `/api/lessons/${lessons[0].id}`, { token: access });
    assert.equal(d.json.lesson.completed, true);
    const undo = await api('PUT', `/api/lessons/${lessons[1].id}/progress`, { token: access, body: { completed: false } });
    assert.equal(undo.json.courseDone, 1);
    assert.equal((await api('PUT', `/api/lessons/${lessons[0].id}/progress`, { token: access, body: { completed: 'yes' } })).status, 400);
  });

  it("one student's progress is not visible to another", async () => {
    const other = await signUp('Other2', `test+p${Date.now()}@mail.dev`);
    const r = await api('GET', '/api/courses/CS%20262/lessons', { token: other.accessToken });
    assert.equal(r.json.completedCount, 0);
  });
});

describe('chats + AI (mock)', () => {
  let chatId;
  it('create chat, send message, get mock reply, history saved', async () => {
    const c = await api('POST', '/api/chats', { token: access, body: {} });
    assert.equal(c.status, 201);
    chatId = c.json.chat.id;
    const m = await api('POST', `/api/chats/${chatId}/messages`, { token: access, body: { text: 'What is recursion?' } });
    assert.equal(m.status, 201);
    assert.equal(m.json.mock, true);
    assert.equal(m.json.reply.role, 'ai');
    assert.ok(m.json.reply.blocks.some((b) => b.type === 'tip'));
    const withCode = await api('POST', `/api/chats/${chatId}/messages`, { token: access, body: { text: 'Fix:\n```js\nlet a = 1\n```' } });
    assert.ok(withCode.json.userMessage.blocks.some((b) => b.type === 'code' && b.language === 'js'));
    const h = await api('GET', `/api/chats/${chatId}`, { token: access });
    assert.equal(h.json.messages.length, 4);
    assert.equal(h.json.chat.title, 'What is recursion?');
  });

  it("another user cannot read this chat (404)", async () => {
    const other = await signUp('Other', `test+o${Date.now()}@mail.dev`);
    const r = await api('GET', `/api/chats/${chatId}`, { token: other.accessToken });
    assert.equal(r.status, 404);
  });

  it('stateless /api/ai/chat works in Khmer', async () => {
    const r = await api('POST', '/api/ai/chat', { token: access, body: { messages: [{ role: 'user', text: 'hi' }], language: 'Khmer' } });
    assert.equal(r.status, 200);
    assert.match(r.json.blocks[0].text, /[\u1780-\u17FF]/);
  });

  it('hint mode (hintsFirst: true) returns hint + quick_check with the real answer attached', async () => {
    const r = await api('POST', '/api/ai/chat', { token: access, body: { messages: [{ role: 'user', text: 'What is recursion?' }], language: 'English', hintsFirst: true } });
    assert.equal(r.status, 200);
    const q = r.json.blocks.find((b) => b.type === 'quick_check');
    assert.ok(q && q.options.length >= 2 && q.answerBlocks.length > 0);
    assert.ok(r.json.blocks[0].type === 'text');
  });

  it('delete chat (soft)', async () => {
    assert.equal((await api('DELETE', `/api/chats/${chatId}`, { token: access })).status, 204);
    assert.equal((await api('GET', `/api/chats/${chatId}`, { token: access })).status, 404);
  });
});

describe('schedule + notifications', () => {
  it('default sessions, toggle, create, delete', async () => {
    const l = await api('GET', '/api/schedule', { token: access });
    assert.equal(l.json.sessions.length, 4);
    const id = l.json.sessions[0].id;
    assert.equal((await api('PATCH', `/api/schedule/${id}`, { token: access, body: { enabled: false } })).json.session.enabled, false);
    const c = await api('POST', '/api/schedule', { token: access, body: { title: 'Revise SQL', time: 'Mon 5 PM' } });
    assert.equal(c.status, 201);
    assert.equal((await api('DELETE', `/api/schedule/${c.json.session.id}`, { token: access })).status, 204);
    assert.equal((await api('DELETE', `/api/schedule/${c.json.session.id}`, { token: access })).status, 404);
  });

  it('welcome notification, mark read', async () => {
    const n = await api('GET', '/api/notifications', { token: access });
    assert.equal(n.json.unread, 1);
    assert.equal((await api('POST', '/api/notifications/read-all', { token: access })).status, 204);
    assert.equal((await api('GET', '/api/notifications', { token: access })).json.unread, 0);
  });
});

describe('refresh / logout / password', () => {
  it('refresh rotates; reusing the old token revokes everything', async () => {
    const r1 = await api('POST', '/api/auth/refresh', { body: { refreshToken: refresh } });
    assert.equal(r1.status, 200);
    assert.notEqual(r1.json.refreshToken, refresh);
    const reuse = await api('POST', '/api/auth/refresh', { body: { refreshToken: refresh } });
    assert.equal(reuse.status, 401);
    const afterTheft = await api('POST', '/api/auth/refresh', { body: { refreshToken: r1.json.refreshToken } });
    assert.equal(afterTheft.status, 401);
  });

  it('logout revokes refresh token', async () => {
    const l = await api('POST', '/api/auth/login', { body: { email, password: pw } });
    assert.equal((await api('POST', '/api/auth/logout', { body: { refreshToken: l.json.refreshToken } })).status, 204);
    assert.equal((await api('POST', '/api/auth/refresh', { body: { refreshToken: l.json.refreshToken } })).status, 401);
  });

  it('forgot + reset password with an email code', async () => {
    const unknown = await api('POST', '/api/auth/forgot-password', { body: { email: 'ghost@mail.dev' } });
    assert.equal(unknown.status, 200);
    assert.equal(unknown.json.devCode, undefined); // same answer, no account guessing
    const f = await api('POST', '/api/auth/forgot-password', { body: { email } });
    assert.equal(f.status, 200);
    assert.match(f.json.devCode, /^\d{6}$/);
    const reset = (code, newPassword) => api('POST', '/api/auth/reset-password', { body: { email, code, newPassword } });
    const wrong = f.json.devCode === '000000' ? '111111' : '000000';
    assert.equal((await reset(wrong, 'NewPassw0rd!')).status, 400);
    assert.equal((await reset(f.json.devCode, 'short')).status, 400); // weak password
    assert.equal((await reset(f.json.devCode, 'NewPassw0rd!')).status, 204);
    assert.equal((await reset(f.json.devCode, 'AnotherPassw0rd!')).status, 400); // single use
    assert.equal((await api('POST', '/api/auth/login', { body: { email, password: pw } })).status, 401);
    assert.equal((await api('POST', '/api/auth/login', { body: { email, password: 'NewPassw0rd!' } })).status, 200);
  });

  it('change password needs the current one; delete account is soft', async () => {
    const l = await api('POST', '/api/auth/login', { body: { email, password: 'NewPassw0rd!' } });
    const t = l.json.accessToken;
    assert.equal((await api('POST', '/api/users/me/password', { token: t, body: { currentPassword: 'bad', newPassword: 'Another1234!' } })).status, 401);
    assert.equal((await api('POST', '/api/users/me/password', { token: t, body: { currentPassword: 'NewPassw0rd!', newPassword: 'Another1234!' } })).status, 204);
    assert.equal((await api('DELETE', '/api/users/me', { token: t, body: { password: 'Another1234!' } })).status, 204);
    assert.equal((await api('POST', '/api/auth/login', { body: { email, password: 'Another1234!' } })).status, 401);
    const row = await pool.query('SELECT deleted_at FROM users WHERE id = $1', [userId]);
    assert.ok(row.rows[0].deleted_at);
  });
});

describe('email OTP safety', () => {
  const mail = `test+otp${Date.now()}@mail.dev`;
  let code;

  it('5 wrong tries lock the code, even the right one', async () => {
    const r = await api('POST', '/api/auth/register', { body: { name: 'Otp User', email: mail, password: pw } });
    code = r.json.devCode;
    const wrong = code === '000000' ? '111111' : '000000';
    for (let i = 0; i < 5; i++) {
      assert.equal((await api('POST', '/api/auth/verify-email', { body: { email: mail, code: wrong } })).status, 400);
    }
    const locked = await api('POST', '/api/auth/verify-email', { body: { email: mail, code } });
    assert.equal(locked.status, 400);
    assert.equal(locked.json.error.code, 'too_many_attempts');
  });

  it('resend inside the cooldown sends nothing; after it, a new code replaces the old', async () => {
    const quick = await api('POST', '/api/auth/resend-code', { body: { email: mail, purpose: 'verify' } });
    assert.equal(quick.status, 200);
    assert.equal(quick.json.devCode, undefined);
    await pool.query("UPDATE email_otps SET created_at = created_at - interval '2 minutes' WHERE email = $1", [mail]);
    const again = await api('POST', '/api/auth/resend-code', { body: { email: mail, purpose: 'verify' } });
    assert.match(again.json.devCode, /^\d{6}$/);
    const old = await api('POST', '/api/auth/verify-email', { body: { email: mail, code } });
    assert.equal(old.status, 400); // the first code is no longer valid
    await pool.query("UPDATE email_otps SET expires_at = now() - interval '1 minute' WHERE email = $1", [mail]);
    const expired = await api('POST', '/api/auth/verify-email', { body: { email: mail, code: again.json.devCode } });
    assert.equal(expired.status, 400);
    assert.equal(expired.json.error.message, 'Invalid or expired code');
  });

  it('starting the sign-up again replaces the unverified account', async () => {
    await pool.query("UPDATE email_otps SET created_at = created_at - interval '2 minutes' WHERE email = $1", [mail]);
    const r = await api('POST', '/api/auth/register', { body: { name: 'Otp User 2', email: mail, password: 'SecondPassw0rd!' } });
    assert.equal(r.status, 201);
    const v = await api('POST', '/api/auth/verify-email', { body: { email: mail, code: r.json.devCode } });
    assert.equal(v.status, 200);
    assert.equal(v.json.user.name, 'Otp User 2');
    assert.equal((await api('POST', '/api/auth/login', { body: { email: mail, password: pw } })).status, 401);
    assert.equal((await api('POST', '/api/auth/login', { body: { email: mail, password: 'SecondPassw0rd!' } })).status, 200);
  });

  it('only an unverified email can ask for a verify code', async () => {
    const r = await api('POST', '/api/auth/resend-code', { body: { email: mail, purpose: 'verify' } });
    assert.equal(r.status, 200);
    assert.equal(r.json.devCode, undefined);
  });
});