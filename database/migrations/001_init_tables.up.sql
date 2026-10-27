-- 001_init_tables.up.sql
-- Initial relational schema for anony (issue #36).
-- Authored only: migrations are applied manually by the project owner.

-- btree_gist lets exclusion constraints combine equality on UUID/SMALLINT columns
-- with range overlap, so overlapping availability windows and slots are rejected by the database.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================
-- users: authentication identity only (one role per user)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    user_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    email            VARCHAR(320) NOT NULL,
    password_hash    VARCHAR(255) NOT NULL,
    role             VARCHAR(10)  NOT NULL,
    token_id         UUID,
    token_expires_at TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT users_role_check CHECK (role IN ('COACH', 'CLIENT')),
    CONSTRAINT users_token_pair_check CHECK ((token_id IS NULL) = (token_expires_at IS NULL)),
    CONSTRAINT users_token_id_key UNIQUE (token_id),
    -- Target of the (user_id, user_role) foreign keys on coaches and clients.
    CONSTRAINT users_user_id_role_key UNIQUE (user_id, role)
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_key ON users (lower(email));

-- ============================================================
-- coaches: public coach profile, including ICF credentials
-- ============================================================
CREATE TABLE IF NOT EXISTS coaches (
    coach_id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID          NOT NULL,
    -- Constant discriminator: guarantees the linked user has role COACH.
    user_role          VARCHAR(10)   NOT NULL DEFAULT 'COACH',
    first_name         VARCHAR(100)  NOT NULL,
    last_name          VARCHAR(100)  NOT NULL,
    photo_url          VARCHAR(2048),
    gender             VARCHAR(20),
    country_code       VARCHAR(2),
    timezone           VARCHAR(64)   NOT NULL,
    biography          VARCHAR(1000),
    icf_acc            BOOLEAN       NOT NULL,
    icf_pcc            BOOLEAN       NOT NULL,
    icf_mcc            BOOLEAN       NOT NULL,
    icf_actc           BOOLEAN       NOT NULL,
    credential_details VARCHAR(1000),
    is_verified        BOOLEAN       NOT NULL DEFAULT FALSE,
    is_onboarded       BOOLEAN       NOT NULL,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT coaches_user_id_key UNIQUE (user_id),
    CONSTRAINT coaches_user_role_check CHECK (user_role = 'COACH'),
    CONSTRAINT coaches_user_fkey FOREIGN KEY (user_id, user_role)
        REFERENCES users (user_id, role) ON DELETE CASCADE,
    CONSTRAINT coaches_gender_check CHECK (gender IN ('MALE', 'FEMALE', 'NON_BINARY', 'PREFER_NOT_TO_SAY')),
    CONSTRAINT coaches_country_code_check CHECK (country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT coaches_icf_credential_check CHECK (icf_acc OR icf_pcc OR icf_mcc OR icf_actc)
);

-- ============================================================
-- clients: coaching clients; is_anonymous hides names from coaches
-- ============================================================
CREATE TABLE IF NOT EXISTS clients (
    client_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL,
    -- Constant discriminator: guarantees the linked user has role CLIENT.
    user_role    VARCHAR(10)  NOT NULL DEFAULT 'CLIENT',
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    is_anonymous BOOLEAN      NOT NULL,
    alias        VARCHAR(64)  NOT NULL,
    is_onboarded BOOLEAN      NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT clients_user_id_key UNIQUE (user_id),
    CONSTRAINT clients_user_role_check CHECK (user_role = 'CLIENT'),
    CONSTRAINT clients_user_fkey FOREIGN KEY (user_id, user_role)
        REFERENCES users (user_id, role) ON DELETE CASCADE
);

-- ============================================================
-- domains: lookup of coaching domains (rows live in seed data)
-- ============================================================
CREATE TABLE IF NOT EXISTS domains (
    domain_id UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    code      VARCHAR(40)  NOT NULL,
    name      VARCHAR(100) NOT NULL,
    CONSTRAINT domains_code_key UNIQUE (code)
);

-- ============================================================
-- coach_domains: coach <-> domain specialisations
-- ============================================================
CREATE TABLE IF NOT EXISTS coach_domains (
    coach_domain_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id        UUID NOT NULL REFERENCES coaches (coach_id) ON DELETE CASCADE,
    domain_id       UUID NOT NULL REFERENCES domains (domain_id) ON DELETE RESTRICT,
    CONSTRAINT coach_domains_coach_id_domain_id_key UNIQUE (coach_id, domain_id)
);

CREATE INDEX IF NOT EXISTS coach_domains_domain_id_idx ON coach_domains (domain_id);

-- ============================================================
-- availability_templates: exactly one weekly template per coach
-- ============================================================
CREATE TABLE IF NOT EXISTS availability_templates (
    availability_template_id UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id                 UUID        NOT NULL REFERENCES coaches (coach_id) ON DELETE CASCADE,
    slot_duration_minutes    SMALLINT    NOT NULL,
    is_active                BOOLEAN     NOT NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT availability_templates_coach_id_key UNIQUE (coach_id),
    CONSTRAINT availability_templates_slot_duration_check CHECK (slot_duration_minutes IN (30, 60))
);

-- ============================================================
-- availability_windows: weekly start/end time ranges of a template
-- Times are wall-clock times in the coach's timezone.
-- ============================================================
CREATE TABLE IF NOT EXISTS availability_windows (
    availability_window_id   UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
    availability_template_id UUID     NOT NULL
        REFERENCES availability_templates (availability_template_id) ON DELETE CASCADE,
    day_of_week              SMALLINT NOT NULL,
    start_time               TIME     NOT NULL,
    end_time                 TIME     NOT NULL,
    -- ISO-8601 numbering: 1 = Monday ... 7 = Sunday.
    CONSTRAINT availability_windows_day_of_week_check CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT availability_windows_time_order_check CHECK (end_time > start_time),
    -- TIME has no built-in range type, so the times are anchored to a fixed date to build a tsrange.
    CONSTRAINT availability_windows_no_overlap EXCLUDE USING gist (
        availability_template_id WITH =,
        day_of_week WITH =,
        tsrange(DATE '2000-01-01' + start_time, DATE '2000-01-01' + end_time) WITH &&
    )
);

-- ============================================================
-- slots: concrete bookable time slots generated from a template
-- ============================================================
CREATE TABLE IF NOT EXISTS slots (
    slot_id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    availability_template_id UUID        NOT NULL
        REFERENCES availability_templates (availability_template_id) ON DELETE CASCADE,
    start_at                 TIMESTAMPTZ NOT NULL,
    end_at                   TIMESTAMPTZ NOT NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT slots_duration_check CHECK (end_at - start_at IN (INTERVAL '30 minutes', INTERVAL '60 minutes')),
    CONSTRAINT slots_no_overlap EXCLUDE USING gist (
        availability_template_id WITH =,
        tstzrange(start_at, end_at) WITH &&
    )
);

CREATE INDEX IF NOT EXISTS slots_availability_template_id_start_at_idx ON slots (availability_template_id, start_at);

-- ============================================================
-- sessions: a client's booking of a slot
-- ============================================================
CREATE TABLE IF NOT EXISTS sessions (
    session_id   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    slot_id      UUID         NOT NULL REFERENCES slots (slot_id) ON DELETE RESTRICT,
    client_id    UUID         NOT NULL REFERENCES clients (client_id) ON DELETE RESTRICT,
    domain_id    UUID         REFERENCES domains (domain_id) ON DELETE RESTRICT,
    topic        VARCHAR(500),
    status       VARCHAR(20)  NOT NULL,
    cancelled_at TIMESTAMPTZ,
    cancelled_by UUID         REFERENCES users (user_id) ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT sessions_status_check CHECK (status IN ('CONFIRMED', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    -- Cancellation details are present exactly when the session is cancelled.
    CONSTRAINT sessions_cancellation_check CHECK (
        (status = 'CANCELLED') = (cancelled_at IS NOT NULL)
        AND (status = 'CANCELLED') = (cancelled_by IS NOT NULL)
    )
);

-- At most one non-cancelled session per slot: makes booking atomic.
CREATE UNIQUE INDEX IF NOT EXISTS sessions_slot_id_active_key ON sessions (slot_id) WHERE status <> 'CANCELLED';
CREATE INDEX IF NOT EXISTS sessions_client_id_created_at_idx ON sessions (client_id, created_at);
CREATE INDEX IF NOT EXISTS sessions_domain_id_idx ON sessions (domain_id);
