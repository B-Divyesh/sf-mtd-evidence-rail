# Review 3 handoff — FAIL

**Work order:** `mtd-evidence-rail-review-3`

**Reviewed source:** `ec565569146bf69fec474c646670462afed9c215`

**Live build:** `bf15534cef6692e35f5ad62b610eb51648dcfe88`

## What was done

- Wrote the cumulative adversarial report at `.factory/review-3.md`.
- Rechecked cold 390 px and desktop first reads, the one-click demo, sample
  visibility, Reset, sandbox isolation, live export, private key recovery,
  routes, links, metadata, focus, accessibility, and visual identity.
- Read every earlier review, polish record, and the prior handoff; rechecked all
  21 earlier finding IDs in live behavior and source.
- Ran all 26 `claims.json` commands individually from a literal clean clone.
- Did not modify product code.

## Verification results

- Exact claim commands: **23 PASS, 3 FAIL**.
- Failed: `live-workspace-consistency`, `live-release-identity`, and
  `live-api-rate-limit`; each expects clean-clone HEAD `ec565569…`, while the
  ready image and `/health` identify `bf15534…`.
- Diagnostic runs with `EXPECTED_SHA=bf15534…` passed release topology,
  100/100 private and demo reads, and live rate limiting.
- `npm test`: PASS — 6 Rust tests and 25/25 Playwright tests.
- `npm run lint`: PASS.
- `npm run build`: PASS; `dist/` produced, JavaScript 11,046 bytes gzip.
- Live demo: 6 transactions, 4 linked files, 2 missing items; named sample in
  first mobile viewport; same-origin requests only; private/licence sentinels
  unchanged; reset restored sample under a new key.
- Live route axe sweep: zero violations on `/`, `/demo`, `/app`, `/privacy`,
  `/terms`, and the designed 404.

## Findings left for the next repair

- F-3-1, F-3-2, F-3-3: exact live claim commands are not reproducible from the
  current clean clone because release identity defaults to repository HEAD.
- F-1-6: deployment jargon has regressed into README and is blocking under the
  history rule.
- F-3-4: rename “Start for real” to “Start a private workspace”.

## Reproduce

```sh
npm ci
npm test
npm run lint
npm run build
npm run test:live-workspace-consistency
npm run test:live-release
npm run test:live-rate-limit
```

The first four commands pass. The last three fail until the release-identity
contract is corrected or the current product revision is deployed.
