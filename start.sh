#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '[%s] %s\n' "$(log_now)" "$*"
}

describe_session() {
  local role="$1"
  local session="$2"
  local cmd="$3"

  if [ -n "$cmd" ]; then
    log "$role session: $session (launch: $cmd)"
  else
    log "$role session: $session (launch: manual shell)"
  fi
}

seed_or_explain_role() {
  local session="$1"
  local role_file="$2"
  local role_name="$3"
  local launch_cmd="$4"
  local tmp=""

  if [ -z "$launch_cmd" ]; then
    tmux send-keys -t "$session" "printf '%s\n' 'Session ready. Launch the ${role_name} CLI manually if needed. Role pack: ${role_file}'" Enter
    return 0
  fi

  if [ "$STARTUP_SEND_ROLE" != "1" ] || [ ! -f "$role_file" ]; then
    return 0
  fi

  tmp=$(mktemp)
  {
    printf 'Startup role context for %s:\n\n' "$role_name"
    cat "$role_file"
    printf '\n'
  } > "$tmp"

  tmux load-buffer -b "mas-startup-$$" "$tmp"
  tmux paste-buffer -b "mas-startup-$$" -t "$session"
  tmux send-keys -t "$session" Enter
  tmux delete-buffer -b "mas-startup-$$" >/dev/null 2>&1 || true
  rm -f "$tmp"
}

start_tmux_session() {
  local session="$1"
  local launch_cmd="$2"
  local role_file="$3"
  local role_name="$4"

  if tmux has-session -t "$session" 2>/dev/null; then
    log "Reusing tmux session $session"
    return 0
  fi

  tmux new-session -d -s "$session" -c "$ROOT"
  sleep 1

  if [ -n "$launch_cmd" ]; then
    tmux send-keys -t "$session" "$launch_cmd" Enter
    sleep 2
  fi

  seed_or_explain_role "$session" "$role_file" "$role_name" "$launch_cmd"
  log "Started tmux session $session"
}

ensure_cron() {
  local cron_line=""
  local tmp=""
  local escaped_root=""

  [ "$ENABLE_CRON_SETUP" = "1" ] || return 0

  escaped_root=$(printf '%q' "$ROOT")
  cron_line="*/${COORDINATOR_INTERVAL_MIN} * * * * cd ${escaped_root} && ${escaped_root}/coordinator.sh >> ${escaped_root}/outbox/coordinator.log 2>&1"

  if crontab -l 2>/dev/null | grep -Fq "$ROOT/coordinator.sh"; then
    log "Cron entry already present"
    return 0
  fi

  tmp=$(mktemp)
  crontab -l 2>/dev/null > "$tmp" || true
  printf '%s\n' "$cron_line" >> "$tmp"
  crontab "$tmp"
  rm -f "$tmp"
  log "Installed coordinator cron entry"
}

start_watchdog() {
  if screen_session_running "$WATCHDOG_SCREEN"; then
    log "Reusing watchdog screen $WATCHDOG_SCREEN"
    return 0
  fi

  screen -dmS "$WATCHDOG_SCREEN" "$ROOT/watchdog.sh"
  sleep 1
  log "Started watchdog screen $WATCHDOG_SCREEN"
}

apply_default_target_pack() {
  local active_target=""
  active_target=$(get_state "ACTIVE_TARGET" 2>/dev/null || printf 'none')

  if [ -n "$DEFAULT_TARGET_PACK" ] && [ "$active_target" = "none" ]; then
    "$ROOT/set-target.sh" "$DEFAULT_TARGET_PACK" >/dev/null
    log "Activated default target pack $DEFAULT_TARGET_PACK"
  fi
}

for cmd in bash tmux screen crontab sed awk grep mktemp; do
  if ! need_cmd "$cmd"; then
    log "Missing required command: $cmd"
    exit 1
  fi
done

executor_cmd=$(detect_launch_cmd "executor")
auditor_cmd=$(detect_launch_cmd "auditor")

describe_session "executor" "$EXECUTOR_SESSION" "$executor_cmd"
describe_session "auditor" "$AUDITOR_SESSION" "$auditor_cmd"
log "watchdog screen: $WATCHDOG_SCREEN"
log "default target pack: ${DEFAULT_TARGET_PACK:-none}"

if [ "$DRY_RUN" -eq 1 ]; then
  log "Dry run only. No files or sessions were changed."
  exit 0
fi

ensure_runtime_layout
set_state "EXECUTOR_SESSION" "$EXECUTOR_SESSION"
set_state "AUDITOR_SESSION" "$AUDITOR_SESSION"
set_state "WATCHDOG_SCREEN" "$WATCHDOG_SCREEN"
set_state "SYSTEM_STATUS" "ready"

start_tmux_session "$EXECUTOR_SESSION" "$executor_cmd" "$EXECUTOR_ROLE_FILE" "executor"
start_tmux_session "$AUDITOR_SESSION" "$auditor_cmd" "$AUDITOR_ROLE_FILE" "auditor"
start_watchdog
ensure_cron
apply_default_target_pack

log "Startup complete"
log "Run ./ws-status.sh to inspect the runtime"
