#!/bin/bash

MAS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

load_runtime_config() {
  EXECUTOR_SESSION="${EXECUTOR_SESSION:-executor-main}"
  AUDITOR_SESSION="${AUDITOR_SESSION:-auditor-main}"
  WATCHDOG_SCREEN="${WATCHDOG_SCREEN:-mas-watchdog}"
  EXECUTOR_LAUNCH_CMD="${EXECUTOR_LAUNCH_CMD:-}"
  AUDITOR_LAUNCH_CMD="${AUDITOR_LAUNCH_CMD:-}"
  WATCHDOG_POLL_INTERVAL="${WATCHDOG_POLL_INTERVAL:-2}"
  COORDINATOR_INTERVAL_MIN="${COORDINATOR_INTERVAL_MIN:-3}"
  ENABLE_CRON_SETUP="${ENABLE_CRON_SETUP:-1}"
  ENVELOPE_MAX_BYTES="${ENVELOPE_MAX_BYTES:-4096}"
  STALL_WINDOW_MIN="${STALL_WINDOW_MIN:-12}"
  STARTUP_SEND_ROLE="${STARTUP_SEND_ROLE:-0}"
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
  STATE_FILE="$MAS_ROOT/STATE.md"
  EXECUTOR_INBOX="$INBOX/for-executor.md"
  AUDITOR_INBOX="$INBOX/for-auditor.md"
  SIGNAL_FILE="$OUTBOX/for-orchestrator.md"
  METRICS_LOG="$OUTBOX/metrics.log"
  COORDINATOR_LOG="$OUTBOX/coordinator.log"
  WATCHDOG_LOG="$OUTBOX/watchdog.log"
  EVENTS_LOG="$AUDITOR_LOGS_DIR/events.log"
  STALL_CHECK_TS="$OUTBOX/stall_check_ts.txt"
  EXECUTOR_ROLE_FILE="${EXECUTOR_ROLE_FILE:-$MAS_ROOT/.claude/agents/executor/agent.md}"
  AUDITOR_ROLE_FILE="${AUDITOR_ROLE_FILE:-$MAS_ROOT/.claude/agents/auditor/agent.md}"
  ORCHESTRATOR_ROLE_FILE="${ORCHESTRATOR_ROLE_FILE:-$MAS_ROOT/.claude/agents/orchestrator/agent.md}"
}

utc_now() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_now() {
  date -u '+%Y-%m-%d %H:%M:%S'
}

append_log() {
  local path="$1"
  shift
  printf '[%s] %s\n' "$(log_now)" "$*" >> "$path"
}

rotate_log_lines() {
  local path="$1"
  local keep="$2"

  if [ -f "$path" ]; then
    local line_count
    line_count=$(wc -l < "$path")
    if [ "$line_count" -gt "$keep" ]; then
      tail -n "$keep" "$path" > "${path}.tmp"
      mv "${path}.tmp" "$path"
    fi
  fi
}

metric_line() {
  printf '%s %s\n' "$(log_now)" "$*" >> "$METRICS_LOG"
  rotate_log_lines "$METRICS_LOG" 120
}

ensure_runtime_layout() {
  mkdir -p \
    "$INBOX" \
    "$OUTBOX" \
    "$TASKS_DIR" \
    "$TARGETS_DIR" \
    "$AUDITOR_LOGS_DIR" \
    "$MEMORY_DIR/context" \
    "$LOCKS_DIR"

  touch "$EXECUTOR_INBOX" "$AUDITOR_INBOX" "$SIGNAL_FILE" "$METRICS_LOG" "$COORDINATOR_LOG" "$WATCHDOG_LOG" "$EVENTS_LOG"
  ensure_state_file
}

ensure_state_file() {
  if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" <<'EOF'
# STATE — live operational state

UPDATED 2026-04-23T00:00:00Z
SYSTEM_STATUS bootstrap
ACTIVE_TASK none
RETRY_COUNT 0

EXECUTOR_SESSION executor-main
AUDITOR_SESSION auditor-main
WATCHDOG_SCREEN mas-watchdog

ACTIVE_TARGET none
TARGET_ACTIVE_REPO none
TARGET_BASELINE_REPO none
TARGET_PACK none
LAST_TARGET_SWITCH never

LAST_COORDINATOR_CHECK never
LAST_SIGNAL none
EOF
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

lock_path_for() {
  local target="$1"
  printf '%s/%s.lock\n' "$LOCKS_DIR" "$(basename "$target")"
}

reserve_file() {
  local target="$1"
  local lock_path
  lock_path=$(lock_path_for "$target")
  local attempt=0

  while ! mkdir "$lock_path" 2>/dev/null; do
    sleep 0.2
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 50 ]; then
      return 1
    fi
  done
}

release_file() {
  local target="$1"
  local lock_path
  lock_path=$(lock_path_for "$target")
  rmdir "$lock_path" 2>/dev/null || true
}

get_state() {
  local field="$1"
  if [ -f "$STATE_FILE" ]; then
    awk -v field="$field" '$1 == field {sub($1 " ", ""); print; found=1} END {if (!found) exit 1}' "$STATE_FILE" 2>/dev/null
  fi
}

set_state() {
  local field="$1"
  shift
  local value="$*"
  local tmp

  reserve_file "$STATE_FILE" || return 1

  tmp=$(mktemp)
  if [ -f "$STATE_FILE" ]; then
    awk -v field="$field" '$1 != field && $1 != "UPDATED" {print}' "$STATE_FILE" > "$tmp"
  else
    printf '# STATE — live operational state\n' > "$tmp"
  fi

  printf 'UPDATED %s\n' "$(utc_now)" >> "$tmp"
  printf '%s %s\n' "$field" "$value" >> "$tmp"
  mv "$tmp" "$STATE_FILE"

  release_file "$STATE_FILE"
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

  if [ -n "$configured" ]; then
    printf '%s\n' "$configured"
    return 0
  fi

  for cmd in $candidates; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf '%s\n' "$cmd"
      return 0
    fi
  done

  printf '\n'
}

screen_session_running() {
  local name="$1"
  screen -ls 2>/dev/null | grep -Eq "[[:space:]][0-9]+\\.${name}([[:space:]]|$)"
}

task_file_for() {
  local task_id="$1"
  printf '%s/%s.md\n' "$TASKS_DIR" "$task_id"
}

task_status() {
  local task_id="$1"
  local task_file
  task_file=$(task_file_for "$task_id")
  awk '$1 == "STATUS" {print $2; exit}' "$task_file" 2>/dev/null
}

update_task_status() {
  local task_id="$1"
  local new_status="$2"
  local task_file
  local tmp

  task_file=$(task_file_for "$task_id")
  [ -f "$task_file" ] || return 1

  reserve_file "$task_file" || return 1
  tmp=$(mktemp)
  awk -v new_status="$new_status" '
    BEGIN {done=0}
    !done && $1 == "STATUS" {$0 = "STATUS " new_status; done=1}
    {print}
  ' "$task_file" > "$tmp"
  mv "$tmp" "$task_file"
  release_file "$task_file"
}

append_runtime_note() {
  local task_id="$1"
  shift
  local note="$*"
  local task_file

  task_file=$(task_file_for "$task_id")
  [ -f "$task_file" ] || return 0

  reserve_file "$task_file" || return 1
  if ! grep -q '^## Runtime Notes$' "$task_file" 2>/dev/null; then
    printf '\n## Runtime Notes\n' >> "$task_file"
  fi
  printf -- '- [%s] %s\n' "$(utc_now)" "$note" >> "$task_file"
  release_file "$task_file"
}

extract_dispatch_from_task() {
  local task_id="$1"
  local dest="$2"
  local task_file

  task_file=$(task_file_for "$task_id")
  [ -f "$task_file" ] || return 1
  sed -n '/^DISPATCH v2$/,/^END_DISPATCH$/p' "$task_file" > "$dest"
}

validate_dispatch_file() {
  local file="$1"
  [ -s "$file" ] || return 1
  grep -q '^DISPATCH v2$' "$file" || return 1
  grep -q '^TASK: TASK-' "$file" || return 1
  grep -q '^GOAL: ' "$file" || return 1
  grep -q '^BUDGET_TOKENS: ' "$file" || return 1
  grep -q '^REQUIRED_OUTPUT: ' "$file" || return 1
  grep -q '^DEADLINE: ' "$file" || return 1
  grep -q '^END_DISPATCH$' "$file" || return 1
}

dispatch_task_to_role() {
  local task_id="$1"
  local role="$2"
  local dest=""

  if [ "$role" = "executor" ]; then
    dest="$EXECUTOR_INBOX"
  else
    dest="$AUDITOR_INBOX"
  fi

  extract_dispatch_from_task "$task_id" "$dest" || return 1
  validate_dispatch_file "$dest"
}

first_task_with_status() {
  local wanted="$1"
  local task_file=""

  while IFS= read -r task_file; do
    if grep -q "^STATUS ${wanted}$" "$task_file" 2>/dev/null; then
      basename "$task_file" .md
      return 0
    fi
  done < <(find "$TASKS_DIR" -maxdepth 1 -type f -name 'TASK-*.md' | sort)

  return 1
}

resolve_local_path() {
  local raw="$1"
  if [ -f "$raw" ]; then
    printf '%s/%s\n' "$(cd "$(dirname "$raw")" && pwd)" "$(basename "$raw")"
  elif [ -f "$MAS_ROOT/$raw" ]; then
    printf '%s/%s\n' "$(cd "$(dirname "$MAS_ROOT/$raw")" && pwd)" "$(basename "$raw")"
  else
    return 1
  fi
}

target_field() {
  local path="$1"
  local key="$2"
  awk -v key="$key" '$1 == key {sub($1 " ", ""); print; exit}' "$path"
}
