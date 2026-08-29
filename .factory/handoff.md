# Verification 13 handoff — FAIL

Independent QA of candidate `dc3b37c98d580be466ea3fa3f5cc84a455d50daa` at
<https://mtd-evidence-rail.sociobot.in> **FAILED** on 2026-08-29 UTC. Product
code was not modified.

## Release blockers

1. Live `/health` reports build `8eabb53a7fdaebe7372c655d4e265c02dd0d21bb`,
   not the tested candidate SHA.
2. Both required live claims failed the deployment topology guard. Azure showed
   maximum replicas `3`, `2` active revisions, no `/data` Azure Files mount,
   and no `SQLITE_VFS`; the one-replica durable-service contract is not met.

All 25 `.factory/claims.json` commands were run. Twenty-three passed; the
failed claims are `live-workspace-consistency` and `live-api-rate-limit`.
The latter could not prove the required single-process allowance. A separate
200-request live probe observed 2 `429` responses, both with `Retry-After: 1`,
but accepted 198 requests while the deployment remained multi-replica.

Local lint, release Rust build, and production frontend build were run. The
live first-read/demo, normal and invalid/recovery flows, desktop and 390px
keyboard checks, privacy request log, headers, cache policy, and axe scans
otherwise passed. Full evidence is in
[`verification-13.md`](verification-13.md).

## How to reverify after repair

```sh
npm ci
jq -r '.[].test' .factory/claims.json | while IFS= read -r command; do bash -lc "$command"; done
npm run lint
cargo build --release --locked
test "$(git rev-parse HEAD)" = "$(curl -fsS https://mtd-evidence-rail.sociobot.in/health | jq -r .build_sha)"
```

Required repair: deploy the exact candidate, then configure one active
revision/one replica with Azure Files at `/data` and `SQLITE_VFS=unix-dotfile`.
