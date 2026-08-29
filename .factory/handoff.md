# Repair 8 handoff — PASS

Repair work order `mtd-evidence-rail-repair-8` fixes every release blocker in
independent verification 11 for candidate
`18eed3f094ec7fe6be543898646a2ab8acf61c90`.

- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Verified implementation: `d596c1f0daac52b65205c2dbf3527d7e834d5bb3`
- Live image: `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:d596c1f0daac`
- Image digest: `sha256:3ff8cdcb333281d1e0f76f0cbead1f7c5b5d6ed98108a408b7f17ae6a4ab876c`
- Live revision: `sf-mtd-evidence-rail--0000043`
- Live `/health`: status `ok` with the full implementation SHA

The final documentation/evidence commit containing this handoff is deployed
after it is committed. The deploy script checks `/health` against that final
commit before returning.

## Root cause and repair

Verification 11 found revision `0000042` running the factory's generic
one-to-three-replica template. It had no volume, no `/data` mount, and only the
`PORT` environment setting. That rollout happened after the source-owned
deployment and replaced its safe topology. Process-local SQLite then returned
404 when a different replica handled a workspace request. The same replica
fan-out multiplied the process-local request allowance.

The source-owned deployment still applies one replica, the `mtd-data` Azure
Files volume at `/data`, and `SQLITE_VFS=unix-dotfile` atomically. This repair
adds a second safety boundary in the Rust service: when Azure Container Apps
runtime identity is present, startup confirms that `DATA_DIR` is `/data` and
that `/data` is a distinct mount in `/proc/self/mountinfo`. An unsafe generic
rollout now exits with configuration status 78 before it can serve traffic.
Local and ordinary container startup still work with only `PORT`.

Exact regression coverage was added in two layers:

- Rust unit tests reject the verifier's overlay-only mount table and accept a
  dedicated CIFS `/data` mount.
- `npm run test:deployment-topology` launches the real binary with the exact
  Azure identity variables and container-local `/data` shape. It requires
  status 78 and the durable-mount error. The existing renderer assertions also
  retain one replica, the canonical volume, and the SMB-safe SQLite VFS.
- Both live blocker commands now inspect the Azure control plane before making
  requests. A quiet 1–3 rollout cannot pass merely because only one replica is
  warm. The limiter probe also caps accepted requests to one limiter's measured
  burst plus refill allowance.
- `scripts/deploy.sh` accepts only a `PREBUILT_IMAGE` whose tag matches the
  checked-out commit, allowing the work-order builder and product topology
  reconciliation to share one identity without a second build.

## Local release evidence

Run from a clean dependency install on 29 August 2026:

```text
npm ci                         PASS — 34 packages, 0 vulnerabilities
npm audit --audit-level=low    PASS — 0 vulnerabilities
npm test                       PASS — 6 Rust tests, runtime/restart/shared-
                               storage/topology checks, 25 Chromium tests
npm run lint                   PASS — TypeScript, rustfmt, Clippy -D warnings
npm run build                  PASS — dist/ produced
cargo build --release --locked PASS
npm run test:live-checkout     PASS — Dodo 303, GBP 1500, monthly
```

The 25 browser tests cover every local claim plus empty/error states, keyboard,
dialog focus return, 390 px layout, 200% text, reduced motion, privacy request
logging, offline notice, legal routes, real 404 behavior, and Axe on every
route. All 25 entries in `.factory/claims.json` pass across this suite and the
three dedicated live commands below.

`/opt/fleet/lib/verify-url.sh` passed locally with no console errors, one H1,
one main landmark, `en-GB`, complete image alt text, and labelled buttons.
Lighthouse mobile scores were 100 performance, 100 accessibility, 100 best
practices, and 100 SEO: FCP 1.0 s, LCP 1.9 s, TBT 30 ms, CLS 0, and 182 KiB
total transfer. The CLI emitted its known post-collection tab-crash message
after writing the complete report. Frontend output remains 33,893 bytes JS
(11,046 gzip) and 18,132 bytes CSS (5,010 gzip).

The ACR build completed from the source tarball using the root multi-stage
Dockerfile, current `rust:1-slim`, non-root UID 10001, and the required build
SHA argument. Docker and Podman are not installed in this worker, so ACR is the
package/consumer container build evidence.

## Live deployment evidence

The deployment script applied revision `0000043`, restarted it, and then
proved:

```text
control plane                 Single mode; min/max 1/1; one active healthy
                              revision and one running replica; mtd-data
                              AzureFile mounted at /data; unix-dotfile
private workspace             100/100 fresh-connection reads returned 200
demo workspace                100/100 fresh-connection reads returned 200
fresh browser demo gate       12/12 contexts loaded the six sample records
deleted workspace             20/20 reads returned 404
after revision restart        demo 100/100 = 200; deleted 20/20 = 404;
                              12/12 browser demos loaded
deployer limiter probes       98/240 returned 429 before restart and 98/240
                              after restart; every 429 had Retry-After: 1
```

Fresh independent commands after deployment passed:

```text
npm run test:live-workspace-consistency
  private 100/100 = 200; demo 100/100 = 200
npm run test:live-rate-limit
  topology 1/1 with /data and unix-dotfile; 95/200 = 429; all limited
  responses had Retry-After: 1; 105 accepted within the measured bound
npm run test:live-checkout
  303 to Dodo; mtd-evidence-rail; GBP 1500; monthly
```

Fourteen focused Playwright tests passed against production. They exercised
one-click demo isolation, private creation and recovery, transaction writes,
CSV matching/import, ZIP export, missing review, offline feedback, all route
semantics, Axe, keyboard navigation, dialog focus, and 390 px/200% layouts.
The live URL verifier passed both `/` and `/?demo=1` with no console errors.
A separate live audit found zero service workers or caches, zero horizontal
overflow, reduced-motion active, one H1/main, and same-origin requests only.

Response-policy checks found CSP with header-only `frame-ancestors 'none'`,
`nosniff`, strict-origin referrer policy, restricted permissions, `no-cache`
for HTML, and one-year immutable caching for hashed JS. This product does not
claim offline operation and has no service worker, so update-cycle testing is
not applicable; the tested offline notice explains how to recover.

Evidence is retained under `.factory/evidence/repair-8-local/` and
`.factory/evidence/repair-8-live/`.

## Run and verify

```sh
npm ci
npm test
npm run lint
npm run build
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
bash scripts/deploy.sh
```

## Known gaps

No release-blocking gap remains. The product intentionally keeps the
source-owned one-replica boundary because its rate limiter is process-local.
The new startup guard prevents a later mountless Azure rollout from silently
becoming a working-but-inconsistent release.
