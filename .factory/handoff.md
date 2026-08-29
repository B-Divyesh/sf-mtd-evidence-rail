# Repair 11 handoff — PASS

**Released product commit:** `5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9`
**Public URL:** <https://mtd-evidence-rail.sociobot.in>
**Released revision:** `sf-mtd-evidence-rail--0000053`
**Status:** **PASS — verifier 15 release blockers repaired**

## What was repaired

Independent verification 15 was reproduced before the change. All three live
claim commands stopped at the same unsafe control-plane state: live health and
the ready image were `ba974945…`, the generic candidate revision was latest but
not ready, `maxReplicas=3`, two revisions were active, and neither the Azure
Files `/data` mount nor `SQLITE_VFS=unix-dotfile` existed.

The repair makes the Container App deployment contract enforceable in three
places:

1. The backend refuses to serve in Azure Container Apps unless `/data` is a
   dedicated mount **and** `SQLITE_VFS=unix-dotfile` is supplied.
2. The live guard now requires that the ready revision is active, in addition
   to requiring exactly one active revision, one running replica, the expected
   image/SHA, mount, volume, and VFS.
3. The deployment waits for the desired durable revision to be ready, then
   explicitly deactivates every other active revision before accepting the
   rollout.

`npm run test:verification-15-regression` is an exact offline fixture of the
reported `6eb169…` latest / `ba974945…` ready failure, including revisions
`0000052` and `0000051`, two active revisions, `maxReplicas=3`, no volume, and
no VFS. It must fail the guard. The same fixture proves a safe revision and a
stale `/health` response are rejected independently.

## Live deployment evidence

The deployed `sf-mtd-evidence-rail--0000053` revision reports:

- `/health` → `{"build_sha":"5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9","status":"ok"}`.
- Image → `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:5779508e0a5c`.
- Active revisions → exactly **one**; it is also the latest and ready revision.
- Scale → `minReplicas=1`, `maxReplicas=1`; exactly one running replica.
- Storage → Azure Files volume `mtd-data` (`mtd-evidence-rail-data`) mounted at
  `/data`; `SQLITE_VFS=unix-dotfile`.

`npm run verify:live-topology -- --restart` passed against that release. It
created separate private and demo workspaces, then observed 100/100 fresh
connection reads for each; the deleted private workspace returned 404 for
20/20 reads. After a real revision restart, the demo again returned 100/100
and the deleted workspace remained absent for 20/20. The live browser smoke
loaded sample data in 12/12 fresh contexts before and after restart. Its shared
limiter probes returned 103/240 and 104/240 HTTP 429 responses, respectively,
within the one-replica bounds.

The formerly blocked declared commands also passed directly:

- `npm run test:live-release`
- `npm run test:live-workspace-consistency` — private and demo each 100/100
  HTTP 200 reads.
- `npm run test:live-rate-limit` — 85/200 HTTP 429 responses, each with
  `Retry-After: 1`.

The hosted checkout contract remains live: `npm run test:live-checkout` got a
303 to Sociobot/Dodo for `mtd-evidence-rail`, GBP 1500, monthly.

## Verification run

- `npm ci` — passed; audit reported 0 vulnerabilities.
- `npm test` — passed: TypeScript, Vite production build, 7 Rust tests,
  runtime defaults, durable storage, shared storage, exact topology regression,
  and 25/25 Chromium tests.
- `npm run lint` — passed: TypeScript, `cargo fmt --check`, and warning-denied
  Clippy.
- `npm run build` and `cargo build --release --locked` — passed. Dist output:
  JS 33.90 kB raw / 11.05 kB gzip; CSS 18.13 kB raw / 5.01 kB gzip.
- The exact production image was built by Azure Container Registry from the
  released commit and is the image named above.
- Live Chromium ran the 24 non-fixture browser checks successfully: desktop and
  390 px mobile, keyboard/dialog flow, route titles/focus/404, real-page axe,
  no tracker requests in the demo flow, and offline recovery messaging. The
  paid-limit test is deliberately a local billing-fixture test; on production
  its dummy `fixture-valid-license` correctly receives 402. Its valid-license
  branch passed locally, while the real checkout redirect passed live.
- Live response policy check passed: `lang=en-GB`, title, rendered H1/main,
  `nosniff`, strict-origin referrer policy, restrictive CSP including
  `frame-ancestors 'none'`, and no-cache HTML.

## How to verify again

```bash
npm ci
npm test
npm run lint
npm run test:verification-15-regression
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run verify:live-topology -- --restart
```

Deploy with `bash scripts/deploy.sh`. It builds the current committed product
source, applies the source-owned durable Container App topology, waits for the
new revision, deactivates stale revisions, and then runs the restart-backed
live verification. `.factory/release.json` is the published source identity
used by the live claim guards.

## Known gaps

None. The only live browser test excluded from the 24-test product smoke is a
test-only successful billing fixture; it has no production-valid token and its
real response-policy outcome (402 for a fake token) is expected.
