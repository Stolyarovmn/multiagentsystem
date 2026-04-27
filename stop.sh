#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

if command -v tmux >/dev/null 2>&1; then
  tmux has-session -t "$EXECUTOR_SESSION" 2>/dev/null && tmux kill-session -t "$EXECUTOR_SESSION"
  tmux has-session -t "$AUDITOR_SESSION" 2>/dev/null && tmux kill-session -t "$AUDITOR_SESSION"
fi

set_state SYSTEM_STATUS stopped
printf 'runtime stopped\n'
