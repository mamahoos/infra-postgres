# infra-postgres

Dockerized PostgreSQL infrastructure with explicit configuration, operational scripts, and optional monitoring hooks.

**Core:** PostgreSQL instance, healthcheck, named volume, backup/restore with GFS rotation.

**Out of scope:** application databases, roles, passwords, and schema migrations — managed by consuming projects. See [docs/application-bootstrap.md](docs/application-bootstrap.md).

**Optional:** extensions (PostGIS, pgvector), postgres-exporter, pgAdmin — enabled separately without bloating the default compose.

## Project structure

```
infra-postgres/
├── compose.yaml
├── .env.example
├── postgres/
│   ├── conf/           # postgresql.conf, pg_hba.conf
│   ├── init/           # ordered SQL bootstrap
│   │   └── optional/   # PostGIS, pgvector (manual opt-in)
│   └── healthcheck.sh
├── scripts/            # backup, restore, ops helpers
├── backups/            # daily / weekly / monthly (gitignored)
├── monitoring/         # exporter env (no service in core compose)
└── docs/
```

## Quick start

1. Copy environment file:

   ```bash
   cp .env.example .env
   # Edit POSTGRES_PASSWORD and retention settings
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

All scripts auto-detect `docker compose` vs `docker-compose`.

| Script | Purpose |
|--------|---------|
| `./scripts/create-db.sh <name>` | Create an empty database (idempotent) |
| `./scripts/backup.sh [db]` | Backup to `backups/daily/` + prune expired dailies |
| `./scripts/restore.sh <file> [db]` | Restore from any GFS tier |
| `./scripts/rotate-backups.sh` | Full GFS promotion (schedule via cron) |
| `./scripts/psql.sh [db]` | Open psql in the container |
| `./scripts/logs.sh [lines]` | Tail Postgres logs |

Application roles and passwords are **not** managed here — see [docs/application-bootstrap.md](docs/application-bootstrap.md).

See [docs/backup.md](docs/backup.md) and [docs/restore.md](docs/restore.md) for details.

## Configuration

- **Data:** Docker named volume `infra_postgres_data` (not bind-mounted)
- **Config/init:** bind-mounted from `postgres/conf/` and `postgres/init/`
- **Network:** internal bridge `infra_db_net` — port exposure via `POSTGRES_PORT`
- **Version:** `POSTGRES_VERSION` in `.env` (default `17`)

## Optional extensions

Core init enables: `pgcrypto`, `citext`, `uuid-ossp`, `pg_stat_statements`.

For PostGIS or pgvector, copy the desired file from `postgres/init/optional/` into `postgres/init/` **before the first container start**:

```bash
cp postgres/init/optional/postgis.sql postgres/init/30-postgis.sql
```

## Optional monitoring

Core compose does **not** include postgres-exporter. If you have Prometheus, use `monitoring/postgres-exporter.env` and add a separate `compose.monitoring.yaml` (future).

## Documentation

- [Architecture](docs/architecture.md)
- [Application bootstrap](docs/application-bootstrap.md)
- [Backup](docs/backup.md)
- [Restore](docs/restore.md)

## Migration from central-postgres-template

| Old | New |
|-----|-----|
| `db/init/` | `postgres/init/` |
| `db/backups/` | `backups/daily/` |
| `scripts/backup-db.sh` | `scripts/backup.sh` |
| `scripts/restore-db.sh` | `scripts/restore.sh` |
| `POSTGRES_IMAGE` | `POSTGRES_VERSION` |
| volume `central_pg_data` | `infra_postgres_data` |
