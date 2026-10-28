#!/bin/bash
set -euo pipefail

if [ -z "${POSTGRES_USER:-}" ] || [ -z "${POSTGRES_PASSWORD:-}" ] || [ -z "${POSTGRES_DB:-}" ] || [ -z "${DOCKER_SEED_DATA_VOLUME:-}" ]; then
    echo "Error: Required environment variables (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, DOCKER_SEED_DATA_VOLUME) must be set." >&2
    exit 1
fi

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "Seeding pre-scheduled live demo session at current recording timestamp..."
psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -h "${POSTGRES_DB}" -f "${DOCKER_SEED_DATA_VOLUME}/seed_demo_session.sql"
echo "Live demo session seeded successfully."
