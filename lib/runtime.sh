#!/bin/bash

MAS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

load_runtime_config() {
  EXECUTOR_SESSION="${EXECUTOR_SESSION:-executor-main}"
  AUDITOR_SESSION="${AUDITOR_SESSION:-auditor-main}"
  WATCHDOG_SCREEN="${WATCHDOG_SCREEN:-multiagentsystem-watchdog}"
  EXECUTOR_LAUNCH_CMD="${EXECUTOR_LAUNCH_CMD:-}"
  AUDITOR_LAUNCH_CMD="${AUDITOR_LAUNCH_CMD:-}"
  WATCHDOG_POLL_INTERVAL="${WATCHDOG_POLL_INTERVAL:-2}"
  ENABLE_CRON_SETUP="${ENABLE_CRON_SETUP:-0}"
  ENVELOPE_MAX_BYTES="${ENVELOPE_MAX_BYTES:-4096}"
  STARTUP_SEND_ROLE="${STARTUP_SEND_ROLE:-1}"
  DEFAULT_TARGET_PACK="${DEFAULT_TARGET_PACK:-}"

  CONFIG_FILE="$MAS_ROOT/config/agents.env"
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
  fi

  INBOX="$MAS_ROOT/inbox"
  OUTBOX="$MAS_ROOT/outbox"
  TASKS_DIR="$MAS_ROOT/tasks"
  TARGETS_DIR="$MAS_ROOT/targets"
  AUDITOR_LOGS_DIR="$MAS_ROOT/auditor_logs"
  MEMORY_DIR="$MAS_ROOT/memory"
  LOCKS_DIR="$MAS_ROOT/.locks"
  STATE_TEMPLATE="$MAS_ROOT/STATE.template.md"
  STATE_FILE="$MAS_ROOT/STATE.md"
  EXECUTOR_INBOX="$INBOX/for-executor.md"
  AUDITOR_INBOX="$INBOX/for-auditor.md"
  SIGNAL_FILE="$OUTBOX/for-orchestrator.md"
  METRICS_LOG="$OUTBOX/metrics.log"
  COORDINATOR_LOG="$OUTBOX/coordinator.log"
  WATCHDOG_LOG="$OUTBOX/watchdog.log"
  EVENTS_LOG="$AUDITOR_LOGS_DIR/events.log"
}

utc_now() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_now() {
  date -u '+%Y-%m-%d %H:%M:%S'
}

ensure_runtime_layout() {
  mkdir -p "$INBOX" "$OUTBOX" "$TASKS_DIR" "$TARGETS_DIR" "$AUDITOR_LOGS_DIR" "$MEMORY_DIR/context" "$LOCKS_DIR"
  touch "$EXECUTOR_INBOX" "$AUDITOR_INBOX" "$SIGNAL_FILE" "$METRICS_LOG" "$COORDINATOR_LOG" "$WATCHDOG_LOG" "$EVENTS_LOG"
  ensure_state_file
}

ensure_state_file() {
  if [ ! -f "$STATE_FILE" ]; then
    if [ -f "$STATE_TEMPLATE" ]; then
      cp "$STATE_TEMPLATE" "$STATE_FILE"
    else
      printf '# STATE — local operational state\n' > "$STATE_FILE"
    fi
  fi

  state_default "SYSTEM_STATUS" "bootstrap"
  state_default "ACTIVE_TASK" "none"
  state_default "RETRY_COUNT" "0"
  state_default "EXECUTOR_SESSION" "$EXECUTOR_SESSION"
  state_default "AUDITOR_SESSION" "$AUDITOR_SESSION"
  state_default "WATCHDOG_SCREEN" "$WATCHDOG_SCREEN"
  state_default "ACTIVE_TARGET" "none"
  state_default "TARGET_ACTIVE_REPO" "none"
  state_default "TARGET_BASELINE_REPO" "none"
  state_default "TARGET_PACK" "none"
  state_default "LAST_TARGET_SWITCH" "never"
  state_default "LAST_COORDINATOR_CHECK" "never"
  state_default "LAST_SIGNAL" "none"
}

state_default() {
  local field="$1"
  shift
  local value="$*"
  if ! grep -q "^${field} " "$STATE_FILE" 2>/dev/null; then
    printf '%s %s\n' "$field" "$value" >> "$STATE_FILE"
  fi
}

get_state() {
  local field="$1"
  awk -v field="$field" '$1 == field {sub($1 " ", ""); print; found=1} END {if (!found) exit 1}' "$STATE_FILE" 2>/dev/null
}

set_state() {
  local field="$1"
  shift
  local value="$*"
  local tmp
  tmp=$(mktemp)
  awk -v field="$field" '$1 != field && $1 != "UPDATED" {print}' "$STATE_FILE" > "$tmp"
  printf 'UPDATED %s\n' "$(utc_now)" >> "$tmp"
  printf '%s %s\n' "$field" "$value" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

append_log() {
  local path="$1"
  shift
  printf '[%s] %s\n' "$(log_now)" "$*" >> "$path"
}

resolve_local_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$MAS_ROOT" "$path" ;;
  esac
}

target_field() {
  local path="$1"
  local field="$2"
  awk -v field="$field" '$1 == field {sub($1 " ", ""); print; exit}' "$path"
}

task_file_for() {
  printf '%s/%s.md\n' "$TASKS_DIR" "$1"
}

update_task_status() {
  local task_id="$1"
  local new_status="$2"
  local task_file
  local tmp
  task_file=$(task_file_for "$task_id")
  [ -f "$task_file" ] || return 1
  tmp=$(mktemp)
  awk -v new_status="$new_status" 'BEGIN {done=0} !done && $1 == "STATUS" {$0 = "STATUS " new_status; done=1} {print}' "$task_file" > "$tmp"
  mv "$tmp" "$task_file"
}

append_runtime_note() {
  local task_id="$1"
  shift
  local task_file
  task_file=$(task_file_for "$task_id")
  [ -f "$task_file" ] || return 0
  {
    printf '\n- %s %s\n' "$(utc_now)" "$*"
  } >> "$task_file"
}

extract_dispatch() {
  local task_file="$1"
  awk '/^DISPATCH v2$/ {capture=1} capture {print} /^END_DISPATCH$/ {exit}' "$task_file"
}

validate_dispatch_file() {
  local file="$1"
  grep -q '^DISPATCH v2$' "$file" &&
    grep -q '^TASK: TASK-[0-9][0-9][0-9]*$' "$file" &&
    grep -q '^END_DISPATCH$' "$file"
}

detect_launch_cmd() {
  local role="$1"
  local configured=""
  local candidates=""
  local cmd=""
  if [ "$role" = "executor" ]; then
    configured="$EXECUTOR_LAUNCH_CMD"
    candidates="codex claude claude-code gemini gemini-cli"
  else
    configured="$AUDITOR_LAUNCH_CMD"
    candidates="gemini gemini-cli codex claude claude-code"
  fi
  [ -n "$configured" ] && { printf '%s\n' "$configured"; return 0; }
  for cmd in $candidates; do
    command -v "$cmd" >/dev/null 2>&1 && { printf '%s\n' "$cmd"; return 0; }
  done
  printf '\n'
}

screen_session_running() {
  screen -ls 2>/dev/null | grep -q "[[:space:]]${1}[[:space:]]"
}
