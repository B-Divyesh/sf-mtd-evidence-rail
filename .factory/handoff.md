# Repair 14 handoff

**Work order:** `mtd-evidence-rail-repair-14`

**Verifier report:** `91aebfb252ae4933ee3406a1dd6544533b8c9b76`

**Corrected failed candidate:** `bb5132445c72488a0840631f7d060fc112254af3`

**Released product source:** `b8408a552f17a2094e8e87f989cdab94d175af2f`

**Release record:** `755359106c98ac2e2d0fb31311779fcc1e6dc850`

**Public URL:** <https://mtd-evidence-rail.sociobot.in>

**Ready revision:** `sf-mtd-evidence-rail--0000065`

**Image digest:** `sha256:7cc21ca8b22d3c20d1492792dde9c95c9cdb0c7922e612d3ae41c4ed53ebd492`

**Status:** **PASS — all verification 18 release blockers repaired**

## Findings reproduced and repaired

### The earlier work order named a commit that did not exist

Verification 18 requested `bb513210…`, while the repository contained
`bb513244…`. The repair work order corrects the immutable candidate to the
existing full SHA above. The corrected candidate is present locally and in the
published `main` history.

No product behavior was changed for this clerical finding.

### The factory code-map commit broke the release identity guard

Before repair, the deployed source was `dbb7dff…`. The corrected candidate
`bb513244…` descended from it, but the guard rejected it because two
release-neutral commits followed deployment:

1. `.factory/handoff.md` and `.factory/release.json` recorded release evidence.
2. The factory updated three generated files under `graphify-out/`.

The guard had required exactly one metadata child. It now requires the
published source to be an ancestor and checks the complete source-to-candidate
diff. Only the release record, handoff, and generated code map may differ.
Any product or deployment change anywhere in the gap still fails.

Exact regression coverage in `scripts/test-published-source-guard.sh` now:

- accepts the published source itself;
- accepts a release-evidence commit followed by a generated code-map commit;
- rejects an unrelated commit with the same visible tree;
- rejects a later product-changing commit; and
- rejects a direct child mixing release metadata with a product change.

`npm run test:verification-18-regression` also proves that stale health,
stale ready images, and the verifier's unsafe rollout topology remain rejected.

### Live did not identify the candidate

The source-owned container deployment built and published the exact repaired
source. Live identity now agrees:

```text
/health: b8408a552f17a2094e8e87f989cdab94d175af2f
ready image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:b8408a552f17
latest = ready: sf-mtd-evidence-rail--0000065
active revisions: 1
running replicas: 1
mount: mtd-data at /data
storage: AzureFile mtd-evidence-rail-data
VFS: unix-dotfile
```

The ACR build used the multi-stage, non-root Dockerfile. The deployed digest is
recorded above. `scripts/deploy.sh` then restarted and rechecked the service:
100/100 private reads, 100/100 demo reads, 20/20 deleted-workspace 404s,
12/12 fresh browser demo loads, and shared rate limiting passed before and
after restart.

## Verification evidence

### Clean install, code, and build

- `npm ci`: 34 packages installed; zero audit findings.
- `npm audit --audit-level=low`: zero vulnerabilities.
- `npm test`: 9/9 Rust tests and 25/25 Chromium tests passed.
- `npm run lint`: TypeScript, Rust formatting, and warning-denied Clippy passed.
- `npm run build`: produced `dist/`.
- `cargo build --release --locked`: passed.
- `npm run test:verification-18-regression`: passed.
- Bundle output: 33,904-byte JS and 18,132-byte CSS; fonts total 102,036 bytes;
  mobile hero 61,374 bytes; desktop hero 173,422 bytes.
- This is not a package or CLI, so consumer-package verification does not
  apply. ACR built the production container because no local Docker CLI exists.

### Clean-clone claims

A fresh clone of pushed release record `7553591…` ran every command declared
in `.factory/claims.json` independently. All 26 claims passed. The Sociobot
billing gateway briefly returned HTTP 503, then its exact claim command passed
from the same clean clone after service recovery at 03:01 UTC.

The passing live claims include:

- release identity and durable topology;
- 100/100 fresh-connection reads for private and demo workspaces; and
- three 200-request limiter waves. They returned 24–25 creations and 175–176
  HTTP 429 responses per wave, with `Retry-After: 1` on every 429.

### Browser, accessibility, privacy, offline, and response policy

- Production-safe Playwright: 24/24 passed against the deployed URL.
- Desktop and 390 px mobile, keyboard-only operation, dialog focus, 200% text,
  route focus, and all route-level axe scans passed.
- The privacy request test observed same-origin traffic only through the core
  demo flow. Licence verification remains an explicit Sociobot request.
- The product makes no offline-use claim and registers no service worker. Its
  tested offline path displays a recovery notice; immutable asset cache and
  unversioned revalidation checks passed.
- Factory `verify-url.sh` passed `/` and `/?demo=1`: HTTP 200, correct route
  titles, `lang=en-GB`, one H1, a main landmark, complete alt text, labelled
  buttons, and zero console errors. Measured loads were 580 ms and 932 ms.
- Root, health, real 404, and hashed assets send the expected CSP, HSTS,
  nosniff, referrer, permissions, and cache headers. HTTP redirects to HTTPS.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 1.13 s, LCP 1.80 s, TBT 0 ms, CLS 0, transfer 181,712 bytes.

## Run and verify

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:verification-18-regression
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-checkout
npm run test:live-rate-limit
BASE_URL=https://mtd-evidence-rail.sociobot.in npx playwright test --grep-invert '@claim:paid-limit'
```

## Known gaps

None. The external Sociobot billing service returned HTTP 503 from 02:49
through 03:00 UTC, then recovered without a product-side change. The clean
clone rerun received HTTP 303 and verified the expected Dodo product, GBP 1500
monthly price, and hosted checkout page.
