# Verification 18 handoff — FAIL

**Work order:** `mtd-evidence-rail-verify-18`

**Requested candidate:** `bb51321015e6489d85dd8b1102b18328cb87810d`

**Available base tested:** `bb5132445c72488a0840631f7d060fc112254af3`

**Live source:** `dbb7dff54f1d40e460b54479a82b33c4a9e832bd`

**Public URL:** <https://mtd-evidence-rail.sociobot.in>

**Status:** **FAIL — do not release**

## Release blockers

1. The requested candidate cannot be fetched or checked out. `origin` returns
   `upload-pack: not our ref`; `main` is `bb513244…`.
2. The mandatory `live-release-identity` claim fails against the closest
   available base. Live `/health` and the ready image identify `dbb7dff…`, not
   the requested candidate.

All other product and infrastructure checks passed. The functional web product
is healthy; this is a provenance/deployment acceptance failure, not a demo-flow
failure.

## Verification summary

- First-read and one-click demo gate: PASS.
- Claims: 25 PASS, 1 FAIL (`live-release-identity`).
- `npm ci`, unfiltered `npm test`, lint/type/format/Clippy, Vite build,
  `cargo build --release --locked`, and npm audit: PASS on `bb513244…`.
- Live production-safe Playwright: 24/24 PASS.
- Core demo, invalid-input recovery, CSV matching, ZIP export, amount/date/kind
  boundaries, concurrency, deletion, and persistence: PASS.
- Live limiter: three 200-request waves completed; 29–30 accepted per wave,
  all 170–171 excess responses were 429 with `Retry-After: 1`. Observed demo
  allowance: burst 20 plus 1 request/second.
- Privacy request log: same-origin only during the core flow.
- Security and cache headers: PASS, including HSTS and CSP.
- Axe serious/critical, keyboard, focus, reduced motion, 390 px, 200% text, and
  valid-route console checks: PASS.
- Lighthouse mobile: 98 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.8 s, TBT 140 ms, CLS 0, transfer 177 KiB.
- Bundle budgets: JS 33,904 bytes raw, CSS 18,132 bytes raw, fonts 102,036
  bytes, mobile hero 61,374 bytes.

The Docker CLI was unavailable. The exact frontend and optimized Rust backend
builds passed, and the Dockerfile contract was inspected successfully.

## Evidence and next step

See [verification-18.md](verification-18.md) and
[evidence/verification-18](evidence/verification-18/) for exact commands,
claim logs, screenshots, headers, Lighthouse output, and browser results.

Publish or correctly name the immutable candidate, deploy it with matching
build identity, then rerun all 26 claim commands from a clean checkout.
