#!/usr/bin/env bash
set -euo pipefail

# GFS backup rotation — retention values from .env (never hardcoded).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env

prune_by_age() {
  local dir="$1"
  local days="$2"
  local now epoch file_mtime age_days

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

promote_weekly() {
  local daily_dir weekly_dir week_id latest

  daily_dir="$(backup_tier_dir daily)"
  weekly_dir="$(backup_tier_dir weekly)"
  mkdir -p "$weekly_dir"

  week_id="$(date +%G-week-%V)"
  if compgen -G "$weekly_dir/*${week_id}*" > /dev/null; then
    return 0
  fi

  latest="$(find "$daily_dir" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  if [[ -n "$latest" ]]; then
    cp -p "$latest" "$weekly_dir/$(basename "${latest%.*}")_${week_id}.dump"
    echo "Promoted to weekly: $(basename "$weekly_dir/$(basename "${latest%.*}")_${week_id}.dump")"
  fi
}

promote_monthly() {
  local weekly_dir monthly_dir month_id source latest

  weekly_dir="$(backup_tier_dir weekly)"
  monthly_dir="$(backup_tier_dir monthly)"
  mkdir -p "$monthly_dir"

  month_id="$(date +%Y-%m)"
  if compgen -G "$monthly_dir/*${month_id}*" > /dev/null; then
    return 0
  fi

  source="$(backup_tier_dir weekly)"
  latest="$(find "$source" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  if [[ -z "$latest" ]]; then
    source="$(backup_tier_dir daily)"
    latest="$(find "$source" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  fi

  if [[ -n "$latest" ]]; then
    cp -p "$latest" "$monthly_dir/$(basename "${latest%.*}")_${month_id}.dump"
    echo "Promoted to monthly: $(basename "$monthly_dir/$(basename "${latest%.*}")_${month_id}.dump")"
  fi
}

run_rotation() {
  local daily_dir="$BACKUPS_DIR/daily"

  mkdir -p "$BACKUPS_DIR/daily" "$BACKUPS_DIR/weekly" "$BACKUPS_DIR/monthly"

  # Personal/simple mode: only daily retention when weekly/monthly retention is 0
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

run_rotation
echo "Backup rotation complete."
