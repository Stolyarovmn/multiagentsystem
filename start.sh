#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

executor_cmd=$(detect_launch_cmd executor)
auditor_cmd=$(detect_launch_cmd auditor)

printf 'multiagentsystem start\n'
printf 'root: %s\n' "$ROOT"
printf 'executor session: %s command: %s\n' "$EXECUTOR_SESSION" "${executor_cmd:-manual shell}"
printf 'auditor session: %s command: %s\n' "$AUDITOR_SESSION" "${auditor_cmd:-manual shell}"
printf 'watchdog: %s\n' "$WATCHDOG_SCREEN"

[ "$DRY_RUN" -eq 1 ] && exit 0

command -v tmux >/dev/null 2>&1 || { printf 'tmux not found; runtime layout is ready for manual use\n' >&2; exit 0; }

if ! tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null; then
  tmux new-session -d -s "$EXECUTOR_SESSION" -c "$ROOT"
  [ -n "$executor_cmd" ] && tmux send-keys -t "$EXECUTOR_SESSION" "$executor_cmd" Enter
fi

if ! tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null; then
  tmux new-session -d -s "$AUDITOR_SESSION" -c "$ROOT"
  [ -n "$auditor_cmd" ] && tmux send-keys -t "$AUDITOR_SESSION" "$auditor_cmd" Enter
fi

set_state SYSTEM_STATUS running
printf 'runtime started\n'
