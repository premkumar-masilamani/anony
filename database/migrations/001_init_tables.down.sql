-- 001_init_tables.down.sql
-- Exact reversal of 001_init_tables.up.sql (drops in reverse dependency order).

DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS slots CASCADE;
DROP TABLE IF EXISTS availability_windows CASCADE;
DROP TABLE IF EXISTS availability_templates CASCADE;
DROP TABLE IF EXISTS coach_domains CASCADE;
DROP TABLE IF EXISTS domains CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS coaches CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP EXTENSION IF EXISTS btree_gist;
