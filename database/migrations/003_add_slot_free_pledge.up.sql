-- 003_add_slot_free_pledge.up.sql
-- Add mandatory monthly free session pledge indicator to slots table (Issue #3).
-- Authored only: migrations are applied manually by the project owner.

ALTER TABLE slots
    ADD COLUMN IF NOT EXISTS is_free_pledge BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS slots_template_free_pledge_start_at_idx
    ON slots (availability_template_id, is_free_pledge, start_at);
