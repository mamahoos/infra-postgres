-- Baseline roles — customize per deployment
-- Example read-only role (password set via create-user.sh or manual ALTER)

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly') THEN
    CREATE ROLE app_readonly WITH LOGIN PASSWORD 'change_me_readonly';
  END IF;
END
$$;
