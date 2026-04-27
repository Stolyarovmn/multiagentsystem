# DISPATCH Specification

The runtime uses a compact typed envelope:

```text
DISPATCH v2
TASK: TASK-NNN
GOAL: one-line goal
CONSTRAINTS: no_credentials,requires_review
BUDGET_TOKENS: 4000
ARTIFACTS:
  - path: /absolute/or/workspace/path
    size_bytes: 123
    sha256: abcdef...
REQUIRED_OUTPUT: {file_path, sha256, summary_1line, status}
DEADLINE: YYYY-MM-DD
END_DISPATCH
```

Required fields:

- `TASK`
- `GOAL`
- `BUDGET_TOKENS`
- `ARTIFACTS`
- `REQUIRED_OUTPUT`
- `DEADLINE`

Useful constraints:

- `no_network`
- `readonly`
- `no_delete`
- `no_credentials`
- `requires_review`
- `max_files=N`
- `timeout=Ns`

Agents should reference artifact paths instead of embedding large file contents.
