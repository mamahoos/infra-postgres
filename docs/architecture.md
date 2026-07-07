# Architecture

## Overview

`infra-postgres` is a minimal, dockerized PostgreSQL **instance** repository. It follows a **core + optional** pattern suitable for the broader `infra-*` family.

**This repo provides PostgreSQL infrastructure — not application databases, roles, or secrets.**

## Responsibility boundaries

| Owned by infra-postgres | Owned by consuming applications |
|-------------------------|--------------------------------|
| PostgreSQL instance & named volume | Application databases |
| Cluster config (`postgresql.conf`, `pg_hba.conf`) | Application roles & passwords |
| Core extensions (pgcrypto, citext, …) | App-specific extensions (PostGIS, pgvector) |
| Backup / restore / rotation | Schema migrations & seed data |
| Healthcheck & monitoring hooks | Bootstrap SQL per service |

Application teams manage users and databases via their own repos (bootstrap SQL, migration tools, or IaC). See [application-bootstrap.md](application-bootstrap.md).

## Core

| Component | Purpose |
|-----------|---------|
| `compose.yaml` | Single Postgres service on an internal network |
| Named volume `infra_postgres_data` | Persistent database storage (not bind-mounted) |
| `postgres/conf/` | `postgresql.conf` and `pg_hba.conf` bind-mounted into the container |
| `postgres/init/00-extensions.sql` | Core extensions only — runs once on empty data dir |
| `postgres/healthcheck.sh` | Container health probe |
| `scripts/` | Backup, restore, rotation, and generic ops helpers |

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

## Initialization (first start only)

Docker runs `/docker-entrypoint-initdb.d/*` **only when `PGDATA` is empty**.

Core init:

- `00-extensions.sql` — pgcrypto, citext, uuid-ossp, pg_stat_statements

Files in `postgres/init/optional/` are **not** executed automatically.

> Init scripts are not suitable for ongoing role/database changes. Use application bootstrap or ops scripts after the instance is running.

Cluster-wide session defaults live in `postgresql.conf` (timezone, timeouts) — not per-database `ALTER DATABASE` in init SQL.

## Backup layout (GFS)

```
backups/
  daily/     ← backup.sh writes here
  weekly/    ← promoted on Sundays by rotate-backups.sh
  monthly/   ← promoted on the 1st by rotate-backups.sh
```

- `backup.sh` prunes expired daily backups after each run
- Full GFS promotion runs via `rotate-backups.sh` (schedule with cron)

Retention is configured via `.env`: `BACKUP_RETENTION_DAYS`, `BACKUP_RETENTION_WEEKS`, `BACKUP_RETENTION_MONTHS`.
