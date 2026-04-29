#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime.sh
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

DRY_RUN=0
CLEAR=0
PACK_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --clear)
      CLEAR=1
      ;;
    *)
      PACK_ARG="$1"
      ;;
  esac
  shift
done

if [ "$CLEAR" -eq 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Would clear active target\n'
    exit 0
  fi

  set_state "ACTIVE_TARGET" "none"
  set_state "TARGET_ACTIVE_REPO" "none"
  set_state "TARGET_BASELINE_REPO" "none"
  set_state "TARGET_PACK" "none"
  set_state "LAST_TARGET_SWITCH" "$(utc_now)"
  printf 'Active target cleared\n'
  exit 0
fi

if [ -z "$PACK_ARG" ]; then
  printf 'Usage: %s [--dry-run] targets/<name>.md\n' "$0" >&2
  printf '       %s --clear\n' "$0" >&2
  exit 1
fi

PACK_PATH=$(resolve_local_path "$PACK_ARG")
TARGET_NAME=$(target_field "$PACK_PATH" "TARGET_NAME")
TARGET_TYPE=$(target_field "$PACK_PATH" "TARGET_TYPE")
ACTIVE_REPO=$(target_field "$PACK_PATH" "ACTIVE_REPO")
BASELINE_REPO=$(target_field "$PACK_PATH" "BASELINE_REPO")

[ -n "$TARGET_NAME" ] || { printf 'Missing TARGET_NAME in %s\n' "$PACK_PATH" >&2; exit 1; }
[ -n "$TARGET_TYPE" ] || { printf 'Missing TARGET_TYPE in %s\n' "$PACK_PATH" >&2; exit 1; }
[ -n "$ACTIVE_REPO" ] || { printf 'Missing ACTIVE_REPO in %s\n' "$PACK_PATH" >&2; exit 1; }
[ -n "$BASELINE_REPO" ] || BASELINE_REPO="none"

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Would activate target %s\n' "$TARGET_NAME"
  printf '  pack: %s\n' "$PACK_PATH"
  printf '  active repo: %s\n' "$ACTIVE_REPO"
  printf '  baseline repo: %s\n' "$BASELINE_REPO"
  exit 0
fi

set_state "ACTIVE_TARGET" "$TARGET_NAME"
set_state "TARGET_ACTIVE_REPO" "$ACTIVE_REPO"
set_state "TARGET_BASELINE_REPO" "$BASELINE_REPO"
set_state "TARGET_PACK" "$PACK_PATH"
set_state "LAST_TARGET_SWITCH" "$(utc_now)"

printf 'Activated target %s\n' "$TARGET_NAME"
