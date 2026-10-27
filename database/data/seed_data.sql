-- Seed data initialization for anony_db
-- Schema definitions are tracked in database/migrations/
--
-- Idempotent: fixed UUIDs + ON CONFLICT DO NOTHING, safe to re-run.
-- All demo accounts share the password: AnonyDemo#2026 (bcrypt, cost 10).
-- Demo slot times are relative to the import time so they stay in the future.

BEGIN;

-- ============================================================
-- domains: coaching domains (reference data)
-- ============================================================
INSERT INTO domains (domain_id, code, name) VALUES
    ('40000000-0000-4000-8000-000000000001', 'CAREER',            'Career Development'),
    ('40000000-0000-4000-8000-000000000002', 'LEADERSHIP',        'Leadership & Executive'),
    ('40000000-0000-4000-8000-000000000003', 'BUSINESS',          'Entrepreneurship & Business'),
    ('40000000-0000-4000-8000-000000000004', 'BURNOUT',           'Burnout & Stress'),
    ('40000000-0000-4000-8000-000000000005', 'WORK_LIFE_BALANCE', 'Work-Life Balance'),
    ('40000000-0000-4000-8000-000000000006', 'PRODUCTIVITY',      'Productivity & Time Management'),
    ('40000000-0000-4000-8000-000000000007', 'CONFIDENCE',        'Confidence & Self-Esteem'),
    ('40000000-0000-4000-8000-000000000008', 'MINDSET',           'Mindset & Personal Growth'),
    ('40000000-0000-4000-8000-000000000009', 'PURPOSE',           'Purpose & Values'),
    ('40000000-0000-4000-8000-000000000010', 'LIFE_TRANSITIONS',  'Life Transitions'),
    ('40000000-0000-4000-8000-000000000011', 'RELATIONSHIPS',     'Relationships'),
    ('40000000-0000-4000-8000-000000000012', 'PARENTING',         'Parenting & Family'),
    ('40000000-0000-4000-8000-000000000013', 'COMMUNICATION',     'Communication Skills'),
    ('40000000-0000-4000-8000-000000000014', 'CREATIVITY',        'Creativity'),
    ('40000000-0000-4000-8000-000000000015', 'ACADEMIC',          'Academic & Student'),
    ('40000000-0000-4000-8000-000000000016', 'RETIREMENT',        'Retirement')
ON CONFLICT DO NOTHING;

-- ============================================================
-- users: 4 coaches + 2 clients
-- ============================================================
INSERT INTO users (user_id, email, password_hash, role) VALUES
    ('10000000-0000-4000-8000-000000000001', 'maya.raman@example.com',      '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'COACH'),
    ('10000000-0000-4000-8000-000000000002', 'daniel.okafor@example.com',   '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'COACH'),
    ('10000000-0000-4000-8000-000000000003', 'sofia.lindqvist@example.com', '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'COACH'),
    ('10000000-0000-4000-8000-000000000004', 'james.carter@example.com',    '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'COACH'),
    ('10000000-0000-4000-8000-000000000101', 'arjun.mehta@example.com',     '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'CLIENT'),
    ('10000000-0000-4000-8000-000000000102', 'priya.nair@example.com',      '$2a$10$nTywmVAG7ehrVZN.TOWMAu3V47lL1K1ThMn35T93TwVUa6PdxqAvi', 'CLIENT')
ON CONFLICT DO NOTHING;

-- ============================================================
-- coaches: 3 verified + 1 pending verification
-- ============================================================
INSERT INTO coaches (
    coach_id, user_id, first_name, last_name, photo_url, gender, country_code, timezone, biography,
    icf_acc, icf_pcc, icf_mcc, icf_actc, credential_details, is_verified, is_onboarded
) VALUES
    ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
     'Maya', 'Raman', NULL, 'FEMALE', 'IN', 'Asia/Kolkata',
     'Former engineering manager helping professionals navigate career growth and burnout.',
     FALSE, TRUE, FALSE, FALSE, 'ICF PCC, demo credential', TRUE, TRUE),
    ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002',
     'Daniel', 'Okafor', NULL, 'MALE', 'GB', 'Europe/London',
     'Executive and team coach focused on leadership communication and purpose.',
     FALSE, FALSE, TRUE, TRUE, 'ICF MCC and ACTC, demo credential', TRUE, TRUE),
    ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003',
     'Sofia', 'Lindqvist', NULL, 'FEMALE', 'SE', 'Europe/Stockholm',
     'Supports people through life transitions with a focus on confidence and balance.',
     TRUE, FALSE, FALSE, FALSE, 'ICF ACC, demo credential', TRUE, TRUE),
    ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004',
     'James', 'Carter', NULL, 'PREFER_NOT_TO_SAY', 'US', 'America/New_York',
     NULL,
     TRUE, FALSE, FALSE, FALSE, 'ICF ACC, awaiting manual verification', FALSE, FALSE)
ON CONFLICT DO NOTHING;

-- ============================================================
-- clients: 1 anonymous + 1 named
-- ============================================================
INSERT INTO clients (client_id, user_id, first_name, last_name, is_anonymous, alias, is_onboarded) VALUES
    ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000101',
     'Arjun', 'Mehta', TRUE, 'Courageous Owl', TRUE),
    ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000102',
     'Priya', 'Nair', FALSE, 'Steady Heron', TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================
-- coach_domains (domains resolved by code)
-- ============================================================
INSERT INTO coach_domains (coach_domain_id, coach_id, domain_id)
SELECT seed.coach_domain_id::UUID, seed.coach_id::UUID, domains.domain_id
FROM (VALUES
    ('50000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'CAREER'),
    ('50000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'LEADERSHIP'),
    ('50000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', 'BURNOUT'),
    ('50000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000002', 'LEADERSHIP'),
    ('50000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', 'COMMUNICATION'),
    ('50000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000002', 'PURPOSE'),
    ('50000000-0000-4000-8000-000000000007', '20000000-0000-4000-8000-000000000003', 'CONFIDENCE'),
    ('50000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000003', 'MINDSET'),
    ('50000000-0000-4000-8000-000000000009', '20000000-0000-4000-8000-000000000003', 'LIFE_TRANSITIONS'),
    ('50000000-0000-4000-8000-000000000010', '20000000-0000-4000-8000-000000000003', 'WORK_LIFE_BALANCE'),
    ('50000000-0000-4000-8000-000000000011', '20000000-0000-4000-8000-000000000004', 'PARENTING')
) AS seed (coach_domain_id, coach_id, domain_code)
JOIN domains ON domains.code = seed.domain_code
ON CONFLICT DO NOTHING;

-- ============================================================
-- availability_templates: one per onboarded coach
-- ============================================================
INSERT INTO availability_templates (availability_template_id, coach_id, slot_duration_minutes, is_active) VALUES
    ('60000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 60, TRUE),
    ('60000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 60, TRUE),
    ('60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', 30, TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================
-- availability_windows (wall-clock times in each coach's timezone; 1 = Monday)
-- ============================================================
INSERT INTO availability_windows (availability_window_id, availability_template_id, day_of_week, start_time, end_time) VALUES
    -- Maya: weekdays 09:00-12:00 and 14:00-17:00
    ('70000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 1, '09:00', '12:00'),
    ('70000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000001', 1, '14:00', '17:00'),
    ('70000000-0000-4000-8000-000000000003', '60000000-0000-4000-8000-000000000001', 2, '09:00', '12:00'),
    ('70000000-0000-4000-8000-000000000004', '60000000-0000-4000-8000-000000000001', 2, '14:00', '17:00'),
    ('70000000-0000-4000-8000-000000000005', '60000000-0000-4000-8000-000000000001', 3, '09:00', '12:00'),
    ('70000000-0000-4000-8000-000000000006', '60000000-0000-4000-8000-000000000001', 3, '14:00', '17:00'),
    ('70000000-0000-4000-8000-000000000007', '60000000-0000-4000-8000-000000000001', 4, '09:00', '12:00'),
    ('70000000-0000-4000-8000-000000000008', '60000000-0000-4000-8000-000000000001', 4, '14:00', '17:00'),
    ('70000000-0000-4000-8000-000000000009', '60000000-0000-4000-8000-000000000001', 5, '09:00', '12:00'),
    ('70000000-0000-4000-8000-000000000010', '60000000-0000-4000-8000-000000000001', 5, '14:00', '17:00'),
    -- Daniel: Tuesday and Thursday 10:00-13:00
    ('70000000-0000-4000-8000-000000000011', '60000000-0000-4000-8000-000000000002', 2, '10:00', '13:00'),
    ('70000000-0000-4000-8000-000000000012', '60000000-0000-4000-8000-000000000002', 4, '10:00', '13:00'),
    -- Sofia: Monday and Wednesday evenings, Saturday mornings
    ('70000000-0000-4000-8000-000000000013', '60000000-0000-4000-8000-000000000003', 1, '18:00', '20:00'),
    ('70000000-0000-4000-8000-000000000014', '60000000-0000-4000-8000-000000000003', 3, '18:00', '20:00'),
    ('70000000-0000-4000-8000-000000000015', '60000000-0000-4000-8000-000000000003', 6, '09:00', '11:00')
ON CONFLICT DO NOTHING;

-- ============================================================
-- slots: demo slots, expressed in each coach's local time
-- ============================================================
INSERT INTO slots (slot_id, availability_template_id, start_at, end_at)
SELECT seed.slot_id::UUID,
       seed.availability_template_id::UUID,
       (date_trunc('day', now() AT TIME ZONE seed.timezone) + seed.local_start) AT TIME ZONE seed.timezone,
       (date_trunc('day', now() AT TIME ZONE seed.timezone) + seed.local_start + seed.duration) AT TIME ZONE seed.timezone
FROM (VALUES
    -- Maya (60 min): one booked, two open, one in the past (completed)
    ('80000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'Asia/Kolkata', INTERVAL '3 days 09:00', INTERVAL '60 minutes'),
    ('80000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000001', 'Asia/Kolkata', INTERVAL '3 days 10:00', INTERVAL '60 minutes'),
    ('80000000-0000-4000-8000-000000000003', '60000000-0000-4000-8000-000000000001', 'Asia/Kolkata', INTERVAL '4 days 14:00', INTERVAL '60 minutes'),
    ('80000000-0000-4000-8000-000000000004', '60000000-0000-4000-8000-000000000001', 'Asia/Kolkata', INTERVAL '-7 days 09:00', INTERVAL '60 minutes'),
    -- Daniel (60 min): one with a cancelled session (bookable again), one open
    ('80000000-0000-4000-8000-000000000005', '60000000-0000-4000-8000-000000000002', 'Europe/London', INTERVAL '5 days 10:00', INTERVAL '60 minutes'),
    ('80000000-0000-4000-8000-000000000006', '60000000-0000-4000-8000-000000000002', 'Europe/London', INTERVAL '5 days 11:00', INTERVAL '60 minutes'),
    -- Sofia (30 min): two open back-to-back slots
    ('80000000-0000-4000-8000-000000000007', '60000000-0000-4000-8000-000000000003', 'Europe/Stockholm', INTERVAL '2 days 18:00', INTERVAL '30 minutes'),
    ('80000000-0000-4000-8000-000000000008', '60000000-0000-4000-8000-000000000003', 'Europe/Stockholm', INTERVAL '2 days 18:30', INTERVAL '30 minutes')
) AS seed (slot_id, availability_template_id, timezone, local_start, duration)
ON CONFLICT DO NOTHING;

-- ============================================================
-- sessions: confirmed, completed and cancelled examples
-- ============================================================
INSERT INTO sessions (session_id, slot_id, client_id, domain_id, topic, status, cancelled_at, cancelled_by)
SELECT seed.session_id::UUID,
       seed.slot_id::UUID,
       seed.client_id::UUID,
       domains.domain_id,
       seed.topic,
       seed.status,
       CASE WHEN seed.cancelled_by IS NOT NULL THEN now() END,
       seed.cancelled_by::UUID
FROM (VALUES
    ('90000000-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
     'BURNOUT', 'Feeling drained at work and unsure how to reset.', 'CONFIRMED', NULL),
    ('90000000-0000-4000-8000-000000000002', '80000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000002',
     'CAREER', 'Preparing for a promotion conversation.', 'COMPLETED', NULL),
    ('90000000-0000-4000-8000-000000000003', '80000000-0000-4000-8000-000000000005', '30000000-0000-4000-8000-000000000002',
     'LEADERSHIP', 'Leading a newly formed team.', 'CANCELLED', '10000000-0000-4000-8000-000000000102')
) AS seed (session_id, slot_id, client_id, domain_code, topic, status, cancelled_by)
JOIN domains ON domains.code = seed.domain_code
ON CONFLICT DO NOTHING;

COMMIT;
