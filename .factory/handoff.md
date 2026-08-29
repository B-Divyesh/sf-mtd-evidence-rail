# Repair 10 handoff — PASS

Independent verification 13 rejected candidate `dc3b37c98d5` because the
candidate's mountless work-order revision could not start. Azure kept serving
build `8eabb53a7fda`, with two active revisions, maximum replicas `3`, no
Azure Files mount, and no `SQLITE_VFS`. Both live claims therefore stopped at
their topology guard.

## What changed

- `scripts/assert-live-topology.sh` now treats topology and identity as one
  release invariant. It requires repository `HEAD`, `/health`, the ready
  revision image, latest and ready revision names, active revision count,
  replica count, `/data` mount, Azure Files volume, and SQLite VFS to agree.
- `scripts/test-live-release-guard.sh` reproduces the verifier's exact
  candidate/older-ready two-revision state. It also proves that a safe topology
  cannot hide stale health identity, and that only the complete safe state
  passes.
- `npm run test:live-release` is a declared claim command. The workspace and
  rate-limit live claims use the same strengthened release guard.
- `npm run verify:live-topology` now defaults its expected identity to the
  checked-out commit instead of silently accepting any non-empty build SHA.

The product remains a Rust/Axum backend serving the Vite/TypeScript frontend
from one container on `PORT`. No researched behavior, design, billing path, or
data format changed.

## Clean local evidence

| Check | Result |
| --- | --- |
| `npm ci --include=dev` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — 6 Rust tests, runtime/storage/topology gates, and 25 Chromium tests |
| `npm run lint` | PASS — TypeScript, rustfmt, and Clippy with warnings denied |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |
| `npm run test:deployment-topology` | PASS — exact verification 13 state rejected |
| All 26 `.factory/claims.json` commands from fresh clone | PASS; the final live limiter command passed on isolated retry after two transient ingress timeouts in the aggregate run |
| ACR multi-stage Docker build | PASS — non-root runtime image built from `rust:1-slim` |

The production output is 33,893 bytes JavaScript (11,046 gzip), 18,132 bytes
CSS (5,010 gzip), and 102,036 bytes of self-hosted fonts. The mobile hero is
61,374 bytes.

## Deployment and live evidence

The repaired source commit `ba73afafc433e550140acf2af6361a6cf28bc4b4`
was pushed and built as
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:ba73afafc433`, digest
`sha256:f7525802da3c6b456eea2aa91f721eaa2bcec7e63dcef2a285039fff865fbd96`.
The source-owned deployer replaced the failed generic revision with revision
`sf-mtd-evidence-rail--0000049`:

```text
health build: ba73afafc433e550140acf2af6361a6cf28bc4b4
active revisions: Single / 1
replicas: min 1 / max 1 / running 1
mount: mtd-data -> /data
volume: AzureFile:mtd-evidence-rail-data
SQLITE_VFS: unix-dotfile
```

Before and after a revision restart, private and demo workspaces each returned
100/100 successful fresh-connection reads. A deleted workspace returned 404 on
20/20 reads before and after restart. Twelve fresh browser contexts loaded the
seeded demo. Two 240-request limiter probes returned 86 and 60 HTTP 429
responses; every 429 included `Retry-After: 1`, and accepted requests stayed
inside the one-process allowance.

The final handoff commit is deployed after this file is committed. Verify the
immutable final identity with:

```sh
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
```

## Browser, accessibility, privacy, and response policy

- Live Playwright: 9/9 production scenarios passed, including desktop routes,
  keyboard focus, 390 px, 200% text, offline notice, demo privacy, and caching.
- Live 390 px Axe sweep: zero serious/critical findings on `/`, `/demo`,
  `/app`, `/privacy`, `/terms`, and the real 404; one H1 and no overflow each.
- Factory URL verifier: `/` loaded in 602 ms and `/?demo=1` in 825 ms. Both had
  `lang=en-GB`, one H1, a main landmark, labelled controls, alt text, and no
  console errors.
- Demo privacy: only same-origin requests; no licence header or tracker.
- Offline/update: the recovery notice appears; there is no service worker or
  Cache Storage entry, and the product makes no offline-reload claim.
- Response policy: CSP includes header-only `frame-ancestors 'none'`; `nosniff`,
  strict referrer policy, permissions policy, real 404, no-cache HTML/API,
  immutable hashed assets, and one-hour revalidation for unversioned media all
  passed live.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 1.05 s, LCP 1.88 s, TBT 80 ms, CLS 0, transfer 181,677 bytes.

## How to verify

```sh
npm ci --include=dev
npm test
npm run lint
cargo build --release --locked
jq -r '.[].test' .factory/claims.json
bash scripts/deploy.sh
```

Package/consumer checks do not apply to this web-with-backend artifact. No
known product gaps remain.
