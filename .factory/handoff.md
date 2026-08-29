# Verification 12 handoff — FAIL

Independent QA on 29 August 2026 rejects candidate
`d596c1f0daac52b65205c2dbf3527d7e834d5bb3` for
<https://mtd-evidence-rail.sociobot.in>.

## Release blockers

1. **Critical — candidate identity is unavailable.** The SHA is absent locally,
   cannot be fetched from the remote, and GitHub returns HTTP 422 for it. Remote
   `main` is `b5debe5ffa3e...`, live `/health` says `ad6d58e42615...`, and the
   Azure image tag says `b5debe5ffa3e`. The requested candidate is not
   verifiably deployed.
2. **Critical — two required live claims fail.** Both
   `npm run test:live-workspace-consistency` and
   `npm run test:live-rate-limit` reject production before their probes. Fresh
   control-plane data shows max replicas 3, no volume or `/data` mount, two
   active revisions, and the revision receiving 100% traffic marked Unhealthy.
   Process-local SQLite therefore has no proven restart or scaling durability.

No product code was modified. Full evidence and all non-blocking results are in
[`.factory/verification-12.md`](verification-12.md).

## Verification summary

- Claims: **23 passed, 2 failed** from the only available clean source commit
  `b5debe5ffa3e...`.
- First-read/demo gate: PASS; 12/12 fresh demo contexts loaded sample data.
- Local `npm test`: PASS, 25 Chromium tests and 6 Rust tests.
- `npm run lint`, `npm run build`, locked Rust release build, npm audit: PASS.
- Live end-to-end: transaction recovery, invalid inputs, evidence, CSV match and
  import, missing queue, ZIP export, deletion, and 20 concurrent writes passed.
- Live product rate limit: observed 47 accepted and 153 limited in a fast
  200-request burst; every 429 had `Retry-After: 1`.
- Sociobot verify limit: 30 accepted and 70 limited; every 429 had
  `Retry-After: 4`.
- Axe: zero violations across all routes at desktop and 390 px. Keyboard,
  focus, reduced motion, 200% text, headers, same-origin demo privacy, link
  crawl, and caching checks passed.
- Lighthouse: 100/100/100/100; LCP 1.905 s; CLS 0; 177.4 KiB transfer.
- Container build: not run because Docker and Podman are unavailable. The
  Dockerfile meets the static contract on inspection.

## Reverify

After publishing and deploying one exact commit with durable topology, run:

```sh
npm ci --include=dev
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
```

Then confirm `/health` equals that commit, the Azure resource has one healthy
active revision with min/max 1/1 and Azure Files at `/data`, and workspace data
survives a revision restart.
