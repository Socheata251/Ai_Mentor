# Astra Learn API

Base URL: `http://localhost:3000` (direct) or `http://localhost:8080` (Docker + nginx).
All bodies are JSON. Protected routes need `Authorization: Bearer <accessToken>`.
Errors always look like `{ "error": { "code": "...", "message": "...", "details": [...] } }`.

Common errors: 400 validation_error / bad_json, 401 unauthorized, 403 forbidden,
404 not_found, 409 conflict, 429 too many requests, 500 internal_error, 502/503 AI problems.

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| GET | /api/health | no | – | 200 `{status, ai}` | 500 |
| POST | /api/auth/register | no | `{name, email, password(8+), university?, semester?}` | 201 `{user, accessToken, refreshToken}` | 400, 409 |
| POST | /api/auth/login | no | `{email, password}` | 200 same as register | 400, 401 |
| POST | /api/auth/refresh | no | `{refreshToken}` | 200 new pair (old token is revoked) | 401 |
| POST | /api/auth/logout | no | `{refreshToken}` | 204 | 400 |
| POST | /api/auth/forgot-password | no | `{email}` | 200 `{message}` (`devToken` only outside production) | 400 |
| POST | /api/auth/reset-password | no | `{token, newPassword}` | 204 | 400 |
| GET | /api/users/me | yes | – | 200 `{user}` | 401, 404 |
| PATCH | /api/users/me | yes | `{name?, university?, semester?}` | 200 `{user}` | 400, 401 |
| POST | /api/users/me/password | yes | `{currentPassword, newPassword}` | 204 | 400, 401 |
| DELETE | /api/users/me | yes | `{password}` | 204 (soft delete) | 401 |
| GET / PUT | /api/settings | yes | `{language?, hintsFirst?, aiModel?, codeFormat?, darkMode?}` | 200 `{settings}` | 400, 401 |
| GET | /api/courses?semester=&q= | yes | – | 200 `{courses:[{code,title,topics,semester,credits,category,progress}]}` | 401 |
| GET | /api/courses/{code} | yes | – | 200 `{course}` | 404 |
| PUT | /api/courses/{code}/progress | yes | `{progress: 0..1}` | 200 | 400, 404 |
| GET | /api/quiz/topics | yes | – | 200 `{topics}` | 401 |
| GET | /api/quiz/topics/{id} | yes | – | 200 `{topic:{..., questions}}` | 404 |
| POST | /api/quiz/attempts | yes | `{topicId, answers:[int\|null], clientRef?}` | 201 `{attempt}` (200 + `duplicate:true` if `clientRef` was used before) | 400, 404 |
| GET | /api/quiz/attempts?limit= | yes | – | 200 `{attempts}` | 401 |
| GET | /api/progress/summary | yes | – | 200 `{quizzesTaken,totalXp,bestPercent,averagePercent,streakDays,courseProgressPercent,topics}` | 401 |
| GET | /api/chats | yes | – | 200 `{chats}` | 401 |
| POST | /api/chats | yes | `{title?}` | 201 `{chat}` | 400 |
| GET | /api/chats/{id} | yes | – | 200 `{chat, messages}` | 404 |
| DELETE | /api/chats/{id} | yes | – | 204 | 404 |
| POST | /api/chats/{id}/messages | yes | `{text, language?}` | 201 `{userMessage, reply, mock}` | 400, 404, 502, 503 |
| POST | /api/ai/chat | yes | `{messages:[{role:'user'\|'ai', text}], language?, hintsFirst?}` | 200 `{blocks, mock}` | 400, 502, 503 |
| GET / POST | /api/schedule | yes | `{title, subtitle?, time, tag?}` | 200 / 201 | 400 |
| PATCH / DELETE | /api/schedule/{id} | yes | `{title?, subtitle?, time?, tag?, enabled?}` | 200 / 204 | 400, 404 |
| GET | /api/notifications | yes | – | 200 `{notifications, unread}` | 401 |
| PATCH | /api/notifications/{id}/read | yes | – | 200 | 404 |
| POST | /api/notifications/read-all | yes | – | 204 | 401 |
| GET | /api/admin/users | admin | – | 200 `{users}` | 401, 403 |
| PATCH | /api/admin/users/{id}/role | admin | `{role: student\|instructor\|admin}` | 200 | 400, 403, 404 |
| GET | /api/admin/audit-logs | admin | – | 200 `{logs}` | 401, 403 |

## Message blocks (chat + AI)

```json
{ "type": "text", "text": "..." }
{ "type": "code", "code": "print(1)", "language": "py" }
{ "type": "tip", "text": "..." }
{ "type": "quick_check", "question": "...", "options": [{"label": "A"}], "correctIndex": 0, "explanation": "..." }
```
These match `TextBlock`, `CodeSnippetBlock`, `TipBlock`, `QuickCheckBlock` in `lib/data/models/message.dart`.
The server currently produces text, code and tip blocks. `quick_check` is accepted by the app but not produced yet.

## AI

While `AI_API_KEY` is empty the server returns built-in mock replies (`"mock": true`).
Fill `AI_API_KEY` and `AI_MODEL` in `.env` to use the real provider (`AI_PROVIDER=anthropic`).
The key lives only on the server; the Flutter app never sees it.

## ER summary

users 1—1 user_settings · users 1—N refresh_tokens / conversations / quiz_attempts / schedule_sessions / notifications
conversations 1—N messages · users N—M courses (user_course_progress) · quiz_topics 1—N quiz_questions
roles 1—N users · audit_logs → users (nullable)
