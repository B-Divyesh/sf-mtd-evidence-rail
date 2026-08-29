# MTD Evidence Rail repair handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-repair-4`.

## Result

Repair commit `9d54aa99c8bd4fb3f07e0ed9146fa6b84147f2a1` is pushed to `main` and
deployed to <https://mtd-evidence-rail.sociobot.in>. The live `/health` route
reported that exact build SHA after the rollout.

The product, README, terms, claims, and checkout test now use the researched
**£15/month subscription**. The landing page links to the Sociobot checkout
endpoint, which returns a Dodo-hosted subscription session. The old redirect-
only checker was removed.

## What changed

- Replaced obsolete payment wording with £15/month subscription wording in
  the product, terms, README, claim registry, and recovery/error messages.
- Added `npm run test:live-checkout`. It follows the checkout response without
  paying and proves the Dodo session host, `mtd-evidence-rail` slug,
  `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP minor-unit amount `1500`, and one-month
  recurring cadence.
- Made the demo banner a labelled top-level complementary landmark; removed an
  unrelated nested preview aside landmark found while tightening the Axe test.
- Removed the 390 px / 200% text overflow by containing the mobile preview,
  preserving the hero image inside the shell, and letting status text wrap.
- Added focused browser coverage for the subscription copy, Dodo link, demo
  landmark/Axe result, 200% text sizing, and the offline recovery notice.

## How to run

```sh
npm ci
npm test
npm run test:live-checkout
npm run build
STATIC_DIR=dist DATA_DIR=data PORT=8080 cargo run
```

For the deployed topology check:

```sh
EXPECTED_SHA=9d54aa99c8bd4fb3f07e0ed9146fa6b84147f2a1 \
  BASE_URL=https://mtd-evidence-rail.sociobot.in \
  bash scripts/verify-live-topology.sh --restart
```

## Verification evidence

- Clean suite: `npm ci && npm test` passed: TypeScript, Vite build, 4 Rust
  tests, runtime-defaults, durable storage restart, shared storage,
  deployment-topology, and **21/21** Chromium tests.
- Checkout contract: `npm run test:live-checkout` passed with HTTP 303 to
  `https://checkout.dodopayments.com/session/...`; it asserted the product
  slug, product ID, GBP 1500 amount, and monthly subscription cadence.
- Format and lint: `cargo fmt -- --check` and
  `cargo clippy --all-targets -- -D warnings` passed.
- Accessibility, keyboard, mobile, privacy, and offline: local and live
  Playwright checks passed. All six routes had one h1 and no Axe violations;
  the 390 px keyboard flow and 200% text-size check passed. The core demo flow
  made same-origin requests only, and the offline event shows a recovery
  notice.
- Live identity and service: `/health` matched the deployed SHA. The live
  topology script created private and demo workspaces and returned 100/100
  fresh-connection reads for each, loaded 12/12 clean demo browser contexts,
  and completed a revision restart during deployment.
- Live rate limit: repeat limiter check returned 78/240 HTTP 429 responses;
  accepted responses (162) stayed below its single-limiter bound (189), and
  429 responses carried `Retry-After: 1`.
- Live URL verification: no console errors; title, `lang=en-GB`, one h1, main
  landmark, image alt text, and button labels were present. See
  `.factory/evidence/repair-4-live/verify.json` and screenshots.
- Live Lighthouse with Chromium: Performance 100, Accessibility 100, Best
  Practices 100, SEO 100; LCP 1.9 s and CLS 0. See
  `.factory/evidence/repair-4-live/lighthouse.json`.

## Deployment

Deployment used `bash scripts/deploy.sh`. The container app is configured as
one active replica with Azure Files at `/data` and `SQLITE_VFS=unix-dotfile`.
The deployment script verified the revision, shared persistent state, restart
recovery, and the live limiter before returning successfully.

## Known gaps

None identified for this repair.
