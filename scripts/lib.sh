#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
COMPOSE_FILE="$ROOT_DIR/compose.yaml"
BACKUPS_DIR="$ROOT_DIR/backups"
DOCKER_COMPOSE_CMD=()

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    set +a
  fi

  POSTGRES_VERSION="${POSTGRES_VERSION:-17}"
  POSTGRES_USER="${POSTGRES_USER:-postgres}"
  POSTGRES_DB="${POSTGRES_DB:-postgres}"
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"
  BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
  BACKUP_RETENTION_WEEKS="${BACKUP_RETENTION_WEEKS:-4}"
  BACKUP_RETENTION_MONTHS="${BACKUP_RETENTION_MONTHS:-12}"
}

require_compose() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD=(docker-compose)
    if [[ ! -f "$COMPOSE_FILE" && -f "$ROOT_DIR/docker-compose.yml" ]]; then
      COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
    fi
  else
    echo "Error: neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
  fi

  if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "Error: compose file not found at $COMPOSE_FILE" >&2
    exit 1
  fi
}

compose() {
  "${DOCKER_COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" "$@"
}

backup_tier_dir() {
  local tier="${1:-daily}"
  echo "$BACKUPS_DIR/$tier"
}

find_backup_file() {
  local name="$1"
  local tier dir

  if [[ "$name" == */* ]]; then
    if [[ -f "$BACKUPS_DIR/$name" ]]; then
      echo "$BACKUPS_DIR/$name"
      return 0
    fi
    echo "Error: backup file not found: backups/$name" >&2
    return 1
  fi

  for tier in daily weekly monthly; do
    dir="$(backup_tier_dir "$tier")"
    if [[ -f "$dir/$name" ]]; then
      echo "$dir/$name"
      return 0
    fi
  done

  echo "Error: backup file not found in daily/, weekly/, or monthly/: $name" >&2
  return 1
}
