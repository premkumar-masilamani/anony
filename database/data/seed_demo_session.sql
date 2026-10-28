-- Pre-scheduled live demo session starting at the exact demo recording time (Issue #5).
-- Idempotent: clears any overlapping unbooked slot on the coach template before upserting
-- the live demo slot (80000000-0000-4000-8000-000000000099) and confirmed session
-- (90000000-0000-4000-8000-000000000099) between Coach Maya Raman and Client Arjun Mehta ('Courageous Owl').

BEGIN;

DELETE FROM sessions
WHERE session_id = '90000000-0000-4000-8000-000000000099'::UUID;

DELETE FROM slots
WHERE slot_id = '80000000-0000-4000-8000-000000000099'::UUID;

-- Remove any unbooked rolling slot on Coach Maya's template that overlaps the current 60-minute recording window
DELETE FROM slots
WHERE availability_template_id = '60000000-0000-4000-8000-000000000001'::UUID
  AND tstzrange(start_at, end_at) && tstzrange(
      date_trunc('minute', now()),
      date_trunc('minute', now()) + INTERVAL '60 minutes'
  )
  AND NOT EXISTS (
      SELECT 1 FROM sessions WHERE sessions.slot_id = slots.slot_id
  );

INSERT INTO slots (slot_id, availability_template_id, start_at, end_at)
VALUES (
    '80000000-0000-4000-8000-000000000099'::UUID,
    '60000000-0000-4000-8000-000000000001'::UUID,
    date_trunc('minute', now()),
    date_trunc('minute', now()) + INTERVAL '60 minutes'
)
ON CONFLICT (slot_id) DO UPDATE
SET start_at = EXCLUDED.start_at,
    end_at = EXCLUDED.end_at;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'slots' AND column_name = 'is_free_pledge'
    ) THEN
        EXECUTE 'UPDATE slots SET is_free_pledge = TRUE WHERE slot_id = ''80000000-0000-4000-8000-000000000099''::UUID';
    END IF;
END $$;

INSERT INTO sessions (session_id, slot_id, client_id, domain_id, topic, status)
SELECT
    '90000000-0000-4000-8000-000000000099'::UUID,
    '80000000-0000-4000-8000-000000000099'::UUID,
    '30000000-0000-4000-8000-000000000001'::UUID,
    domains.domain_id,
    'Navigating engineering leadership burnout and setting sustainable boundaries.',
    'CONFIRMED'
FROM domains
WHERE domains.code = 'BURNOUT'
ON CONFLICT (session_id) DO UPDATE
SET slot_id = EXCLUDED.slot_id,
    topic = EXCLUDED.topic,
    status = EXCLUDED.status,
    updated_at = now();

COMMIT;
