#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

log() {
  append_log "$COORDINATOR_LOG" "$*"
}

event() {
  printf '[%s] %s\n' "$(utc_now)" "$*" >> "$EVENTS_LOG"
}

dispatch_to_executor() {
  local task_id="$1"
  dispatch_task_to_role "$task_id" "executor"
  log "Dispatch prepared for executor task=$task_id"
}

dispatch_to_auditor() {
  local task_id="$1"
  dispatch_task_to_role "$task_id" "auditor"
  log "Dispatch prepared for auditor task=$task_id"
}

task_from_signal() {
  local line="$1"
  printf '%s\n' "$line" | sed -n 's/.*\(TASK-[0-9][0-9][0-9]*\).*/\1/p' | head -n 1
}

process_line() {
  local line="$1"
  local task_id=""
  local reason=""
  local retry_count=0

  [ -n "$line" ] || return 0
  set_state "LAST_SIGNAL" "$line"

  if [[ "$line" =~ ^SESSION_START[[:space:]] ]]; then
    metric_line "$line"
    return 0
  fi

  if [[ "$line" =~ ^ATTEMPT_START[[:space:]] ]]; then
    metric_line "$line"
    task_id=$(task_from_signal "$line")
    if [ -n "$task_id" ]; then
      append_runtime_note "$task_id" "$line"
    fi
    return 0
  fi

  if [[ "$line" =~ ^ATTEMPT_END[[:space:]] ]]; then
    metric_line "$line"
    task_id=$(task_from_signal "$line")
    if [ -n "$task_id" ]; then
      append_runtime_note "$task_id" "$line"
    fi
    return 0
  fi

  if [[ "$line" =~ ^ARTIFACT_READY[[:space:]] ]]; then
    metric_line "$line"
    task_id=$(task_from_signal "$line")
    if [ -n "$task_id" ]; then
      append_runtime_note "$task_id" "$line"
    fi
    return 0
  fi

  if [[ "$line" =~ ^(TASK-[0-9]+)\ NEEDS_REVIEW:\ (.*)$ ]]; then
    task_id="${BASH_REMATCH[1]}"
    reason="${BASH_REMATCH[2]}"
    update_task_status "$task_id" "REVIEW" || true
    append_runtime_note "$task_id" "Executor requested review: $reason"
    dispatch_to_auditor "$task_id"
    metric_line "DISPATCH_AUDIT task=$task_id"
    set_state "ACTIVE_TASK" "$task_id"
    set_state "SYSTEM_STATUS" "review"
    return 0
  fi

  if [[ "$line" =~ ^(TASK-[0-9]+)\ DONE:\ (.*)$ ]]; then
    task_id="${BASH_REMATCH[1]}"
    reason="${BASH_REMATCH[2]}"
    update_task_status "$task_id" "DONE" || true
    append_runtime_note "$task_id" "Task completed without audit: $reason"
    metric_line "TASK_DONE task=$task_id"
    event "TASK_DONE task=$task_id"
    set_state "ACTIVE_TASK" "none"
    set_state "RETRY_COUNT" "0"
    set_state "SYSTEM_STATUS" "idle"
    return 0
  fi

  if [[ "$line" =~ ^(TASK-[0-9]+)\ BLOCKED:\ (.*)$ ]]; then
    task_id="${BASH_REMATCH[1]}"
    reason="${BASH_REMATCH[2]}"
    update_task_status "$task_id" "BLOCKED" || true
    append_runtime_note "$task_id" "Task blocked: $reason"
    metric_line "TASK_BLOCKED task=$task_id"
    event "TASK_BLOCKED task=$task_id reason=$reason"
    set_state "ACTIVE_TASK" "none"
    set_state "SYSTEM_STATUS" "blocked"
    return 0
  fi

  if [[ "$line" =~ ^(TASK-[0-9]+)\ AUDIT\ PASS$ ]]; then
    task_id="${BASH_REMATCH[1]}"
    update_task_status "$task_id" "DONE" || true
    append_runtime_note "$task_id" "Audit passed"
    metric_line "AUDIT_PASS task=$task_id"
    event "AUDIT_PASS task=$task_id"
    set_state "ACTIVE_TASK" "none"
    set_state "RETRY_COUNT" "0"
    set_state "SYSTEM_STATUS" "idle"
    return 0
  fi

  if [[ "$line" =~ ^(TASK-[0-9]+)\ AUDIT\ FAIL:\ (.*)$ ]]; then
    task_id="${BASH_REMATCH[1]}"
    reason="${BASH_REMATCH[2]}"
    retry_count=$(get_state "RETRY_COUNT" 2>/dev/null || printf '0')
    append_runtime_note "$task_id" "Audit failed: $reason"

    if [ "$retry_count" -lt 2 ]; then
      retry_count=$((retry_count + 1))
      set_state "RETRY_COUNT" "$retry_count"
      update_task_status "$task_id" "IN_PROGRESS" || true
      dispatch_to_executor "$task_id"
      metric_line "RETRY_DISPATCH task=$task_id retry=$retry_count"
      event "AUDIT_FAIL_RETRY task=$task_id retry=$retry_count reason=$reason"
      set_state "ACTIVE_TASK" "$task_id"
      set_state "SYSTEM_STATUS" "retry"
    else
      update_task_status "$task_id" "BLOCKED" || true
      metric_line "AUDIT_FAIL_FINAL task=$task_id"
      event "AUDIT_FAIL_FINAL task=$task_id reason=$reason"
      set_state "ACTIVE_TASK" "none"
      set_state "SYSTEM_STATUS" "blocked"
    fi
    return 0
  fi
}

process_signal_file() {
  local snapshot=""
  local line=""

  [ -s "$SIGNAL_FILE" ] || return 0

  snapshot="${SIGNAL_FILE}.snapshot.$$"
  mv "$SIGNAL_FILE" "$snapshot"
  : > "$SIGNAL_FILE"

  while IFS= read -r line || [ -n "$line" ]; do
    process_line "$line"
  done < "$snapshot"

  rm -f "$snapshot"
}

redispatch_orphaned_review() {
  local review_task=""
  review_task=$(first_task_with_status "REVIEW" 2>/dev/null || true)

  if [ -n "$review_task" ] && [ ! -s "$AUDITOR_INBOX" ]; then
    dispatch_to_auditor "$review_task"
    log "Redispatched orphaned review task=$review_task"
    metric_line "REDISPATCH_REVIEW task=$review_task"
  fi
}

dispatch_next_queued() {
  local active_task=""
  local queued_task=""

  active_task=$(get_state "ACTIVE_TASK" 2>/dev/null || printf 'none')
  if [ "$active_task" != "none" ]; then
    return 0
  fi

  [ ! -s "$EXECUTOR_INBOX" ] || return 0
  [ ! -s "$AUDITOR_INBOX" ] || return 0

  queued_task=$(first_task_with_status "QUEUED" 2>/dev/null || true)
  if [ -z "$queued_task" ]; then
    return 0
  fi

  dispatch_to_executor "$queued_task"
  update_task_status "$queued_task" "IN_PROGRESS" || true
  set_state "ACTIVE_TASK" "$queued_task"
  set_state "RETRY_COUNT" "0"
  set_state "SYSTEM_STATUS" "active"
  metric_line "DISPATCH task=$queued_task"
  log "Dispatched queued task=$queued_task"
}

stall_detection() {
  local active_task=""
  local task_file=""
  local task_state=""
  local task_age_min=0
  local now=0
  local modified=0
  local missing_component=""

  active_task=$(get_state "ACTIVE_TASK" 2>/dev/null || printf 'none')
  if [ "$active_task" = "none" ]; then
    return 0
  fi

  task_file=$(task_file_for "$active_task")
  [ -f "$task_file" ] || return 0
  task_state=$(task_status "$active_task")
  now=$(date +%s)
  modified=$(stat -c %Y "$task_file")
  task_age_min=$(((now - modified) / 60))

  if [ "$task_age_min" -lt "$STALL_WINDOW_MIN" ]; then
    return 0
  fi

  if [ "$task_state" = "REVIEW" ]; then
    if ! tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null; then
      missing_component="auditor_session_dead"
    fi
  else
    if ! tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null; then
      missing_component="executor_session_dead"
    fi
  fi

  if [ -z "$missing_component" ] && ! screen_session_running "$WATCHDOG_SCREEN"; then
    missing_component="watchdog_dead"
  fi

  if [ -n "$missing_component" ]; then
    append_runtime_note "$active_task" "STALL_DETECTED: $missing_component"
    metric_line "STALL_DETECTED task=$active_task reason=$missing_component"
    event "STALL_DETECTED task=$active_task reason=$missing_component"
    set_state "SYSTEM_STATUS" "stalled"
    log "Stall detected for task=$active_task reason=$missing_component"
  fi
}

set_state "LAST_COORDINATOR_CHECK" "$(utc_now)"
metric_line "COORDINATOR_CHECK"
log "Coordinator check started"

process_signal_file
redispatch_orphaned_review
dispatch_next_queued
stall_detection

printf '%s\n' "$(date +%s)" > "$STALL_CHECK_TS"
log "Coordinator check complete"
