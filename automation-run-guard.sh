#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

usage() {
  printf 'Usage: %s acquire|release|status <name>\n' "$0"
}

cmd="${1:-}"
name="${2:-}"
[ -n "$cmd" ] && [ -n "$name" ] || { usage >&2; exit 2; }

lock="$LOCKS_DIR/${name}.lock"

case "$cmd" in
  acquire)
    mkdir "$lock" 2>/dev/null || { printf 'guard_blocked: %s already locked\n' "$name"; exit 1; }
    date -u '+%Y-%m-%dT%H:%M:%SZ' > "$lock/started_at"
    printf 'guard_acquired: %s\n' "$name"
    ;;
  release)
    rm -rf "$lock"
    printf 'guard_released: %s\n' "$name"
    ;;
  status)
    if [ -d "$lock" ]; then
      printf 'guard_locked: %s\n' "$name"
    else
      printf 'guard_free: %s\n' "$name"
    fi
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
