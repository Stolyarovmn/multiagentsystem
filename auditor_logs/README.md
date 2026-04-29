# Auditor Logs

This directory holds the institutional memory of the runtime layer.

Committed examples should stay generic. Live `*.log` files are ignored.

## Files

- `events.log`
  Critical events: final audit failures, stalls, blocked escalations.

- `DISPUTE-NNN.md`
  Formal disputes and their resolutions.

## Rule

`coordinator.log` may be read as an operational log. Files in `auditor_logs/` are institutional memory that must not be silently discarded.
