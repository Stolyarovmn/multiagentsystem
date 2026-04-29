#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$ROOT/automation_reports"
IMPROVEMENTS_DIR="$REPORTS_DIR/improvements"
resolve_report_dir() {
  local primary="$1"
  local fallback="$2"

  if [ -d "$REPORTS_DIR/$primary" ]; then
    printf '%s/%s\n' "$REPORTS_DIR" "$primary"
    return 0
  fi

  if [ -d "$REPORTS_DIR/$fallback" ]; then
    printf '%s/%s\n' "$REPORTS_DIR" "$fallback"
    return 0
  fi

  printf '%s/%s\n' "$REPORTS_DIR" "$primary"
}

EXECUTION_DIR="$(resolve_report_dir "executions" "execution")"
AUDIT_DIR="$(resolve_report_dir "audits" "audit")"

json=0
strict=0

usage() {
  cat <<'USAGE'
Usage: automation-report-status.sh [--json] [--strict]

Checks whether the automation report streams are keeping up:
  execution -> audit -> improvements

Default output is human-readable and exits 0 for status reporting.
Use --strict to exit 1 when coverage is stale or report filenames are malformed.
Use --json for automation-friendly output.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --json)
      json=1
      ;;
    --strict)
      strict=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for dir in "$EXECUTION_DIR" "$AUDIT_DIR" "$IMPROVEMENTS_DIR"; do
  if [ ! -d "$dir" ]; then
    printf 'Missing report directory: %s\n' "$dir" >&2
    exit 1
  fi
done

standard_reports() {
  local dir="$1"
  local suffix="$2"

  find "$dir" -maxdepth 1 -type f -name "*_${suffix}.md" 2>/dev/null | sort
}

canonical_reports() {
  local dir="$1"
  local suffix="$2"
  local file base

  standard_reports "$dir" "$suffix" |
    while IFS= read -r file; do
      base="$(basename "$file")"
      case "$base" in
        ????-??-??T??????Z_"$suffix".md)
          printf '%s\n' "$file"
          ;;
      esac
    done
}

malformed_reports() {
  local dir="$1"
  local suffix="$2"
  local file base

  standard_reports "$dir" "$suffix" |
    while IFS= read -r file; do
      base="$(basename "$file")"
      case "$base" in
        ????-??-??T??????Z_"$suffix".md)
          ;;
        *)
          printf '%s\n' "$file"
          ;;
      esac
    done |
    sort
}

latest_report() {
  local dir="$1"
  local suffix="$2"
  local latest=""
  local _mtime=""
  local path=""

  while IFS=$'\t' read -r _mtime path; do
    latest="$path"
  done < <(find "$dir" -maxdepth 1 -type f -name "*_${suffix}.md" -printf '%T@\t%p\n' 2>/dev/null | sort -n)

  printf '%s\n' "$latest"
}

report_count() {
  local dir="$1"
  local suffix="$2"

  standard_reports "$dir" "$suffix" | wc -l | tr -d ' '
}

report_prefix() {
  local path="$1"
  local base

  if [ -z "$path" ]; then
    printf ''
    return
  fi

  base="$(basename "$path")"
  printf '%s' "${base:0:18}"
}

report_mtime() {
  local path="$1"

  if [ -z "$path" ] || [ ! -f "$path" ]; then
    printf '0\n'
    return
  fi

  stat -c '%Y' "$path"
}

count_after_mtime() {
  local dir="$1"
  local suffix="$2"
  local reference_mtime="$3"
  local count=0
  local file file_mtime

  if [ -z "$reference_mtime" ] || [ "$reference_mtime" = "0" ]; then
    report_count "$dir" "$suffix"
    return
  fi

  while IFS= read -r file; do
    file_mtime=$(report_mtime "$file")
    if [ "$file_mtime" -gt "$reference_mtime" ]; then
      count=$((count + 1))
    fi
  done < <(standard_reports "$dir" "$suffix")

  printf '%s\n' "$count"
}

extract_referenced_report() {
  local path="$1"
  local suffix="$2"

  if [ -z "$path" ] || [ ! -f "$path" ]; then
    printf ''
    return
  fi

  grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}Z_${suffix}[.]md" "$path" | tail -n 1 || true
}

malformed_report_basenames() {
  {
    malformed_reports "$EXECUTION_DIR" "execution"
    malformed_reports "$AUDIT_DIR" "audit"
    malformed_reports "$IMPROVEMENTS_DIR" "improvement"
  } | while IFS= read -r file; do
    [ -n "$file" ] && basename "$file"
  done
}

json_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '"%s"' "$value"
}

latest_execution="$(latest_report "$EXECUTION_DIR" "execution")"
latest_audit="$(latest_report "$AUDIT_DIR" "audit")"
latest_improvement="$(latest_report "$IMPROVEMENTS_DIR" "improvement")"

latest_execution_base="$(basename "${latest_execution:-}")"
latest_audit_base="$(basename "${latest_audit:-}")"
latest_improvement_base="$(basename "${latest_improvement:-}")"

latest_execution_prefix="$(report_prefix "$latest_execution")"
latest_audit_prefix="$(report_prefix "$latest_audit")"
latest_improvement_prefix="$(report_prefix "$latest_improvement")"
latest_execution_mtime="$(report_mtime "$latest_execution")"
latest_audit_mtime="$(report_mtime "$latest_audit")"
latest_improvement_mtime="$(report_mtime "$latest_improvement")"

execution_count="$(report_count "$EXECUTION_DIR" "execution")"
audit_count="$(report_count "$AUDIT_DIR" "audit")"
improvement_count="$(report_count "$IMPROVEMENTS_DIR" "improvement")"
malformed_report_count="$(malformed_report_basenames | wc -l | tr -d ' ')"
malformed_report_files="$(malformed_report_basenames | paste -sd ',' -)"

audited_execution_base="$(extract_referenced_report "$latest_audit" "execution")"
improved_audit_base="$(extract_referenced_report "$latest_improvement" "audit")"

execution_after_audit="$(count_after_mtime "$EXECUTION_DIR" "execution" "$latest_audit_mtime")"
audit_after_improvement="$(count_after_mtime "$AUDIT_DIR" "audit" "$latest_improvement_mtime")"

status="ok"
if [ "$execution_count" -eq 0 ]; then
  status="no_execution_reports"
elif [ "$audit_count" -eq 0 ]; then
  status="audit_missing"
elif [ "$latest_audit_mtime" -lt "$latest_execution_mtime" ]; then
  status="audit_lag"
elif [ "$improvement_count" -eq 0 ]; then
  status="improvement_missing"
elif [ "$latest_improvement_mtime" -lt "$latest_audit_mtime" ]; then
  status="improvement_lag"
fi

if [ "$json" -eq 1 ]; then
  printf '{\n'
  printf '  "status": '
  json_string "$status"
  printf ',\n'
  printf '  "latest_execution": '
  json_string "$latest_execution_base"
  printf ',\n'
  printf '  "latest_audit": '
  json_string "$latest_audit_base"
  printf ',\n'
  printf '  "latest_improvement": '
  json_string "$latest_improvement_base"
  printf ',\n'
  printf '  "audited_execution": '
  json_string "$audited_execution_base"
  printf ',\n'
  printf '  "improved_audit": '
  json_string "$improved_audit_base"
  printf ',\n'
  printf '  "execution_reports": %s,\n' "$execution_count"
  printf '  "audit_reports": %s,\n' "$audit_count"
  printf '  "improvement_reports": %s,\n' "$improvement_count"
  printf '  "malformed_reports": %s,\n' "$malformed_report_count"
  printf '  "malformed_report_files": '
  json_string "$malformed_report_files"
  printf ',\n'
  printf '  "execution_reports_after_latest_audit": %s,\n' "$execution_after_audit"
  printf '  "audit_reports_after_latest_improvement": %s\n' "$audit_after_improvement"
  printf '}\n'
else
  printf 'automation-report-status\n'
  printf 'status: %s\n' "$status"
  printf 'latest_execution: %s\n' "${latest_execution_base:-none}"
  printf 'latest_audit: %s\n' "${latest_audit_base:-none}"
  printf 'latest_improvement: %s\n' "${latest_improvement_base:-none}"
  printf 'audited_execution: %s\n' "${audited_execution_base:-none}"
  printf 'improved_audit: %s\n' "${improved_audit_base:-none}"
  printf 'execution_reports: %s\n' "$execution_count"
  printf 'audit_reports: %s\n' "$audit_count"
  printf 'improvement_reports: %s\n' "$improvement_count"
  printf 'malformed_reports: %s\n' "$malformed_report_count"
  printf 'malformed_report_files: %s\n' "${malformed_report_files:-none}"
  printf 'execution_reports_after_latest_audit: %s\n' "$execution_after_audit"
  printf 'audit_reports_after_latest_improvement: %s\n' "$audit_after_improvement"
fi

if [ "$strict" -eq 1 ] && [ "$status" != "ok" ]; then
  exit 1
fi
