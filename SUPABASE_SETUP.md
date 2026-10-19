# Supabase Setup Guide (for teammates)

This project = **Flutter app** → **Node.js backend** → **Supabase (PostgreSQL)**.
The Flutter app never talks to the database directly. Only the backend does, using a secret connection string stored in `backend/.env` (never committed to Git).

Commands below are for **Windows PowerShell**.

---

## 0. Install the tools (once)

```
winget install OpenJS.NodeJS.LTS
```

Close and reopen VS Code, then check:

```
node -v          # must be v20 or higher
flutter --version
```

If `npm` shows "running scripts is disabled", run this once:

```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## 1. Get the code

```
git clone https://github.com/Socheata251/Ai_Mentor.git
cd Ai_Mentor
```

If you already have it, run `git pull`.

---

## 2. Choose how you connect to the database

### Option A: Use the team's shared database (same data as everyone)

Ask the project owner for ONE of these:

1. **An invite to the Supabase organization** (best). Accept the email invite, open the project, then click **Connect** → **Direct** tab → Type **URI** → Method **Session pooler**, and copy the string.
2. **The `DATABASE_URL` and `JWT_SECRET`** sent privately (direct message or password manager).

> Do NOT run `npm run db:init` in this option. The tables already exist.
> The `JWT_SECRET` must be the same value the owner uses.

### Option B: Use your own separate database (recommended for safe testing)

1. Go to supabase.com and sign in.
2. Click **New organization** (Personal, Free plan), then **New project**.
3. Name it `ai-mentor`, set a database password (letters and numbers only), choose the closest region, and create it. Wait 1 to 2 minutes.
4. Click **Connect** → **Direct** tab → Type **URI** → Method **Session pooler**, and copy the string.
5. You WILL run `npm run db:init` in step 4 to create the tables.

---

## 3. Create your `backend/.env` file

```
cd backend
copy .env.example .env
notepad .env
```

Edit these lines, then save:

```
DATABASE_URL=postgresql://postgres.YOURREF:YOURPASSWORD@aws-0-REGION.pooler.supabase.com:5432/postgres
JWT_SECRET=a-long-random-string
```

- Replace `[YOUR-PASSWORD]` with the real password and remove the square brackets.
- If the password contains `@ # / :` the connection fails. Use letters and numbers only, or reset the password in **Project Settings → Database**.
- Add `?sslmode=require` to the end of `DATABASE_URL` if you get an SSL error.
- Generate a secret with:
```
  node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```
- Leave `AI_API_KEY` empty. The tutor then gives mock replies. To use the real AI, ask the owner for a key and also set `AI_MODEL`.

**Never commit `.env`, never paste the connection string in chat or screenshots, and never put it in Flutter code.** `.env` is already in `backend/.gitignore`.

---

## 4. Install and create the tables

```
npm install
npm run db:init
```

(Skip `npm run db:init` if you chose Option A.)

Expected output:

```
ran 01_schema.sql
ran 02_seed_courses.sql
ran 03_seed_quiz.sql
```

Check in Supabase: **Table Editor** should show `users`, `courses`, `conversations`, `messages`, `quiz_topics` and more.

---

## 5. Start the backend

```
npm run dev
```

Open http://localhost:3000/api/health in your browser. You should see:

```
{"status":"ok","ai":"mock"}
```

`ai: mock` is normal when no AI key is set. Keep this terminal running.

---

## 6. Run the Flutter app

Open a second terminal (the **+** button in VS Code):

```
cd D:\Ai_Mentor        # your project root
flutter pub get
flutter run -d chrome
```

The app on the web uses `http://localhost:3000` automatically, so the backend must be running on your own computer.

---

## 7. Test it works

1. Register a new account in the app.
2. In Supabase **Table Editor** → `users`, your account appears.
3. Send a message in the tutor chat, then check `conversations` and `messages`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `DATABASE_URL is missing` / `JWT_SECRET is missing` | `.env` is not inside `backend/`, or the lines are empty |
| `password authentication failed` | Wrong password. Reset it in **Project Settings → Database** |
| `ENOTFOUND` / `ETIMEDOUT` | Use the **Session pooler** string, not the plain Direct connection (IPv6 only) |
| SSL error | Add `?sslmode=require` to the end of `DATABASE_URL` |
| `/api/health` works but register fails | Tables are missing. Run `npm run db:init` (Option B) |
| App shows a network error | Backend is not running. Check http://localhost:3000/api/health |
| `npm` blocked in PowerShell | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Chrome not listed | `flutter config --enable-web`, then `flutter devices` |