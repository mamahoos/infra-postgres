#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

DB_NAME="${1:-}"
if [[ -z "$DB_NAME" ]]; then
  echo "Usage: $0 <database_name>"
  exit 1
fi

compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE \"$DB_NAME\";"

echo "Database '$DB_NAME' created successfully."
