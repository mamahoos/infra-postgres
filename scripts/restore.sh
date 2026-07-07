#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

DUMP_ARG="${1:-}"
TARGET_DB="${2:-${POSTGRES_DB:-}}"

if [[ -z "$DUMP_ARG" || -z "$TARGET_DB" ]]; then
  echo "Usage: $0 <backup_file_or_tier/path> [target_database]"
  echo "Examples:"
  echo "  $0 mydb_20260707_120000.dump"
  echo "  $0 daily/mydb_20260707_120000.dump mydb"
  exit 1
fi

LOCAL_FILE="$(find_backup_file "$DUMP_ARG")"
REL_PATH="${LOCAL_FILE#$BACKUPS_DIR/}"
CONTAINER_PATH="/backups/$REL_PATH"

compose exec -T postgres pg_restore -U "$POSTGRES_USER" -d "$TARGET_DB" --clean --if-exists "$CONTAINER_PATH"

echo "Restore completed to database '$TARGET_DB' from backups/$REL_PATH"
