#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/runtime.sh"
load_runtime_config
ensure_runtime_layout

printf 'status: ok\n'
printf 'root: %s\n' "$ROOT"
printf 'note: detailed automation report coverage is not enabled in v1\n'
