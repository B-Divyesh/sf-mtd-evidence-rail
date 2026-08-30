# Review 4 handoff

**Work order:** `mtd-evidence-rail-review-4`

**Candidate:** `5995607104fdec40b52f6555fe98ae88684aedaa`

**Live build:** `b8408a552f17a2094e8e87f989cdab94d175af2f`

**Status:** **FAIL**

The complete adversarial report is in [review-4.md](review-4.md). No product
code was changed.

## What was done

- Opened the live landing page cold in fresh 390 × 844 and 1440 × 1000
  Chromium contexts.
- Entered the sample in one click, confirmed realistic data above the fold,
  tested Reset, and checked private workspace and subscription isolation.
- Ran every exact command in `.factory/claims.json` from a committed clean
  clone.
- Audited every landing and README sentence, heading, label, and action.
- Rechecked every finding from reviews 1–3 and polish records 1–3 against live
  behavior and current source.
- Checked route titles, H1s, metadata, canonicals, H1 focus on navigation and
  Back, designed 404 behavior, links, mobile overflow, console output, request
  origins, and axe results.
- Ran the full local test, lint, and build gates from the clean clone.

## Verification results

- Exact claims: **25 PASS, 1 FAIL**.
- Failing command: `npm run test:live-release`.
- `npm test`: **PASS**, 9 Rust tests and 25/25 Chromium tests.
- `npm run lint`: **PASS**.
- `npm run build`: **PASS**, producing `dist/`; JavaScript is 11.05 kB gzip.
- Live demo: **PASS** for one-click sample, 390 px first-screen value, Reset,
  private-data isolation, same-origin requests, and no licence header.
- Live route axe sweep: **0 violations** across `/`, `/demo`, `/app`,
  `/privacy`, `/terms`, and the designed 404.
- Live workspace consistency: **PASS**, 100/100 private and 100/100 demo reads.
- Live rate limit: **PASS**, three 200-request waves with `Retry-After: 1` on
  every 429.

## Open findings

1. **F-3-2, blocking regression:** the release-identity claim command rejects
   committed verification-19 evidence before checking the live release.
2. **F-1-6, blocking regression:** deployment jargon returned to README, with
   one 27-word sentence.
3. **F-4-1, medium:** README's comparative demo-limit statement is vague and
   absent from the claims registry.
4. **F-4-2, minor:** README uses the unexplained term “namespace”.

## Reproduce

From a clean clone:

```sh
npm ci
npm run test:live-release
npm test
npm run lint
npm run build
```

The first command after install reproduces the blocking claim failure. The
other three quality gates pass. See `review-4.md` for the exact output, full
claims matrix, copy audit, history audit, and concrete fixes.
