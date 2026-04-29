#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

log() {
  printf '[%s] %s\n' "$(log_now)" "$*"
}

remove_cron_entry() {
  local tmp=""
  if ! crontab -l >/dev/null 2>&1; then
    return 0
  fi

  tmp=$(mktemp)
  crontab -l 2>/dev/null | grep -F -v "$ROOT/coordinator.sh" > "$tmp" || true
  crontab "$tmp"
  rm -f "$tmp"
}

if screen_session_running "$WATCHDOG_SCREEN"; then
  screen -S "$WATCHDOG_SCREEN" -X quit >/dev/null 2>&1 || true
  log "Stopped watchdog screen $WATCHDOG_SCREEN"
else
  log "Watchdog screen not running"
fi

if tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null; then
  tmux kill-session -t "$EXECUTOR_SESSION"
  log "Stopped tmux session $EXECUTOR_SESSION"
else
  log "Executor session not running"
fi

if tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null; then
  tmux kill-session -t "$AUDITOR_SESSION"
  log "Stopped tmux session $AUDITOR_SESSION"
else
  log "Auditor session not running"
fi

remove_cron_entry
set_state "SYSTEM_STATUS" "stopped"
log "Runtime stopped"
