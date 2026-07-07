-- Optional: pgvector — NOT run automatically
-- Requires a Postgres image with pgvector preinstalled.
-- To enable, copy or symlink into postgres/init/ before first container start:
--   cp postgres/init/optional/pgvector.sql postgres/init/30-pgvector.sql
CREATE EXTENSION IF NOT EXISTS vector;
