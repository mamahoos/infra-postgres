# Architecture

## Overview

`infra-postgres` is a minimal, dockerized PostgreSQL infrastructure repository. It follows a **core + optional** pattern suitable for the broader `infra-*` family.

## Core

| Component | Purpose |
|-----------|---------|
| `compose.yaml` | Single Postgres service on an internal network |
| Named volume `infra_postgres_data` | Persistent database storage (not bind-mounted) |
| `postgres/conf/` | `postgresql.conf` and `pg_hba.conf` bind-mounted into the container |
| `postgres/init/` | Ordered SQL bootstrap on first start |
| `postgres/healthcheck.sh` | Container health probe |
| `scripts/` | Backup, restore, rotation, and ops helpers |

## Optional (not in core compose)

| Capability | How to enable |
|------------|---------------|
| PostGIS / pgvector | Copy from `postgres/init/optional/` into `postgres/init/` before first start |
| postgres-exporter | `monitoring/postgres-exporter.env` + future `compose.monitoring.yaml` |
| pgAdmin, scheduler, replication | Separate compose overlays (future) |

## Data flow

```
Host                          Container (infra-postgres)
────                          ───────────────────────────
postgres/conf/        ──ro──►  /etc/postgresql/
postgres/init/        ──ro──►  /docker-entrypoint-initdb.d/
backups/              ──rw──►  /backups/
[named volume]        ──rw──►  /var/lib/postgresql/data
```

## Network

- Network: `infra_db_net` (bridge, `internal: true`)
- Port mapping controlled by `POSTGRES_PORT` in `.env`
- Other stacks attach via `external: true` network reference

## Initialization order

1. `00-extensions.sql` — pgcrypto, citext, uuid-ossp, pg_stat_statements
2. `10-create-roles.sql` — baseline roles
3. `20-default-config.sql` — database-level defaults

Files in `postgres/init/optional/` are **not** executed automatically.

## Backup layout (GFS)

```
backups/
  daily/     ← backup.sh writes here
  weekly/    ← promoted by rotate-backups.sh
  monthly/   ← promoted by rotate-backups.sh
```

Retention is configured via `.env`: `BACKUP_RETENTION_DAYS`, `BACKUP_RETENTION_WEEKS`, `BACKUP_RETENTION_MONTHS`.
