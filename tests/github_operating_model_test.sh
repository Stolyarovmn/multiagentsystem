#!/usr/bin/env bash
set -euo pipefail

required_files=(
  ".github/ISSUE_TEMPLATE/task.yml"
  ".github/ISSUE_TEMPLATE/dispute.yml"
  ".github/ISSUE_TEMPLATE/process-change.yml"
  ".github/ISSUE_TEMPLATE/blocker-escalation.yml"
  ".github/ISSUE_TEMPLATE/config.yml"
  ".github/PULL_REQUEST_TEMPLATE.md"
  ".github/CODEOWNERS"
  ".github/workflows/pages.yml"
  ".github/workflows/process-hygiene.yml"
  ".github/workflows/pr-checks.yml"
  "docs/github-operating-model.md"
  "docs/github/labels-schema.md"
  "docs/github/project-fields.md"
  "docs/state/github-control-plane-state.md"
  "docs/memory/README.md"
  "docs/index.html"
  "docs/app.js"
  "docs/styles.css"
  "scripts/build_pages_data.py"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || {
    echo "missing file: $path"
    exit 1
  }
done

grep -q "GitHub-native" docs/github-operating-model.md || {
  echo "missing operating model wording"
  exit 1
}

grep -q "Status" docs/github/project-fields.md || {
  echo "missing project status field doc"
  exit 1
}

grep -qi "linked task" .github/PULL_REQUEST_TEMPLATE.md || {
  echo "missing linked task section"
  exit 1
}

grep -q "workflow_dispatch" .github/workflows/pages.yml || {
  echo "missing manual pages trigger"
  exit 1
}

grep -qi "process hygiene" .github/workflows/process-hygiene.yml || {
  echo "missing process hygiene workflow name"
  exit 1
}

grep -q "Tasks" docs/index.html || {
  echo "missing dashboard tasks section"
  exit 1
}

echo "github operating model files present"
