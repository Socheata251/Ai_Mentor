# Astra Learn backend

Node.js 20+ · Express · PostgreSQL · JWT + refresh tokens · Docker.

## Run with Docker (needs Docker Desktop)

```
cd backend
copy .env.example .env        (Windows cmd)   |   cp .env.example .env
:: edit .env: set JWT_SECRET to a long random string. Leave AI_API_KEY empty.
docker compose up --build
```
API: http://localhost:8080/api/health

## Run without Docker

1. Install PostgreSQL and create a database: `createdb mentor` (user mentor / password mentor, or change DATABASE_URL).
2. `copy .env.example .env` and edit it.
3. `npm install`, then `npm run db:init` (creates tables, sample courses and quizzes; set ADMIN_EMAIL and ADMIN_PASSWORD first if you want an admin).
4. `npm run dev`  ->  http://localhost:3000/api/health
5. `npm test`

## AI key

`AI_API_KEY` is empty on purpose. The tutor answers with mock replies until you fill `AI_API_KEY` and `AI_MODEL`.
Never put this key in the Flutter app.

API list: `docs/API.md`.

## Connect the Flutter app

```
flutter pub get
flutter run                                              (Android emulator uses 10.0.2.2:3000, Windows/web use localhost:3000)
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000    (real phone, same Wi-Fi)
flutter run --dart-define=USE_BACKEND=false                      (old offline mock mode)
```
