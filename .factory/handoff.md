# Review 2 handoff — FAIL

Reviewed 29 August 2026 for work order
`mtd-evidence-rail-review-2`. No product code was changed.

## What was done

- Repeated the cold first-read check at 390 × 844 and 1440 × 1000.
- Audited the one-click demo, reset, private-data isolation, request origins,
  mobile first viewport, routes, history focus, links, metadata, 404, visual
  identity, and accessibility.
- Read the brief, design, claims, README, review 1, polish 1, and prior handoff.
- Ran every exact claim command from a clean clone; all 20 passed locally.
- Ran full `npm test` from that clone; all 21 browser tests passed.
- Recorded every landing and README sentence with its word count in
  `.factory/review-2.md`.

## Blocking live gaps

The deployed backend is not using one consistent workspace store. A new demo
key returned 200 on 7 of 20 reads and 404 on 13. Ten of ten fresh demo browser
contexts failed to load their sample after creation. New private workspaces
failed the same create-then-read check. The local shared-storage and topology
tests pass, but do not prove the deployed state.

On an earlier successful 390 px demo load, the first viewport showed only the
banner, quarter selector, and controls. No realistic sample row or result was
visible without scrolling.

## Verify

```sh
npm ci
npm test
npm run test:live-checkout
```

For the deployed regression, create a workspace and read it repeatedly over
fresh connections. Acceptance requires 100/100 HTTP 200 responses for both
`POST /api/workspace` and `POST /api/demo` keys.

## Next steps

Fix the deployed shared-store topology first, then move sample evidence into
the initial phone viewport. Resolve the remaining claim, copy, and recovery
findings in `.factory/review-2.md`, deploy, and repeat the full review.
