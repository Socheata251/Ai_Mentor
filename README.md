# iLearnCode

iLearnCode is a mobile app for students who start from zero. No experience needed. It guides you step by step, from your first line of code to more advanced topics. The AI tutor does not just give the answer. It gives hints, short explanations, and quick checks, so you really understand.

## Features

- AI tutor chat with hints and quick checks
- Lessons and course library
- Quizzes with history
- Study schedule and progress tracking
- Sign up and sign in with email code (OTP)
- Settings and profile

## Tech Stack

- App: Flutter (Dart)
- Backend: Node.js and Express
- Database: PostgreSQL on Supabase
- Login: Supabase Auth and JWT
- AI: Ollama (can also use Anthropic)

## Project Structure

```
lib/        Flutter app (features, data, core)
backend/    Node.js API and SQL files
assets/     Images and files for the app
test/       App tests
```

## How to Run

### 1. Backend

```
cd backend
copy .env.example .env
npm install
npm run db:init
npm start
```

Open `backend/.env` and put your own values (database, JWT secret, AI key, email). Never share this file and never commit it.

To use a local database with Docker instead:

```
docker compose up
```

### 2. Flutter app

```
flutter pub get
flutter run
```

On the Android emulator, the app reaches your computer at `http://10.0.2.2:3000`.

## Security Notes

- Keep all keys and passwords in `backend/.env` only.
- `.env` is in `.gitignore`. Do not remove it.
- Use real keys only on your own computer or server.

## Team

CADT Capstone project.

## License

For learning use.