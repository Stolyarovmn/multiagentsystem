#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

DRY_RUN=0
TARGET_OVERRIDE=""
TITLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --target) shift; TARGET_OVERRIDE="${1:-}" ;;
    *) TITLE="${TITLE:+$TITLE }$1" ;;
  esac
  shift
done

[ -n "$TITLE" ] || { printf 'Usage: %s [--dry-run] [--target <name>] "Task title"\n' "$0" >&2; exit 1; }

last_num=$(find "$TASKS_DIR" -maxdepth 1 -type f -name 'TASK-*.md' | sed -n 's/.*TASK-\([0-9][0-9][0-9]*\)\.md/\1/p' | sort -n | tail -n 1)
last_num=${last_num:-0}
next_num=$((10#$last_num + 1))
task_id=$(printf 'TASK-%03d' "$next_num")
task_file="$TASKS_DIR/${task_id}.md"
target_name="${TARGET_OVERRIDE:-$(get_state ACTIVE_TARGET 2>/dev/null || printf none)}"
created_at=$(utc_now)
deadline=$(date -u -d '+1 day' '+%Y-%m-%d')

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Would create %s\n' "$task_file"
  printf '  target: %s\n' "$target_name"
  printf '  title: %s\n' "$TITLE"
  exit 0
fi

cat > "$task_file" <<EOF
# ${task_id}: ${TITLE}

STATUS QUEUED
CREATED ${created_at}
AUTHOR orchestrator
TARGET ${target_name}

## Goal

Fill in the exact task objective.

## Criteria

- [ ] Define the success condition clearly
- [ ] Keep continuity in the task file

## Context

- Active repo:
- Baseline repo:
- Related docs:
- Constraints:

## Dispatch Envelope

DISPATCH v2
TASK: ${task_id}
GOAL: ${TITLE}
CONSTRAINTS: no_credentials,requires_review
BUDGET_TOKENS: 4000
ARTIFACTS:
  - path: ${task_file}
    size_bytes: 0
    sha256: pending
REQUIRED_OUTPUT: {file_path, sha256, summary_1line, status}
DEADLINE: ${deadline}
END_DISPATCH

## Attempt Log

- none

## Audit Notes

- none
EOF

printf 'Created %s\n' "$task_file"
