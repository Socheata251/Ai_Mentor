-- Supabase Auth: the accounts and passwords live in Supabase (auth.users).
-- Our "users" table stays as the student profile, and users.id = the Supabase user id.
-- Safe to run more than once.

ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Old local accounts (made before this switch) cannot sign in through Supabase,
-- and their email would block a new sign-up with the same address.
-- For test accounts, remove them once (this also removes their chats, progress, etc.):
--   DELETE FROM users WHERE password_hash IS NOT NULL;
-- To make someone an admin or instructor after they sign up (role ids: 1 student, 2 instructor, 3 admin):
--   UPDATE users SET role_id = 3 WHERE lower(email) = 'you@example.com';