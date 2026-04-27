#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

deliver_once() {
  local source_file="$1"
  local session="$2"
  local role="$3"
  [ -s "$source_file" ] || return 0
  if ! command -v tmux >/dev/null 2>&1 || ! tmux has-session -t "$session" 2>/dev/null; then
    append_log "$WATCHDOG_LOG" "pending $role dispatch; tmux session $session unavailable"
    return 0
  fi
  if ! validate_dispatch_file "$source_file"; then
    append_log "$WATCHDOG_LOG" "invalid dispatch in $source_file"
    return 0
  fi
  tmux load-buffer -b "multiagentsystem-watchdog-$$" "$source_file"
  tmux paste-buffer -b "multiagentsystem-watchdog-$$" -t "$session"
  tmux send-keys -t "$session" Enter
  tmux delete-buffer -b "multiagentsystem-watchdog-$$" >/dev/null 2>&1 || true
  : > "$source_file"
  append_log "$WATCHDOG_LOG" "delivered $role dispatch to $session"
}

while true; do
  deliver_once "$EXECUTOR_INBOX" "$EXECUTOR_SESSION" executor
  deliver_once "$AUDITOR_INBOX" "$AUDITOR_SESSION" auditor
  sleep "$WATCHDOG_POLL_INTERVAL"
done
