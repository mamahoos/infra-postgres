#!/usr/bin/env bash
set -euo pipefail

# GFS backup rotation — retention values from .env (never hardcoded).
# Promotion runs on schedule (Sunday → weekly, 1st → monthly), not on every backup.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env
require_backup_enabled

MODE="${1:-}"

prune_by_age() {
  local dir="$1"
  local days="$2"
  local now file_mtime age_days

  [[ -d "$dir" ]] || return 0
  now="$(date +%s)"

  while IFS= read -r -d '' file; do
    file_mtime="$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file")"
    age_days=$(( (now - file_mtime) / 86400 ))
    if (( age_days > days )); then
      rm -f "$file"
      echo "Pruned: ${file#$ROOT_DIR/}"
    fi
  done < <(find "$dir" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -print0 2>/dev/null)
}

prune_keep_newest() {
  local dir="$1"
  local keep="$2"
  local count=0

  [[ -d "$dir" ]] || return 0
  mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)

  for file in "${files[@]}"; do
    count=$((count + 1))
    if (( count > keep )); then
      rm -f "$file"
      echo "Pruned (count): ${file#$ROOT_DIR/}"
    fi
  done
}

newest_backup_in() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-
}

promote_weekly() {
  # ISO Sunday = 7
  [[ "$(date +%u)" -eq 7 ]] || return 0

  local daily_dir weekly_dir week_id latest dest

  daily_dir="$(backup_tier_dir daily)"
  weekly_dir="$(backup_tier_dir weekly)"
  mkdir -p "$weekly_dir"

  week_id="$(date +%G-week-%V)"
  if compgen -G "$weekly_dir/*${week_id}*" > /dev/null; then
    return 0
  fi

  latest="$(newest_backup_in "$daily_dir")"
  if [[ -n "$latest" ]]; then
    dest="$weekly_dir/$(basename "${latest%.*}")_${week_id}.dump"
    cp -p "$latest" "$dest"
    echo "Promoted to weekly: $(basename "$dest")"
  fi
}

promote_monthly() {
  [[ "$(date +%d)" -eq 01 ]] || return 0

  local weekly_dir monthly_dir month_id source latest dest

  weekly_dir="$(backup_tier_dir weekly)"
  monthly_dir="$(backup_tier_dir monthly)"
  mkdir -p "$monthly_dir"

  month_id="$(date +%Y-%m)"
  if compgen -G "$monthly_dir/*${month_id}*" > /dev/null; then
    return 0
  fi

  source="$weekly_dir"
  latest="$(newest_backup_in "$source")"
  if [[ -z "$latest" ]]; then
    source="$(backup_tier_dir daily)"
    latest="$(newest_backup_in "$source")"
  fi

  if [[ -n "$latest" ]]; then
    dest="$monthly_dir/$(basename "${latest%.*}")_${month_id}.dump"
    cp -p "$latest" "$dest"
    echo "Promoted to monthly: $(basename "$dest")"
  fi
}

prune_daily_only() {
  mkdir -p "$(backup_tier_dir daily)"
  prune_by_age "$(backup_tier_dir daily)" "${BACKUP_RETENTION_DAYS}"
}

run_rotation() {
  local daily_dir
  daily_dir="$(backup_tier_dir daily)"

  mkdir -p "$BACKUPS_DIR/daily" "$BACKUPS_DIR/weekly" "$BACKUPS_DIR/monthly"

  if [[ "${BACKUP_RETENTION_WEEKS:-0}" -eq 0 && "${BACKUP_RETENTION_MONTHS:-0}" -eq 0 ]]; then
    prune_by_age "$daily_dir" "${BACKUP_RETENTION_DAYS}"
    return 0
  fi

  promote_weekly
  promote_monthly
  prune_by_age "$daily_dir" "${BACKUP_RETENTION_DAYS}"
  prune_keep_newest "$(backup_tier_dir weekly)" "${BACKUP_RETENTION_WEEKS}"
  prune_keep_newest "$(backup_tier_dir monthly)" "${BACKUP_RETENTION_MONTHS}"
}

case "$MODE" in
  --prune-daily)
    prune_daily_only
    ;;
  "")
    run_rotation
    echo "Backup rotation complete."
    ;;
  *)
    echo "Usage: $0 [--prune-daily]" >&2
    exit 1
    ;;
esac
