#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

DRY_RUN=0
TARGET_OVERRIDE=""
TITLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --target)
      shift
      TARGET_OVERRIDE="${1:-}"
      ;;
    *)
      if [ -z "$TITLE" ]; then
        TITLE="$1"
      else
        TITLE="$TITLE $1"
      fi
      ;;
  esac
  shift
done

if [ -z "$TITLE" ]; then
  printf 'Usage: %s [--dry-run] [--target <name>] "Task title"\n' "$0" >&2
  exit 1
fi

last_num=$(find "$TASKS_DIR" -maxdepth 1 -type f -name 'TASK-*.md' | sed -n 's/.*TASK-\([0-9][0-9][0-9]*\)\.md/\1/p' | sort -n | tail -n 1)
last_num=${last_num:-0}
next_num=$((10#$last_num + 1))
task_id=$(printf 'TASK-%03d' "$next_num")
task_file="$TASKS_DIR/${task_id}.md"
target_name="${TARGET_OVERRIDE:-$(get_state "ACTIVE_TARGET" 2>/dev/null || printf 'none')}"
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
    size_bytes: 0000
    sha256: pending
REQUIRED_OUTPUT: {file_path, sha256, summary_1line, status}
DEADLINE: ${deadline}
END_DISPATCH

## Attempt Log

### v1

- started:
- result:
- note:

## Audit Notes

- none
EOF

for _ in 1 2 3; do
  size_bytes=$(wc -c < "$task_file")
  sha=$(sha256sum "$task_file" | awk '{print $1}')
  sed -i "s/size_bytes: [0-9][0-9]*/size_bytes: ${size_bytes}/" "$task_file"
  sed -i "s/sha256: .*/sha256: ${sha}/" "$task_file"
done

printf '%s\n' "$task_file"
