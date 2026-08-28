# MTD Evidence Rail verification handoff

Updated 28 August 2026 for work order `mtd-evidence-rail-verify-2`.

## Result

**FAIL — do not release.**

Candidate `9a357651212a07db848e3857217cfa1bc91240ca` is deployed at
<https://mtd-evidence-rail.sociobot.in>, and its static assets match the clean
local production build. The deployed backend does not provide one consistent
workspace store.

Fresh final evidence:

- 0/12 new browser contexts loaded the one-click sample demo;
- every failure was `POST /api/demo` 201 followed by `GET /api/workspace` 404;
- one demo key returned 13/40 successful reads and 27/40 404s;
- one private key returned 10/30 successful reads and 20/30 404s;
- both probes repeated `404, 404, 200`, indicating three isolated request
  targets;
- all 100 health checks returned the exact candidate SHA.

The core receipt/invoice workflow, demo, persistence, deletion, and export are
therefore unreliable in production. This is release-blocking even though an
earlier live suite happened to pass once.

## Verification completed

- All 18 commands in `.factory/claims.json`: PASS from a detached clean
  checkout.
- `npm test`: PASS, including TypeScript, Rust, runtime, persistence, and 17
  Chromium tests.
- `npm audit`, Rust formatting, strict Clippy, locked release build, and exact
  Vite production build: PASS.
- Independent local normal, boundary, invalid-input, recovery, export,
  deletion, and HTML-injection checks: PASS.
- Live first-read, accessibility, keyboard, 390 px layout, reduced motion,
  privacy request log, headers, caching, links, build identity, and bundle
  budgets: PASS.
- Live product API rate limit: 35/180 responses were 429 with `Retry-After: 1`;
  observed burst allowance was 145 under the broken multi-instance topology.
- Sociobot verification rate limit: 70/100 were 429 with `Retry-After: 4`.
- Fresh mobile Lighthouse: 98 performance, 100 accessibility, 100 best
  practices, 100 SEO; LCP 1.88 s and CLS 0.

Docker/Podman was unavailable, so the image was not rebuilt locally. The
Dockerfile was reviewed and meets the declared build/runtime shape. This is not
a PWA, library, or CLI and requires no sign-in, so those conditional checks do
not apply.

## Next step

Repair or reconfigure production so every request reaches the same durable
workspace data. Then prove 100/100 reads for newly created demo and private
keys across fresh connections and a revision restart before rerunning QA.

See [verification-2.md](verification-2.md) for the full evidence and all test
results.
