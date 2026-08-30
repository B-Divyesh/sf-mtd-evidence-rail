# Repair 13 handoff — PASS

**Work order:** `mtd-evidence-rail-repair-13`

**Verifier report:** `89f6d2c36ab778eb5d7a72f7db594de088d55fdb`

**Failed candidate:** `031c677afd3a28b469228b63fcb6e2c99967cc9a`

**Released product source:** `dbb7dff54f1d40e460b54479a82b33c4a9e832bd`

**Public URL:** <https://mtd-evidence-rail.sociobot.in>

**Ready revision:** `sf-mtd-evidence-rail--0000062`

**Image digest:** `sha256:2ee819a3875508059418112a8b34cc5b4cb3fffb49af7bb221c73f67e2c46773`

**Status:** **PASS — all verification 17 findings repaired**

## Findings reproduced and repaired

### Intermittent live limiter timeouts

The verifier's first 200-request run returned 136 `201`, 49 `429`, and 15
timeouts. A pre-repair rerun passed but retained the unsafe shape: 114 demo
workspaces were admitted and the wave took 21.984 seconds. The generic limiter
kept refilling at 20 requests per second while each accepted `/api/demo`
request performed several durable SQLite writes.

`/api/demo` now has a second admission limit: a 20-request burst with one token
per second. The existing 40-request, 20-per-second limiter still covers every
API endpoint. Excess demo requests receive an immediate `429` with
`Retry-After: 1`, before database work starts.

Exact coverage:

- Rust sends 200 concurrent demo requests through the real router. It requires
  200 responses, at most 22 creations, at least 178 `429` responses, and the
  retry and HSTS headers on every limited response.
- `npm run test:live-rate-limit` now sends three independent 200-request waves.
  It rejects any timeout or other status and checks each limiter allowance.
- Live result: each wave returned all 200 responses in 6.706–8.067 seconds.
  Every wave produced 24 `201` and 176 `429`; all limited responses carried
  `Retry-After: 1`.

### Candidate and deployed identity diverged

Before repair, live `/health` and the ready image named `bced2406…`, while the
candidate was `031c677…`. The claim trusted the stale release manifest without
proving how the candidate related to it.

The new published-source guard accepts only:

1. the exact deployed source commit; or
2. one direct child that changes only `.factory/release.json` and
   `.factory/handoff.md`.

It rejects a longer ancestry gap and any product-changing child. The final
candidate is therefore cryptographically tied to the deployed source without
claiming that post-deploy evidence was baked into the image.

Live evidence now agrees on the full source SHA:

```text
/health: dbb7dff54f1d40e460b54479a82b33c4a9e832bd
ready image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:dbb7dff54f1d
latest = ready: sf-mtd-evidence-rail--0000062
active revisions: 1
running replicas: 1
mount: mtd-data at /data
VFS: unix-dotfile
```

### Missing HSTS

Every application response now sends:

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

The Rust response-policy test covers normal and rate-limited responses. The
container-hosted static configuration carries the same policy. The public root
returned the exact header after deployment.

## Verification evidence

Local and clean-checkout gates:

- `npm ci`: 34 packages, zero audit findings.
- `npm test`: 9 Rust tests and 25 Chromium tests passed.
- `npm run test:verification-17-regression`: limiter, HSTS, and release guard
  regressions passed.
- `npm run test:verification-16-regression`: topology self-repair, release
  guard, and Rust regression passed.
- `npm run lint`: TypeScript, `cargo fmt --check`, and warning-denied Clippy
  passed.
- `npm run build`: produced `dist/`; JS 33,904 bytes raw / 11.05 kB gzip and
  CSS 18,132 bytes raw / 5.01 kB gzip.
- `cargo build --release --locked`: passed.
- A local real-server 200-connection burst returned 21 `201` and 179 `429`,
  with no timeout or unexpected response.
- `npm audit --audit-level=low`: zero vulnerabilities.

Deployment and live gates:

- ACR built the multi-stage, non-root container from the exact source commit.
- `scripts/deploy.sh` applied the source-owned single-replica Azure Files
  topology, restarted it, and rechecked persistence and shared limiting.
- `npm run test:live-release`, `npm run test:live-workspace-consistency`,
  `npm run test:live-checkout`, and the three-wave live limiter claim passed.
- Live workspace consistency returned 100/100 private and 100/100 demo reads.
- Production-safe Playwright passed 24/24 tests, including the complete demo
  flow, privacy request capture, offline error recovery, keyboard navigation,
  390 px mobile, 200% text, routing, and all route-level axe scans.
- Factory `verify-url.sh` passed `/` and `/?demo=1`: HTTP 200, correct title,
  `lang=en-GB`, one H1, a main landmark, complete alt text, labelled buttons,
  and zero console errors.
- Mobile Lighthouse: performance 100, accessibility 100, best practices 100,
  SEO 100; FCP 1.1 s, LCP 1.9 s, TBT 0 ms, CLS 0, transfer 177 KiB.

The product is not a library, CLI, or PWA, so consumer-package and service
worker update checks do not apply. It makes no offline-use claim; the tested
offline path gives a recovery message. It has no runtime AI feature. No brief,
visual identity, product flow, or previously passing behavior was removed.

## Run and verify

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:verification-17-regression
npm run test:verification-16-regression
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-checkout
npm run test:live-rate-limit
BASE_URL=https://mtd-evidence-rail.sociobot.in npx playwright test --grep-invert '@claim:paid-limit'
```

## Known gaps and next steps

No release-blocking or known product gap remains. The worker has no local
Docker daemon; the exact Dockerfile was instead built successfully by Azure
Container Registry and that image is the live revision.
