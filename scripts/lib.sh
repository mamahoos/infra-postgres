#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
COMPOSE_FILE="$ROOT_DIR/compose.yaml"
DOCKER_COMPOSE_CMD=()

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    set +a
  fi
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
