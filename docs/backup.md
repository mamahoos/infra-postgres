# Backup

Backup is **optional** and off by default. Postgres runs fine without it.

## Enable

In `.env`:

```env
BACKUP_ENABLED=true
```

Personal defaults keep only daily dumps for 14 days (no weekly/monthly promotion):

```env
BACKUP_RETENTION_DAYS=14
BACKUP_RETENTION_WEEKS=0
BACKUP_RETENTION_MONTHS=0
```

## Quick start

```bash
./scripts/backup.sh              # backs up POSTGRES_DB from .env
./scripts/backup.sh my_service   # backs up a specific database
```

Backups are written to `backups/daily/` as custom-format dumps (`pg_dump -Fc`).

After each backup, expired daily files are pruned.

## Scheduling

Core compose does not include a scheduler. Use cron on the host:

```cron
0 2 * * * cd /path/to/infra-postgres && ./scripts/backup.sh >> /var/log/infra-postgres-backup.log 2>&1
```

## Advanced: GFS rotation

For longer retention, set weekly and/or monthly counts and schedule promotion separately:

```env
BACKUP_RETENTION_DAYS=7
BACKUP_RETENTION_WEEKS=4
BACKUP_RETENTION_MONTHS=12
```

```cron
0 3 * * 0 cd /path/to/infra-postgres && ./scripts/rotate-backups.sh
```

| Tier | Directory | Retention |
|------|-----------|-----------|
| Daily | `backups/daily/` | age (`BACKUP_RETENTION_DAYS`) |
| Weekly | `backups/weekly/` | newest N (`BACKUP_RETENTION_WEEKS`) |
| Monthly | `backups/monthly/` | newest N (`BACKUP_RETENTION_MONTHS`) |

Weekly promotion runs on **Sundays**; monthly on the **1st** of each month.

**Limitation:** each promotion copies only the single newest dump in the source tier. Multi-database setups do not get one weekly/monthly copy per database.

Manual run:

```bash
./scripts/rotate-backups.sh
```

## Notes

- Backup files are gitignored — never commit dumps
- Dumps live inside the container at `/backups/` (bind-mounted from `./backups/`)
- Scripts exit with a clear message when `BACKUP_ENABLED` is not true
