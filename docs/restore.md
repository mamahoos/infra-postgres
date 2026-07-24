# Restore

Restore requires backups to be enabled:

```env
BACKUP_ENABLED=true
```

## Quick start

```bash
./scripts/restore.sh <backup_file> [target_database]
```

The script searches `backups/daily/`, `backups/weekly/`, and `backups/monthly/` when given a filename only.

## Examples

```bash
# Restore to default database from .env
./scripts/restore.sh postgres_20260707_020000.dump

# Restore to a specific database
./scripts/restore.sh postgres_20260707_020000.dump my_service

# Restore from a specific tier
./scripts/restore.sh daily/postgres_20260707_020000.dump my_service
```

## Behaviour

- Uses `pg_restore --clean --if-exists` — existing objects in the target DB may be dropped
- Target database must already exist (create with `./scripts/create-db.sh` if needed)

## Recovery scenarios

| Situation | Look in |
|-----------|---------|
| Today's failure | `backups/daily/` |
| Failure from ~2 weeks ago | `backups/weekly/` (only if GFS is configured) |
| Failure from months ago | `backups/monthly/` (only if GFS is configured) |

## Warning

Restore is destructive to the target database schema/data. Test on a non-production database first.
