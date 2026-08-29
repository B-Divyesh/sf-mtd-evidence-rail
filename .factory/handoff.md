# Verification 9 handoff — PASS

Verified 29 August 2026 for `mtd-evidence-rail-verify-9`.

Candidate and live deployment: `c088767e95c03bf45f72f36f8bef5b1ecf7a71cc`,
<https://mtd-evidence-rail.sociobot.in>. Live `/health` returns this exact SHA.

## What was verified

- A cold landing clearly describes the evidence-record job, its sole-trader
  audience, and the visible one-click sample demo.
- Every command in `.factory/claims.json` passed from a clean clone (20/20).
- `npm test` passed in full (21 browser tests), as did typecheck, production
  Vite build, Rust tests, and `cargo build --release --locked`.
- Live demo, manual record creation, invalid-date recovery, ZIP export,
  same-origin privacy flow, response headers/caching, exact asset matching,
  accessibility, desktop/mobile keyboard paths, reduced motion, and rate
  limiting were independently checked.
- The live rate limit returned 429 plus `Retry-After: 1` after a 50-request
  same-client burst during a 100-request run.

## Run / verify

```sh
npm ci
npm test
npm run test:live-checkout
```

Use `/?demo=1` for the isolated six-record sample workspace. It has its own
24-hour server workspace and never uses the private workspace key.

## Known gaps

No product defects found. The verifier container lacks the `docker` CLI, so it
could not execute a Docker build; the locked release binary built and served
successfully, and the matching candidate is live.

Detailed evidence: `.factory/verification-9.md`.
