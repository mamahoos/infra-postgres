-- Optional: PostGIS — NOT run automatically
-- To enable, copy or symlink into postgres/init/ before first container start:
--   cp postgres/init/optional/postgis.sql postgres/init/30-postgis.sql
CREATE EXTENSION IF NOT EXISTS postgis;
