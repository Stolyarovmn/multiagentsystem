#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

watch_mode=0
if [ "${1:-}" = "watch" ]; then
  watch_mode=1
fi

cron_present() {
  crontab -l 2>/dev/null | grep -Fq "$ROOT/coordinator.sh"
}

print_once() {
  if [ -t 1 ] && command -v clear >/dev/null 2>&1; then
    clear
  fi
  printf 'multiagentsystem status\n'
  printf 'root: %s\n\n' "$ROOT"

  printf 'sessions\n'
  if tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null; then
    printf '  OK   executor: %s\n' "$EXECUTOR_SESSION"
  else
    printf '  FAIL executor: %s\n' "$EXECUTOR_SESSION"
  fi

  if tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null; then
    printf '  OK   auditor:  %s\n' "$AUDITOR_SESSION"
  else
    printf '  FAIL auditor:  %s\n' "$AUDITOR_SESSION"
  fi

  if screen_session_running "$WATCHDOG_SCREEN"; then
    printf '  OK   watchdog: %s\n' "$WATCHDOG_SCREEN"
  else
    printf '  FAIL watchdog: %s\n' "$WATCHDOG_SCREEN"
  fi

  if cron_present; then
    printf '  OK   cron: coordinator installed\n'
  else
    printf '  WARN cron: coordinator entry missing\n'
  fi

  printf '\nstate\n'
  tail -n 12 "$STATE_FILE" | sed 's/^/  /'

  printf '\nqueues\n'
  for queue in "$EXECUTOR_INBOX" "$AUDITOR_INBOX" "$SIGNAL_FILE"; do
    if [ -s "$queue" ]; then
      printf '  PENDING %s (%s bytes)\n' "$(basename "$queue")" "$(wc -c < "$queue")"
    else
      printf '  EMPTY   %s\n' "$(basename "$queue")"
    fi
  done

  printf '\nrecent metrics\n'
  tail -n 8 "$METRICS_LOG" 2>/dev/null | sed 's/^/  /' || true

  printf '\nrecent coordinator log\n'
  tail -n 8 "$COORDINATOR_LOG" 2>/dev/null | sed 's/^/  /' || true
}

if [ "$watch_mode" -eq 1 ]; then
  while true; do
    print_once
    sleep 2
  done
else
  print_once
fi
