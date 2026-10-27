-- 003_add_slot_free_pledge.down.sql
-- Exact reversal of 003_add_slot_free_pledge.up.sql (Issue #3).
-- Authored only: migrations are applied manually by the project owner.

DROP INDEX IF EXISTS slots_template_free_pledge_start_at_idx;

ALTER TABLE slots
    DROP COLUMN IF EXISTS is_free_pledge;
