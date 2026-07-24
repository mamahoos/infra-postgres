#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env
require_backup_enabled

DB_NAME="${1:-${POSTGRES_DB:-}}"
if [[ -z "$DB_NAME" ]]; then
  echo "Usage: $0 [database_name]" >&2
  exit 1
fi
validate_identifier "$DB_NAME" "database name"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DAILY_DIR="$(backup_tier_dir daily)"
mkdir -p "$DAILY_DIR"

OUTPUT_FILE="/backups/daily/${DB_NAME}_${TIMESTAMP}.dump"

compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$DB_NAME" -Fc -f "$OUTPUT_FILE"

echo "Backup created: backups/daily/$(basename "$OUTPUT_FILE")"

"$SCRIPT_DIR/rotate-backups.sh" --prune-daily
echo "Pruned expired daily backups (retention: ${BACKUP_RETENTION_DAYS} days)."
