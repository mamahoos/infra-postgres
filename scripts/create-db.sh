#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

DB_NAME="${1:-}"
if [[ -z "$DB_NAME" ]]; then
  echo "Usage: $0 <database_name>"
  exit 1
fi

validate_identifier "$DB_NAME" "database name"

compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}') THEN
    EXECUTE format('CREATE DATABASE %I', '${DB_NAME}');
  END IF;
END
\$\$;
EOSQL

echo "Database '$DB_NAME' ready."
