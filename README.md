# Central Postgres Template

A fully dockerized central PostgreSQL template with internal Docker networking, initialization support, and operational scripts for database creation, backup, and restore.

## Project Structure

- `docker-compose.yml`: main Postgres service definition
- `db/init/`: SQL files executed on first database initialization
- `db/backups/`: backup output directory
- `scripts/`: operational bash scripts
- `.env.example`: environment variable template

## Quick Start

1. Copy environment file:

   ```bash
   cp .env.example .env
   ```

2. Start PostgreSQL:

   ```bash
   docker compose up -d
   ```

3. Check health:

   ```bash
   docker compose ps
   ```

## Scripts

All scripts are under `scripts/`.

### Create a new database

```bash
./scripts/create-db.sh my_service_db
```

### Create a backup

```bash
./scripts/backup-db.sh
# or
./scripts/backup-db.sh my_service_db
```

### Restore from backup

```bash
./scripts/restore-db.sh my_service_db_20260426_120000.dump
# or with target db
./scripts/restore-db.sh my_service_db_20260426_120000.dump my_service_db
```

## Networking and Security Notes

- The Postgres service is attached to an internal Docker network (`internal: true`).
- Port exposure is controlled via `.env` (`POSTGRES_PORT`).
- Database files are persisted in named volume `central_pg_data`.

## Initialization

Put SQL bootstrap files in `db/init/`. They are executed only the first time the data directory is initialized.

## Template Usage

After creating repositories from this template:

- update `.env.example`
- add service-specific SQL in `db/init/`
- extend `scripts/` based on your operational policies
