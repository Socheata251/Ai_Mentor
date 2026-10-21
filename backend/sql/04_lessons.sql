-- Lessons (W3Schools style). Content is written by teachers/students, not by AI.

CREATE TABLE IF NOT EXISTS lessons (
  id           SERIAL PRIMARY KEY,
  course_code  TEXT NOT NULL REFERENCES courses(code) ON DELETE CASCADE,
  position     INT NOT NULL CHECK (position > 0),
  slug         TEXT NOT NULL,
  title        TEXT NOT NULL,
  summary      TEXT NOT NULL DEFAULT '',
  content      JSONB NOT NULL,      -- list of blocks: heading | text | code | output | tip
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (course_code, slug),
  UNIQUE (course_code, position) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX IF NOT EXISTS lessons_course_idx ON lessons (course_code, position);
DROP TRIGGER IF EXISTS lessons_updated ON lessons;
CREATE TRIGGER lessons_updated BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_lesson_progress (
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id     INT  NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  completed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, lesson_id)
);