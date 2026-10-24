-- Supabase publishes every table in the "public" schema through its Data API
-- (anyone with the public anon key could read them). This app only talks to the
-- database through the Node backend (the owner role, which ignores RLS), so we
-- switch Row Level Security ON for every table and add NO policies:
-- the public API sees nothing, the backend keeps working. Safe to run again.
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.tablename);
  END LOOP;
END $$;