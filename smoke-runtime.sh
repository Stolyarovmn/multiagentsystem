#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

for path in \
  "$ROOT/AGENTS.md" \
  "$ROOT/MANIFEST.md" \
  "$ROOT/ARCHITECTURE.md" \
  "$ROOT/OPERATIONS.md" \
  "$ROOT/PRINCIPLES.md" \
  "$ROOT/DISPATCH_SPEC.md" \
  "$ROOT/DISPUTE.md" \
  "$ROOT/STATE.template.md" \
  "$ROOT/STATE.md" \
  "$ROOT/tasks/TASK_TEMPLATE.md" \
  "$ROOT/targets/TARGET_TEMPLATE.md" \
  "$ROOT/tests/fixtures/targets/example-target.md"; do
  [ -e "$path" ] || { printf 'Missing required file: %s\n' "$path" >&2; exit 1; }
done

for script in "$ROOT"/*.sh "$ROOT/lib/runtime.sh"; do
  bash -n "$script"
done

"$ROOT/start.sh" --dry-run >/dev/null
"$ROOT/set-target.sh" --dry-run "$ROOT/tests/fixtures/targets/example-target.md" >/dev/null
"$ROOT/new-task.sh" --dry-run "smoke task" >/dev/null
"$ROOT/ws-status.sh" >/dev/null

printf 'smoke-runtime: OK\n'
