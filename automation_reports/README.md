# Automation Reports

Automation reports record evidence for the autonomous operation cycle of `multiagentsystem`.

Reports are local by default. Commit only reusable examples or framework-level summaries.

## Streams

- `execution/`
  What agents actually did in the target repository.
- `audit/`
  How closely the work matched the framework rules.
- `improvements/`
  What changes were made to the framework itself after reading execution/audit reports.

## Naming Rule

Each run must create a new timestamped report rather than overwriting an existing one.

Report filenames must follow UTC format:

```text
YYYY-MM-DDTHHMMSSZ_<kind>.md
```

Example:

```text
2026-04-23T134009Z_audit.md
```

Files that do not match this timestamp pattern do not participate in coverage decisions and are treated as a filename warning.

## Coverage Check

From the repository root:

```bash
./automation-report-status.sh
./automation-report-status.sh --json
./automation-report-status.sh --strict
```

Coverage contract:

- the latest audit report must reference the latest execution report;
- the latest improvement report must reference the latest audit report;
- a no-op improvement must still leave a timestamped improvement report;
- non-canonical filenames must be surfaced via `malformed_reports`.

A `audit_lag` status means the improve loop must not pretend everything is closed: an audit loop over the new execution report must run first.
