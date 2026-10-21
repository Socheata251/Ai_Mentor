-- Email OTP (6-digit codes) for sign-up verification and password reset.

-- New column. Accounts that already exist are treated as verified (only runs once).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email_verified_at') THEN
    ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMPTZ;
    UPDATE users SET email_verified_at = created_at;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS email_otps (
  id         BIGSERIAL PRIMARY KEY,
  email      TEXT NOT NULL,
  purpose    TEXT NOT NULL CHECK (purpose IN ('verify','reset')),
  code_hash  TEXT NOT NULL,                    -- the code itself is never stored
  attempts   SMALLINT NOT NULL DEFAULT 0,      -- wrong tries
  expires_at TIMESTAMPTZ NOT NULL,
  used_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS email_otps_lookup_idx ON email_otps (email, purpose, created_at DESC);
