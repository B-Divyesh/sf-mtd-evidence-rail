# Verification 11 handoff — FAIL

Independent QA for work order `mtd-evidence-rail-verify-11` is complete.

- Candidate: `18eed3f094ec7fe6be543898646a2ab8acf61c90`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Decision: **FAIL — do not release**
- Full evidence: [verification-11.md](verification-11.md)

## Release blockers

1. Production is running revision `sf-mtd-evidence-rail--0000042` with scale
   1–3 (three replicas observed after load), no volume mount, no volume, and no
   `SQLITE_VFS`. New private and demo workspace reads returned 404 on 64/100 and
   65/100 fresh connections respectively. Eight of eight fresh one-click demos
   failed; retry could load the sample, but the next valid write returned 404.
2. The deployed API accepted all 200 same-client `POST /api/demo` requests. It
   returned no 429 or `Retry-After`, so the documented 40-request burst is not
   enforced across the active replicas.

These are fresh deployment findings. `/health` reports the exact candidate SHA,
and the live HTML/JS/CSS hashes match the clean candidate build.

## Verification summary

- `.factory/claims.json`: present; 23/25 exact claim commands passed from a
  detached clean worktree. `live-workspace-consistency` and
  `live-api-rate-limit` failed.
- First screen: PASS for what, who, and what to click. One-click demo outcome:
  FAIL.
- `npm ci`: PASS; 34 packages, 0 vulnerabilities.
- `npm test`: PASS; all 25 Chromium tests plus Rust/runtime/storage checks.
- `npm run lint`: PASS.
- `npm run build`: PASS; `dist/` produced.
- `cargo build --release --locked`: PASS.
- `npm audit --audit-level=low`: PASS.
- Live Axe: zero violations on landing, legal, 404, and recovered demo views.
- Mobile/keyboard/reduced motion: PASS outside the deployment data failure.
- Lighthouse: 100/100/100/100; LCP 1.7 s, CLS 0, transfer 177 KiB.
- Privacy request log: same-origin only through the attempted core demo flow.
- Security headers and immutable hashed-asset caching: PASS.
- Sociobot subscription verification throttling: 30 accepted / 70 HTTP 429,
  every 429 with `Retry-After: 4`.
- Docker image build: not run because Docker/Podman is unavailable in the
  verifier container; Vite and locked Rust release builds passed.

## How to reproduce

```sh
npm ci
npm test
npm run lint
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
```

Inspect the active Azure Container App to confirm `maxReplicas: 3`, null mounts
and volumes, and only `PORT=8080`. Apply the source-owned one-replica `/data`
topology, then rerun every live check and a browser write after demo recovery.

No product source code was changed during verification.
