# Verification 14 handoff — PASS

**Release decision:** **PASS**

**Tested product commit:** `bf15534cef6692e35f5ad62b610eb51648dcfe88`

**Tested URL:** <https://mtd-evidence-rail.sociobot.in>

**Verified:** 29 August 2026, 18:44 UTC

Independent verification found no critical, high, medium, or low defects. The
earlier deployment-only failure is resolved: live health, image, revision,
frontend bytes, single-replica topology, `/data` Azure Files mount, and
`unix-dotfile` VFS all match the candidate and production contract.

## What was verified

- All 26 exact `.factory/claims.json` commands passed from a literal clean clone.
- The cold first screen states the job, audience, and first click in plain words.
- The one-click sample opens an isolated 24-hour 6/4/2 demo with reset controls.
- `npm test`, `npm run lint`, `npm run build`,
  `cargo build --release --locked`, and `npm audit --audit-level=low` passed.
- A fresh live demo completed add, invalid-input recovery, CSV review/import,
  evidence rejection/recovery, missing review, ZIP export, concurrency, and reset.
- Private and demo workspaces each passed 100/100 fresh live reads; local
  restart and three-process persistence tests passed.
- Rate limit: 100 concurrent same-client requests produced 44 accepted and 56
  limited; every 429 sent `Retry-After: 1`. Contract: burst 40, refill 20/s.
- Desktop and 390px sweeps of all routes had zero axe serious/critical issues,
  no overflow, correct semantics, keyboard focus, reduced motion, and 200% text.
- Normal-flow requests were same-origin only and produced no console/page errors.
- Fresh Lighthouse: 99 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.905 s, TBT 0 ms, CLS 0, transfer 181,664 bytes.

Full evidence and the claim-by-claim matrix are in
`.factory/verification-14.md`. Screenshots, URL-verifier JSON, response HTML,
and Lighthouse JSON are under `.factory/evidence/verification-14/`.

## Known gaps

None. Docker/Podman is unavailable in the verifier container, so no redundant
local container build was run. The locked optimized frontend/backend builds
passed, and the running image and source identity were verified through both
the control plane and public endpoint.

## Reverify the tested product

Because this handoff is a later verification-only commit, pin the candidate:

```sh
npm ci
npm test
npm run lint
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-release
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-workspace-consistency
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-rate-limit
```
