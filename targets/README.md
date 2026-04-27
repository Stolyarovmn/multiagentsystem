# Target Packs

Target-packs connect external repositories to this framework without copying their history into this repository.

Tracked files:

- `targets/TARGET_TEMPLATE.md`
- generic examples only if intentionally added

Local files:

- `targets/*.local.md`

Local target-packs are ignored by git because they may contain machine-specific absolute paths.

## Required Header

```text
TARGET_NAME example
TARGET_TYPE repo
ACTIVE_REPO /absolute/path/to/repo
BASELINE_REPO none
```

## Required Sections

- `Purpose`
- `Active Repo`
- `Baseline / Reference`
- `Read-Order For Fresh Agent`
- `Recovery Anchors`
- `Canon Rules`
