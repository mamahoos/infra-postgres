# Backup

## Quick start

```bash
./scripts/backup.sh              # backs up POSTGRES_DB from .env
./scripts/backup.sh my_service   # backs up a specific database
```

Backups are written to `backups/daily/` as custom-format dumps (`pg_dump -Fc`).

After each backup, `rotate-backups.sh` runs automatically to apply the GFS retention policy.

## GFS layout

| Tier | Directory | Default retention |
|------|-----------|-------------------|
| Daily | `backups/daily/` | 7 days |
| Weekly | `backups/weekly/` | 4 weeks |
| Monthly | `backups/monthly/` | 12 months |

Configure in `.env`:

```env
BACKUP_RETENTION_DAYS=7
BACKUP_RETENTION_WEEKS=4
BACKUP_RETENTION_MONTHS=12
```

### Personal / simple mode

For a single-machine setup, keep only daily backups:

```env
BACKUP_RETENTION_DAYS=14
BACKUP_RETENTION_WEEKS=0
BACKUP_RETENTION_MONTHS=0
```

## Manual rotation

```bash
./scripts/rotate-backups.sh
```

## Scheduling

Core compose does not include a scheduler. Use cron on the host:

```cron
0 2 * * * cd /path/to/infra-postgres && ./scripts/backup.sh >> /var/log/infra-postgres-backup.log 2>&1
```

## Notes

- Backup files are gitignored — never commit dumps
- Dumps live inside the container at `/backups/` (bind-mounted from `./backups/`)
