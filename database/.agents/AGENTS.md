# AGENTS.md - Database

## Commands
```bash
# Connect to psql shell on active container
make connect_database
```

> [!CAUTION]
> **NEVER apply migrations**: Agents must NEVER run `make migrate_database`, `make run_database`, or any command that applies migrations. All migrations are strictly manual.

## Boundaries

### Always do
- Use append-only SQL migration pairs in `database/migrations/`.
- Ensure down scripts are exact reversals (`DROP TABLE IF EXISTS ... CASCADE`).
- Use `IF EXISTS` / `IF NOT EXISTS` guards for idempotency.
- Use DB migrations strictly for DDL only (schema changes).
- Author migration files only; leave execution entirely to the user (all migrations are manual).
- Author any schema updates, new columns, or alterations in a new, separately numbered migration script pair (`XXX_...up.sql` / `XXX_...down.sql`). DB migrations are executed only for new scripts; existing/already-authored migration files must never be retroactively modified.
- Primary key convention in `anony`: Use UUID primary keys `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` unless specified otherwise in schema specs.
- Ensure all child tables enforce foreign keys with appropriate `ON DELETE CASCADE` or `ON DELETE RESTRICT` constraints.

### Ask first
- Any structural schema changes or dropping tables/columns.

### Never do
- Apply migrations (never run `make migrate_database`, `make run_database`, `migrate`, or any automated migration execution). All migrations are manual—never ever apply them.
- Edit, retroactively update, or alter existing/already-authored migration files. All schema additions must be created in a new, separate migration script.
- Drop tables without `CASCADE`.
- Use PostgreSQL reserved keywords (`user`, `type`, `order`, etc.) for column names.

## Project Structure
```text
migrations/        # Sequentially numbered up/down SQL migration pairs
data/              # Raw SQL seed data (seed_data.sql)
scripts/           # Initialization scripts (import_seed_data.sh)
```
