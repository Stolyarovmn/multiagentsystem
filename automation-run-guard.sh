#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOCKS_DIR="$ROOT/.locks/automation"
STATUS_SCRIPT="$ROOT/automation-report-status.sh"
STALE_MIN="${AUTOMATION_LOCK_STALE_MIN:-45}"

usage() {
  cat <<'USAGE'
Usage:
  automation-run-guard.sh acquire <loop-name> [--require-status ok]
  automation-run-guard.sh release <loop-name>
  automation-run-guard.sh status <loop-name>

Prevents overlapping automation runs and optionally gates execution on
automation-report-status.sh.
USAGE
}

now_epoch() {
  date +%s
}

lock_dir_for() {
  local name="$1"
  printf '%s/%s.lock\n' "$LOCKS_DIR" "$name"
}

report_status() {
  "$STATUS_SCRIPT" | awk -F': ' '$1 == "status" {print $2; found=1} END {if (!found) exit 1}'
}

lock_age_sec() {
  local lock_dir="$1"
  local created_file="$lock_dir/created_at_epoch"
  local created=""

  if [ -f "$created_file" ]; then
    created="$(cat "$created_file" 2>/dev/null || true)"
  fi

  case "$created" in
    ''|*[!0-9]*)
      printf '%s\n' "$((STALE_MIN * 60 + 1))"
      ;;
    *)
      printf '%s\n' "$(( $(now_epoch) - created ))"
      ;;
  esac
}

write_lock_metadata() {
  local lock_dir="$1"
  local name="$2"

  {
    printf 'loop=%s\n' "$name"
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$(hostname 2>/dev/null || printf unknown)"
    printf 'started_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'cwd=%s\n' "$(pwd)"
  } > "$lock_dir/metadata"
  now_epoch > "$lock_dir/created_at_epoch"
}

acquire_lock() {
  local name="$1"
  local require_status="${2:-}"
  local current_status=""
  local lock_dir=""
  local age=0

  if [ "$require_status" = "--require-status" ]; then
    require_status="${3:-}"
  fi

  if [ -n "$require_status" ]; then
    current_status="$(report_status)"
    if [ "$current_status" != "$require_status" ]; then
      printf 'guard_blocked: report status is %s, required %s\n' "$current_status" "$require_status" >&2
      exit 20
    fi
  fi

  mkdir -p "$LOCKS_DIR"
  lock_dir="$(lock_dir_for "$name")"

  if mkdir "$lock_dir" 2>/dev/null; then
    write_lock_metadata "$lock_dir" "$name"
    printf 'guard_acquired: %s\n' "$lock_dir"
    return 0
  fi

  age="$(lock_age_sec "$lock_dir")"
  if [ "$age" -gt "$((STALE_MIN * 60))" ]; then
    rm -rf "$lock_dir"
    if mkdir "$lock_dir" 2>/dev/null; then
      write_lock_metadata "$lock_dir" "$name"
      printf 'guard_acquired_after_stale_cleanup: %s\n' "$lock_dir"
      return 0
    fi
  fi

  printf 'guard_blocked: lock already exists for %s at %s\n' "$name" "$lock_dir" >&2
  if [ -f "$lock_dir/metadata" ]; then
    sed -n '1,20p' "$lock_dir/metadata" >&2 || true
  fi
  exit 21
}

release_lock() {
  local name="$1"
  local lock_dir

  lock_dir="$(lock_dir_for "$name")"
  rm -rf "$lock_dir"
  printf 'guard_released: %s\n' "$lock_dir"
}

show_status() {
  local name="$1"
  local lock_dir age

  lock_dir="$(lock_dir_for "$name")"
  if [ ! -d "$lock_dir" ]; then
    printf 'guard_status: unlocked\n'
    return 0
  fi

  age="$(lock_age_sec "$lock_dir")"
  printf 'guard_status: locked\n'
  printf 'lock_dir: %s\n' "$lock_dir"
  printf 'age_sec: %s\n' "$age"
  if [ -f "$lock_dir/metadata" ]; then
    sed -n '1,20p' "$lock_dir/metadata"
  fi
}

main() {
  local command="${1:-}"
  local name="${2:-}"

  if [ -z "$command" ] || [ -z "$name" ]; then
    usage >&2
    exit 2
  fi

  case "$command" in
    acquire)
      shift 2
      acquire_lock "$name" "$@"
      ;;
    release)
      release_lock "$name"
      ;;
    status)
      show_status "$name"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      printf 'Unknown command: %s\n\n' "$command" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
