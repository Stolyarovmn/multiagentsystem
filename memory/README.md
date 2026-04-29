# Memory

`memory/` stores short derived summaries that help agents recover context faster.

Use this directory for durable framework memory that is intentionally promoted into git.

Local target-specific memory should use ignored files such as `memory/context/*.local.md`.

This is a useful layer, but not the primary canon.

## Priority Order on Conflict

1. Canonical docs in the repository root;
2. Active target-pack;
3. Derived memory in this directory.
