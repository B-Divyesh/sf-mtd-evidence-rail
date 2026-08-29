# Polish 2 handoff

Completed 29 August 2026 for work order
`mtd-evidence-rail-polish-2`. The implementation release is commit
`70822dc371f3a07bbf7cb0b91b6b60c889ad89f7`.

## What changed

- Restored reliable live workspaces by deploying one active replica with the
  source-owned Azure Files mount at `/data`.
- Added a public 100-read consistency claim for new private and demo
  workspaces.
- Added a compact mobile demo result above the action toolbar. It shows the
  sample count, missing count, and one named transaction without scrolling.
- Added workspace-key copy and restore flows, warnings, invalid-key feedback,
  focus management, and strict API-wide key validation.
- Registered and tested sample composition, key recovery, key authorization,
  and live consistency claims.
- Unified the audience wording and removed every unproved or misleading
  sentence identified in review 2.
- Retained the paper-moon railway art, local typography, palette, ticket
  shapes, reduced-motion behavior, and original generated assets.
- Rechecked the earlier review-1 isolation, claim, terminology, heading,
  README, and network-copy findings.

Every finding-to-change-to-evidence mapping is in `.factory/polish-2.md`.

## Verification

Run locally:

```sh
npm ci
npm test
npm run test:live-checkout
npm run test:live-workspace-consistency
npm run verify:live-topology
npm run build
```

Observed evidence:

- `npm test`: PASS; four Rust tests and 25/25 Chromium tests.
- Fresh clone: every exact command in `.factory/claims.json` passed. Full log:
  `.factory/evidence/polish-2/clean-claims.log`.
- Build output: JS 33.89 kB raw / 11.05 kB gzip; CSS 18.13 kB raw /
  5.01 kB gzip.
- Accessibility: Playwright axe found zero violations on all six routes.
- `verify-url.sh`: PASS for cold live `/` and `/?demo=1`, with zero console
  errors and all baseline document checks.
- Live topology: 100/100 private reads, 100/100 demo reads, 12/12 fresh demo
  browser contexts, confirmed deletion, and `429` responses with
  `Retry-After`. After an Azure revision restart, the same demo passed another
  100/100 reads and deleted data stayed absent.
- Live route audit: distinct titles and canonical URLs; one H1; working legal
  links; forward and Back focus restoration; real styled HTTP 404.
- Live mobile demo: “Teaching card supplies” ended at 344.53 px in a 390 × 844
  viewport.
- Live Lighthouse: performance 100, accessibility 100, best practices 100,
  SEO 100, LCP 1.9 s, CLS 0, transfer 177 KiB.
- Docker was unavailable locally. Azure ACR built the multi-stage Dockerfile
  successfully in 5m23s and deployed the resulting image.

Evidence is under `.factory/evidence/polish-2/`. The deployed URL is
<https://mtd-evidence-rail.sociobot.in>.

## Deployment

`scripts/deploy.sh` built the image in Azure ACR, selected Single revision
mode, mounted `mtd-evidence-rail-data` at `/data`, set one minimum and maximum
replica, bound the managed certificate, and ran the restart verification.
The initial verified live `/health` response reported
`70822dc371f3a07bbf7cb0b91b6b60c889ad89f7`.

## Known gaps and next steps

No acceptance gap remains. Routine operations should keep the source-owned
one-replica storage contract and run `npm run verify:live-topology` after each
future deployment.
