#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

require_compose
load_env

DB_NAME="${1:-${POSTGRES_DB:-}}"
EXTRA_ARGS=("${@:2}")

compose exec -it postgres psql -U "$POSTGRES_USER" -d "$DB_NAME" "${EXTRA_ARGS[@]}"
