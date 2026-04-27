#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

printf 'multiagentsystem status\n'
printf 'root: %s\n\n' "$ROOT"

printf 'state\n'
tail -n 20 "$STATE_FILE" | sed 's/^/  /'

printf '\nqueues\n'
for queue in "$EXECUTOR_INBOX" "$AUDITOR_INBOX" "$SIGNAL_FILE"; do
  if [ -s "$queue" ]; then
    printf '  PENDING %s (%s bytes)\n' "$(basename "$queue")" "$(wc -c < "$queue")"
  else
    printf '  EMPTY   %s\n' "$(basename "$queue")"
  fi
done

printf '\nsessions\n'
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null; then
  printf '  OK   executor: %s\n' "$EXECUTOR_SESSION"
else
  printf '  INFO executor: %s not running\n' "$EXECUTOR_SESSION"
fi

if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null; then
  printf '  OK   auditor: %s\n' "$AUDITOR_SESSION"
else
  printf '  INFO auditor: %s not running\n' "$AUDITOR_SESSION"
fi
