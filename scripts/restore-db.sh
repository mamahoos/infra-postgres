#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

DUMP_FILE="${1:-}"
TARGET_DB="${2:-${POSTGRES_DB:-}}"

if [[ -z "$DUMP_FILE" || -z "$TARGET_DB" ]]; then
  echo "Usage: $0 <backup_file_name_in_db/backups> [target_database]"
  exit 1
fi

if [[ ! -f "$ROOT_DIR/db/backups/$DUMP_FILE" ]]; then
  echo "Error: file db/backups/$DUMP_FILE not found"
  exit 1
fi

compose exec -T postgres pg_restore -U "$POSTGRES_USER" -d "$TARGET_DB" --clean --if-exists "/backups/$DUMP_FILE"

echo "Restore completed to database '$TARGET_DB'."
