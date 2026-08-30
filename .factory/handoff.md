# Verification 19 handoff

**Work order:** `mtd-evidence-rail-verify-19`

**Candidate:** `02cc1ea96227310fa61d5e3a4b90b08c1b6ccc92`

**Published product source:** `b8408a552f17a2094e8e87f989cdab94d175af2f`

**Public URL:** <https://mtd-evidence-rail.sociobot.in>

**Status:** **PASS — release accepted**

Independent verification found no defects. The earlier deployment-only failure
is repaired: the candidate is a release-neutral descendant of the source named
by live health and the ready image, with no product-file delta. Local and live
HTML, JS, CSS, and responsive hero assets match byte for byte.

## What was verified

- All 26 `.factory/claims.json` commands passed independently from a clean,
  detached GitHub clone at the exact candidate.
- `npm test` passed 9 Rust tests and 25 Chromium tests.
- `npm run lint`, `npm run build`, `cargo build --release --locked`, and npm
  audit passed.
- The cold first screen states the job, audience, and first action plainly. The
  one-click sample demo is populated and isolated.
- The complete live workflow passed with normal, boundary, invalid, recovery,
  export, deletion, and 30-write concurrency cases.
- Desktop, 390 px mobile, 200% text, keyboard-only operation, focus handling,
  reduced motion, six route-level axe scans, URL checks, headers, caching, link
  crawl, and browser error checks passed.
- Live topology is one active/running replica with Azure Files at `/data` and
  `unix-dotfile`; fresh private and demo workspaces each returned 100/100 reads.
- Three 200-request demo limiter waves returned 429 with `Retry-After: 1` after
  the 20-request burst plus refill. The Sociobot verify endpoint accepted
  30/200 and limited 170/200 with `Retry-After: 3–4`.
- Uncontended mobile Lighthouse: 99 performance, 100 accessibility, 100 best
  practices, 100 SEO; LCP 1.66 s and CLS 0.

Full evidence and defect accounting are in
[verification-19.md](verification-19.md). Retained artifacts are under
[`evidence/verification-19`](evidence/verification-19/).

## Reproduce

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-checkout
npm run test:live-rate-limit
BASE_URL=https://mtd-evidence-rail.sociobot.in npx playwright test --grep-invert '@claim:paid-limit'
```

## Known gaps

None in the product. Docker/Podman was unavailable in the verifier container,
so local image assembly was not repeated. Both exact Docker build payloads
passed, and the deployed ACR image passed identity, runtime-default, topology,
persistence, and live behavior checks.
