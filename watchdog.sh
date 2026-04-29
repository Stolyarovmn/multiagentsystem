#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

log() {
  append_log "$WATCHDOG_LOG" "$*"
}

task_id_from_dispatch() {
  local file="$1"
  sed -n 's/^TASK: \(TASK-[0-9][0-9][0-9]*\)$/\1/p' "$file" | head -n 1
}

deliver_message() {
  local session="$1"
  local message_file="$2"
  local buffer_name="mas-watchdog-$$"

  tmux load-buffer -b "$buffer_name" "$message_file"
  tmux paste-buffer -b "$buffer_name" -t "$session"
  tmux send-keys -t "$session" Enter
  tmux delete-buffer -b "$buffer_name" >/dev/null 2>&1 || true
}

build_message() {
  local role_file="$1"
  local dispatch_file="$2"
  local message_file="$3"

  if [ -f "$role_file" ]; then
    {
      cat "$role_file"
      printf '\n\n'
      printf '================================================================\n'
      printf 'TASK DISPATCH\n'
      printf '================================================================\n\n'
      cat "$dispatch_file"
      printf '\n'
    } > "$message_file"
  else
    cp "$dispatch_file" "$message_file"
  fi
}

process_inbox_file() {
  local source_file="$1"
  local session="$2"
  local role_file="$3"
  local role_name="$4"
  local claim_file=""
  local message_file=""
  local task_id=""
  local byte_size=0

  [ -s "$source_file" ] || return 0

  claim_file="${source_file}.claimed.$$"
  if ! mv "$source_file" "$claim_file" 2>/dev/null; then
    return 0
  fi

  if ! validate_dispatch_file "$claim_file"; then
    log "Invalid dispatch envelope in $claim_file"
    rm -f "$claim_file"
    return 0
  fi

  byte_size=$(wc -c < "$claim_file")
  task_id=$(task_id_from_dispatch "$claim_file")

  if [ "$byte_size" -gt "$ENVELOPE_MAX_BYTES" ]; then
    printf '%s BLOCKED: dispatch envelope exceeds ENVELOPE_MAX_BYTES=%s\n' "${task_id:-TASK-000}" "$ENVELOPE_MAX_BYTES" >> "$SIGNAL_FILE"
    log "Oversized envelope for ${task_id:-unknown}: ${byte_size} bytes"
    rm -f "$claim_file"
    return 0
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    mv "$claim_file" "$source_file"
    log "tmux session $session not found; envelope returned to queue"
    return 0
  fi

  message_file=$(mktemp)
  build_message "$role_file" "$claim_file" "$message_file"
  deliver_message "$session" "$message_file"
  log "Delivered ${task_id:-unknown} to $role_name session $session"
  rm -f "$message_file" "$claim_file"
}

log "watchdog started in $ROOT"

while true; do
  process_inbox_file "$EXECUTOR_INBOX" "$EXECUTOR_SESSION" "$EXECUTOR_ROLE_FILE" "executor"
  process_inbox_file "$AUDITOR_INBOX" "$AUDITOR_SESSION" "$AUDITOR_ROLE_FILE" "auditor"
  sleep "$WATCHDOG_POLL_INTERVAL"
done
