# Verification 17 handoff — FAIL

**Candidate:** `031c677afd3a28b469228b63fcb6e2c99967cc9a`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Verified:** 29 August 2026 UTC

**Status:** **FAIL — do not release**

The complete independent report is
[`verification-17.md`](verification-17.md). Product code was not changed.

## Release blockers

1. The first clean run of all 26 declared claim commands had one failure:
   `npm run test:live-rate-limit`. Its 200-request burst returned 136 HTTP 201,
   49 HTTP 429, and 15 connection timeouts. Every received 429 had
   `Retry-After: 1`, but the claim requires excess calls to receive a response.
   A later exact retry passed, so this is intermittent rather than a missing
   limiter.
2. Live `/health`, the ready image, and the active revision identify product
   source `bced2406fb8e1abdeb374ef13a40c78131799b0a`, not candidate
   `031c677afd3a28b469228b63fcb6e2c99967cc9a`. The runtime files match byte for
   byte because the candidate changes only release documentation, but exact
   candidate identity was required.

Low-severity hardening gap: HTTPS responses omit
`Strict-Transport-Security`; HTTP does redirect to HTTPS.

## What passed

- Mandatory cold first-read and one-click sample demo.
- 25/26 claim commands on their first exact run; the failed limiter command
  passed on retry.
- `npm ci`, `npm test` (8 Rust + 25 Playwright), `npm run lint`,
  `npm run build`, `cargo build --release --locked`, topology-repair regression,
  and `npm audit`.
- Live production-safe Playwright: 24/24.
- Full demo workflow: add, validation recovery, evidence upload, CSV matching,
  missing queue, ZIP export, reset, and workspace deletion.
- Persistence/restart and three-process shared-store tests; 100/100 live reads
  for both private and demo workspaces; 30 concurrent writes stored exactly the
  25 accepted records.
- Same-origin-only core flow, secure CSP and related headers, cache policy,
  desktop and 390 px layouts, keyboard focus, reduced motion, 200% text, and
  zero axe violations.
- Mobile Lighthouse 99 performance / 100 accessibility / 100 best practices /
  100 SEO; LCP 1.7 s, TBT 120 ms, CLS 0.

## Reproduce

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:verification-16-regression
npm run test:live-checkout
npm run test:live-workspace-consistency
npm run test:live-release
npm run test:live-rate-limit
BASE_URL=https://mtd-evidence-rail.sociobot.in npx playwright test --grep-invert '@claim:paid-limit'
```

The verifier container had no Docker CLI. Both Dockerfile build payloads were
built directly. This product is not a PWA, library, or CLI and requires no
sign-in.

Evidence is retained in
[`evidence/verification-17`](evidence/verification-17/).
