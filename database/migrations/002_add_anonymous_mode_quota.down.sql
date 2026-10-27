-- 002_add_anonymous_mode_quota.down.sql
-- Exact reversal of 002_add_anonymous_mode_quota.up.sql (Issue #42).
-- Authored only: migrations are applied manually by the project owner.

DROP INDEX IF EXISTS idx_clients_quota;

ALTER TABLE clients
    DROP CONSTRAINT IF EXISTS clients_free_sessions_count_check;

ALTER TABLE clients
    DROP COLUMN IF EXISTS is_anonymous_mode,
    DROP COLUMN IF EXISTS free_sessions_count,
    DROP COLUMN IF EXISTS last_free_session_at;
