-- 002_add_anonymous_mode_quota.up.sql
-- Add anonymous mode toggle and pro-bono free session quota tracking to clients table (Issue #42).
-- Authored only: migrations are applied manually by the project owner.

ALTER TABLE clients
    ADD COLUMN IF NOT EXISTS is_anonymous_mode BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS free_sessions_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_free_session_at TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'clients_free_sessions_count_check'
    ) THEN
        ALTER TABLE clients
            ADD CONSTRAINT clients_free_sessions_count_check
            CHECK (free_sessions_count >= 0 AND free_sessions_count <= 6);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_clients_quota ON clients (last_free_session_at, free_sessions_count);
