#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

log() {
  append_log "$COORDINATOR_LOG" "$*"
}

dispatch_task_to_executor() {
  local task_file="$1"
  local task_id
  task_id="$(basename "$task_file" .md)"
  extract_dispatch "$task_file" > "$EXECUTOR_INBOX"
  update_task_status "$task_id" IN_PROGRESS
  set_state ACTIVE_TASK "$task_id"
  log "dispatched $task_id to executor"
}

process_signals() {
  local tmp
  tmp=$(mktemp)
  cp "$SIGNAL_FILE" "$tmp"
  : > "$SIGNAL_FILE"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    set_state LAST_SIGNAL "$line"
    case "$line" in
      TASK-[0-9][0-9][0-9]" NEEDS_REVIEW:"*)
        task_id=${line%% *}
        update_task_status "$task_id" REVIEW || true
        extract_dispatch "$(task_file_for "$task_id")" > "$AUDITOR_INBOX"
        ;;
      TASK-[0-9][0-9][0-9]" DONE:"*)
        task_id=${line%% *}
        update_task_status "$task_id" DONE || true
        set_state ACTIVE_TASK none
        ;;
      TASK-[0-9][0-9][0-9]" BLOCKED:"*)
        task_id=${line%% *}
        update_task_status "$task_id" BLOCKED || true
        set_state ACTIVE_TASK none
        ;;
      TASK-[0-9][0-9][0-9]" AUDIT PASS"*)
        task_id=${line%% *}
        update_task_status "$task_id" DONE || true
        set_state ACTIVE_TASK none
        ;;
      TASK-[0-9][0-9][0-9]" AUDIT FAIL:"*)
        task_id=${line%% *}
        update_task_status "$task_id" IN_PROGRESS || true
        extract_dispatch "$(task_file_for "$task_id")" > "$EXECUTOR_INBOX"
        ;;
    esac
    log "processed signal: $line"
  done < "$tmp"
  rm -f "$tmp"
}

process_signals

if [ -s "$EXECUTOR_INBOX" ] || [ "$(get_state ACTIVE_TASK 2>/dev/null || printf none)" != "none" ]; then
  set_state LAST_COORDINATOR_CHECK "$(utc_now)"
  exit 0
fi

next_task=$(find "$TASKS_DIR" -maxdepth 1 -type f -name 'TASK-*.md' -print | sort | while read -r file; do
  awk '$1 == "STATUS" && $2 == "QUEUED" {print FILENAME; exit}' "$file"
done | head -n 1)

if [ -n "$next_task" ]; then
  dispatch_task_to_executor "$next_task"
fi

set_state LAST_COORDINATOR_CHECK "$(utc_now)"
