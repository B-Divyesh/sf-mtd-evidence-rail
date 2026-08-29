# Repair 12 handoff — PASS

**Verifier report:** `c0735c4541447629f7052b0ed46ab5e2ca055bd4`
**Failed candidate:** `560392b27a89568a3e88ca461b060f42fec7e61f`
**Released product source:** `bced2406fb8e1abdeb374ef13a40c78131799b0a`
**Public URL:** <https://mtd-evidence-rail.sociobot.in>
**Observed recovered revision:** `sf-mtd-evidence-rail--0000057`
**Status:** **PASS — all verification 16 release blockers repaired**

## Finding reproduced

All three failed claim commands reproduced the verifier's exact state before
the repair:

```text
latest=sf-mtd-evidence-rail--0000054
ready=sf-mtd-evidence-rail--0000053
ready_active=true
mode=Single min=1 max=3
mount= volume=: vfs=
active=2 running=1
```

The source-owned deployment had correctly created durable revision `0000053`.
After the repair turn, the factory's mandatory generic container rollout made
`0000054` with only `PORT`, `maxReplicas=3`, and no volume. The backend refused
to start it, but Azure kept the failed revision active and kept its unsafe shape
as the desired template. This caused `live-workspace-consistency`,
`live-release-identity`, and `live-api-rate-limit` to fail before their
workloads.

## Root-cause repair

The existing fail-closed storage check remains. An unsafe Azure replica now:

1. obtains an Azure management token from its assigned factory identity;
2. reads the current app and its last ready revision;
3. requests `Single` mode, `minReplicas=maxReplicas=1`, Azure Files `mtd-data`
   at `/data`, and `SQLITE_VFS=unix-dotfile`;
4. keeps the last ready image, so a metadata-only wrapper cannot change release
   identity; and
5. exits with code 78 without opening container-local SQLite or serving.

The normal local runtime still starts with only `PORT`. A correctly configured
Azure revision takes no management action.

## Exact regression coverage

`npm run test:verification-16-regression` covers both boundaries:

- `scripts/test-live-release-guard.sh` uses the exact `560392b` candidate,
  `5779508` ready build, revisions `0000054`/`0000053`, two active revisions,
  `maxReplicas=3`, missing mount, and missing VFS. The live guard must reject it.
- `scripts/test-topology-self-repair.mjs` starts the real backend against local
  managed-identity and Azure-management fixtures. It asserts the repair PATCH,
  last-ready image, one-replica scale, mount, VFS, and exit-before-serving.
- The Rust unit test checks the same topology transformation and removal of
  stale build-identity environment values.

The production-topology claim runs this integration automatically during
`npm test`.

## Real work-order deployment proof

The product source was first deployed with `scripts/deploy.sh`, producing image
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:bced2406fb8e` with digest
`sha256:750c815e9a886adc4902af1e9d330f8a2c80db2ec77abd2ee1efb0251812a9b9`.

I then ran the factory's exact generic container helper with that image. It
created the same unsafe `PORT`-only rollout that caused verification 16. The
new runtime recovery executed through the real managed identity and produced
ready revision `0000057`. Fresh control-plane evidence after recovery:

```text
latest=ready=sf-mtd-evidence-rail--0000057
active revisions=1
image=sociobotregistry.azurecr.io/sf-mtd-evidence-rail:bced2406fb8e
mode=Single min=1 max=1 running=1
mount=mtd-data:/data
volume=AzureFile:mtd-evidence-rail-data
SQLITE_VFS=unix-dotfile
```

`npm run verify:live-topology -- --restart` then passed on this recovered
revision: private and demo workspaces each returned 200 on 100/100 fresh reads;
the deleted private workspace returned 404 on 20/20 reads before and after a
real revision restart; 12/12 fresh demo browser contexts loaded before and
after restart. Limiter probes returned 80/240 and 102/240 HTTP 429 responses,
within one-process bounds, and every limited response included `Retry-After: 1`.

## Complete verification

- `npm ci`: pass; 34 packages, 0 vulnerabilities.
- `npm audit --audit-level=low`: pass; 0 vulnerabilities.
- `npm test`: pass; 8 Rust tests, runtime-defaults, restart durability,
  three-process shared storage, topology/recovery tests, and 25/25 Chromium
  tests.
- `npm run lint`: pass; TypeScript, rustfmt, and warning-denied Clippy.
- `npm run build`: pass; `dist/` produced.
- `cargo build --release --locked`: pass.
- Azure ACR Docker build: pass using the root multi-stage Dockerfile and
  `BUILD_SHA=bced2406fb8e1abdeb374ef13a40c78131799b0a`.
- All 26 claim implementations ran: 22 local claims in the full suite and four
  live commands. The three claims that failed verification 16 now pass.
- `npm run test:live-release`: pass on recovered revision `0000057`.
- `npm run test:live-workspace-consistency`: pass, 100/100 private and 100/100
  demo reads.
- `npm run test:live-rate-limit`: pass; 80/200 requests returned 429 and every
  429 supplied `Retry-After: 1`.
- `npm run test:live-checkout`: pass; HTTP 303 to Dodo, product
  `mtd-evidence-rail`, GBP 1500, monthly.

## Browser, accessibility, privacy, offline, and policy

- Live Playwright: 24/24 production-safe tests passed. The excluded paid-limit
  branch uses a local-only recorded billing fixture and passed in `npm test`.
- Desktop and 390 px mobile passed the full job flow, keyboard navigation,
  skip link, dialog focus/return, 200% text, touch-target, and overflow checks.
- Playwright axe found zero violations on `/`, `/demo`, `/app`, `/privacy`,
  `/terms`, and the real 404.
- Factory `verify-url.sh`: HTTP 200, correct title and `lang=en-GB`, one H1,
  main landmark, all image alt text, labelled buttons, and zero console errors.
- The demo privacy test recorded only same-origin requests. No tracker,
  third-party script, private workspace key, or subscription token was sent.
- Offline recovery messaging passed. This product is not a PWA and makes no
  offline-use or update claim, so service-worker update testing does not apply.
- Response policy passed: `nosniff`, strict-origin referrer policy, restricted
  permissions, CSP with header-only `frame-ancestors 'none'`, no-cache HTML/API,
  one-year immutable hashed assets, and a real HTTP 404.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; LCP 1.905 s, TBT 0 ms, CLS 0, transfer 181,659 bytes.
- Production output is unchanged: JS 33.90 kB raw / 11.05 kB gzip, CSS 18.13
  kB raw / 5.01 kB gzip, fonts 102,036 bytes, mobile hero 61,374 bytes.

Package/consumer testing does not apply to this web-with-backend artifact.
There is no service worker and no runtime AI feature. The researched brief,
visual system, frontend behavior, billing contract, and deployment class are
unchanged.

## Verify again

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:verification-16-regression
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
npm run verify:live-topology -- --restart
```

## Known gaps

None.
