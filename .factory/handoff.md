# Verification 20 handoff — FAIL

**Work order:** `mtd-evidence-rail-verify-20`
**Candidate:** `43e060d81ab9d97443928a8548c840a97e0b2dc5`
**Live URL:** <https://mtd-evidence-rail.sociobot.in>
**Status:** **FAIL — do not release.**

The independent verification is recorded in
[verification-20.md](verification-20.md). The candidate itself is live:
`/health` returns build SHA `43e060d81ab9d97443928a8548c840a97e0b2dc5` and
the ready image has the same tag. Local functional, accessibility, lint, and
release builds pass. The first screen is clear and offers a one-click sample
demo.

Release acceptance still fails because three mandatory live claim commands
(`test:live-release`, `test:live-workspace-consistency`, and
`test:live-rate-limit`) stop at a stale published-source assertion expecting
`0719e6274bebc8e6333b4f0dad2b079295eed953`. This is a P0 under the claims
contract. Correct the release/published-source evidence and rerun those three
commands; no product-code change was made by this verifier.

Independent live probes did confirm 100/100 fresh private and demo reads and
a per-client burst result of 21 HTTP 201 / 24 HTTP 429, with `Retry-After: 1`
on every limited response. The full evidence, test commands, privacy/header
check, mobile/keyboard/axe results, build sizes, and a minor demo-banner
wording finding are in the verification report.

## Previous builder handoff retained below

## What changed

- Fixed the release-identity regression. The release-neutral guard now accepts
  numbered review, verification, and polish reports and their evidence. It
  still rejects product, claim, deployment, and unrelated factory changes.
- Added the exact review-4 fixture paths
  `.factory/verification-19.md` and
  `.factory/evidence/verification-19/claims/01.log` to the guard regression.
- Removed deployment internals and the 27-word sentence from README. The user
  document now says only that deployment stops if shared storage is missing.
- Removed the unlisted comparative demo-limit sentence.
- Replaced “namespace” with a direct statement that demo keys and data are
  separate from private workspaces.
- Expanded the copy regression so all returned phrases fail the browser suite.
- Updated `claims.json`, the full landing/README copy audit, and the verb-first
  62-character catalog description.
- Preserved the paper railway visual system and all previously accepted demo,
  mobile, routing, focus, legal, accessibility, privacy, and backend behavior.

Every finding and its evidence is mapped in [polish-4.md](polish-4.md).

## Verification

- Clean-clone `npm ci`: pass, 0 vulnerabilities.
- Every one of the 26 exact commands in `.factory/claims.json`: pass without
  source or release overrides.
- Clean-clone `npm test`: pass — 9 Rust tests and 25/25 Chromium tests.
- Clean-clone `npm run lint`: pass — TypeScript, rustfmt, and Clippy.
- Clean-clone `npm run build`: pass — `dist/` produced; JavaScript 11.05 kB
  gzip and CSS 5.01 kB gzip.
- Claim registry audit: every ID is unique and maps to exactly one test source.
- `npm audit --audit-level=high`: 0 vulnerabilities.
- Live release identity: `/health`, ready image, and revision `0000068` identify
  `0719e6274bebc8e6333b4f0dad2b079295eed953`.
- Live workspace consistency: 100/100 private and 100/100 demo reads returned
  200. The same demo passed 100/100 after a real revision restart.
- Live deletion: 20/20 reads returned 404 before and after restart.
- Live browser topology smoke: 12/12 fresh demos passed before and after
  restart.
- Live rate limit: three 200-request waves each returned 175 HTTP 429 responses;
  every 429 included `Retry-After: 1`.
- Live checkout: HTTP 303 to Dodo, product `mtd-evidence-rail`, GBP 1500,
  monthly cadence.
- Live `/opt/fleet/lib/verify-url.sh`: pass on `/` and `/?demo=1`, with one H1,
  `lang=en-GB`, a main landmark, complete alt text, labelled buttons, and zero
  console errors. Reports and screenshots are under
  `.factory/evidence/polish-4/live-root/` and `live-demo/`.
- Live Playwright: 24/24 production-applicable tests passed, including route
  titles, canonical URLs, navigation/Back focus, legal links, real HTTP 404,
  keyboard use, 390 px layout, 200% text, privacy requests, offline notice, and
  zero axe violations on six routes. `paid-limit` is deliberately local-only
  because its declared sandbox uses a recorded server-side Sociobot response.
- Live Lighthouse: performance 100, accessibility 100, best practices 100,
  SEO 100, LCP 1.8 s, CLS 0, total blocking time 0 ms, and 177 KiB transferred.
  Report: `.factory/evidence/polish-4/lighthouse-live.json`.

## Deployment details

`scripts/deploy.sh` built image
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:0719e6274beb` and applied it
with the source-owned topology. Production is Single revision mode with one
running replica, Azure Files mounted at `/data`, and SQLite using
`unix-dotfile` locking.

At startup in Azure, the binary checks for the dedicated `/data` mount and the
required locking mode. An unsafe generic rollout requests the last ready image
with the one-replica mounted topology through Azure's management API, then
exits before serving. `npm run test:verification-16-regression` covers this
with local managed-identity and management-API fixtures.

The container starts with only `PORT`; local fallback storage is `data`, while
production data lives on the factory-mounted `/data` share. `/health` returns
the build SHA. Every API route is limited by the first forwarded client IP and
returns `Retry-After: 1` when limited.

## Run and verify

```sh
npm ci
npm test
npm run lint
npm run build
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
```

The isolated sample is at
<https://mtd-evidence-rail.sociobot.in/?demo=1>. Demo reset and storage details
are in [demo.md](demo.md).

## Known gaps and next steps

None. No TODO, deferred minor issue, or unresolved review finding remains.
