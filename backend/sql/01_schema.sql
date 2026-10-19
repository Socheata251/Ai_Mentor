-- Astra Learn (Ai_Mentor) database schema - PostgreSQL 14+
-- Relationships: 1:1 users-user_settings | 1:N users-conversations-messages
--                N:M users-courses (user_course_progress)

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS roles (
  id    SMALLSERIAL PRIMARY KEY,
  name  TEXT NOT NULL UNIQUE CHECK (name IN ('student','instructor','admin'))
);
INSERT INTO roles (name) VALUES ('student'),('instructor'),('admin') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT NOT NULL CHECK (length(trim(name)) > 0),
  email          TEXT NOT NULL,
  password_hash  TEXT NOT NULL,
  university     TEXT NOT NULL DEFAULT 'ACLEDA University',
  semester       SMALLINT NOT NULL DEFAULT 4 CHECK (semester BETWEEN 1 AND 12),
  role_id        SMALLINT NOT NULL REFERENCES roles(id) DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ                      -- soft delete
);
CREATE UNIQUE INDEX IF NOT EXISTS users_email_active_uq ON users (lower(email)) WHERE deleted_at IS NULL;
DROP TRIGGER IF EXISTS users_updated ON users;
CREATE TRIGGER users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_settings (
  user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  language     TEXT NOT NULL DEFAULT 'Khmer' CHECK (language IN ('English','Khmer')),
  hints_first  BOOLEAN NOT NULL DEFAULT true,
  ai_model     TEXT NOT NULL DEFAULT 'IT Mentor v2',
  code_format  TEXT NOT NULL DEFAULT 'Auto' CHECK (code_format IN ('Auto','2 spaces','4 spaces','Tabs')),
  dark_mode    TEXT NOT NULL DEFAULT 'system' CHECK (dark_mode IN ('system','light','dark')),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS user_settings_updated ON user_settings;
CREATE TRIGGER user_settings_updated BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  device      TEXT,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS refresh_tokens_user_idx ON refresh_tokens (user_id);

CREATE TABLE IF NOT EXISTS password_resets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  used_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS courses (
  code      TEXT PRIMARY KEY,
  title     TEXT NOT NULL,
  topics    TEXT NOT NULL,
  semester  SMALLINT NOT NULL CHECK (semester BETWEEN 1 AND 12),
  credits   SMALLINT NOT NULL DEFAULT 3,
  category  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_course_progress (
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_code  TEXT NOT NULL REFERENCES courses(code) ON DELETE CASCADE,
  progress     NUMERIC(4,3) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, course_code)
);

CREATE TABLE IF NOT EXISTS quiz_topics (
  id        TEXT PRIMARY KEY,
  title     TEXT NOT NULL,
  subtitle  TEXT NOT NULL,
  category  TEXT NOT NULL,
  level     TEXT NOT NULL,
  file_name TEXT NOT NULL,
  lang_badge TEXT NOT NULL,
  position  INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS quiz_questions (
  id               SERIAL PRIMARY KEY,
  topic_id         TEXT NOT NULL REFERENCES quiz_topics(id) ON DELETE CASCADE,
  position         INT NOT NULL,
  tag              TEXT NOT NULL,
  prompt           TEXT NOT NULL,
  code             TEXT,
  options          JSONB NOT NULL,
  correct_index    SMALLINT NOT NULL CHECK (correct_index >= 0),
  hint             TEXT NOT NULL,
  explanation      TEXT NOT NULL,
  options_are_code BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (topic_id, position)
);

CREATE TABLE IF NOT EXISTS quiz_attempts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic_id    TEXT NOT NULL REFERENCES quiz_topics(id),
  score       SMALLINT NOT NULL CHECK (score >= 0),
  total       SMALLINT NOT NULL CHECK (total > 0),
  xp          INT NOT NULL CHECK (xp >= 0),
  answers     JSONB NOT NULL,
  client_ref  TEXT,                                  -- idempotency key from the app
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (score <= total)
);
CREATE INDEX IF NOT EXISTS quiz_attempts_user_idx ON quiz_attempts (user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS quiz_attempts_client_ref_uq ON quiz_attempts (user_id, client_ref) WHERE client_ref IS NOT NULL;

CREATE TABLE IF NOT EXISTS conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT 'New chat',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS conversations_user_idx ON conversations (user_id, updated_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role             TEXT NOT NULL CHECK (role IN ('user','ai')),
  blocks           JSONB NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS messages_conv_idx ON messages (conversation_id, created_at);

CREATE TABLE IF NOT EXISTS schedule_sessions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  subtitle    TEXT NOT NULL DEFAULT '',
  time_label  TEXT NOT NULL,
  tag         TEXT NOT NULL DEFAULT '',
  enabled     BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS schedule_user_idx ON schedule_sessions (user_id);
DROP TRIGGER IF EXISTS schedule_updated ON schedule_sessions;
CREATE TRIGGER schedule_updated BEFORE UPDATE ON schedule_sessions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS notifications_user_idx ON notifications (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS audit_logs (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  action      TEXT NOT NULL,
  entity      TEXT,
  entity_id   TEXT,
  ip          TEXT,
  meta        JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_logs_created_idx ON audit_logs (created_at DESC);
