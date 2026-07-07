#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

USERNAME="${1:-}"
PASSWORD="${2:-}"

if [[ -z "$USERNAME" ]]; then
  echo "Usage: $0 <username> [password]"
  echo "If password is omitted, POSTGRES_PASSWORD from .env is used as a placeholder."
  exit 1
fi

if [[ -z "$PASSWORD" ]]; then
  PASSWORD="${POSTGRES_PASSWORD:-change_me}"
  echo "Warning: using password from .env — change it after creation." >&2
fi

ESCAPED_PASSWORD="${PASSWORD//\'/\'\'}"
SQL="DO \$\$
BEGIN
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = '${USERNAME}') THEN
    ALTER ROLE \"${USERNAME}\" WITH LOGIN PASSWORD '${ESCAPED_PASSWORD}';
  ELSE
    CREATE ROLE \"${USERNAME}\" WITH LOGIN PASSWORD '${ESCAPED_PASSWORD}';
  END IF;
END
\$\$;"

compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -c "$SQL"

echo "User '$USERNAME' created or updated."
