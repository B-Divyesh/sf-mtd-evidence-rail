# Polish 3 release handoff

**Work order:** `mtd-evidence-rail-polish-3`

**Product release:** `ba9749453d21c02fa05467dcd5190832ccb255a7`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Live revision:** `sf-mtd-evidence-rail--0000051`

## What was done

- Closed every finding in `review-1.md`, `review-2.md`, and `review-3.md`.
  The finding-by-finding ledger is in `polish-3.md`.
- Added `.factory/release.json` as the committed published-product identity.
  Exact live claim commands no longer confuse later review commits with the
  deployed product image.
- Added a regression case that accepts the manifest revision while continuing
  to reject stale health, stale images, split revisions, extra replicas, or a
  missing durable mount.
- Renamed the demo banner action to “Start a private workspace” and asserted
  its label and `/app` target in the demo-isolation claim.
- Removed deployment jargon from README and kept operational evidence here.
- Re-audited landing copy, updated the catalog line to a 65-character,
  verb-first sentence, and retained the paper-moon railway visual system.
- Deployed the exact repair commit through `scripts/deploy.sh`, updated the
  release manifest, and pushed both repair and evidence commits to `main`.

## Clean-clone verification

A literal clone of GitHub commit
`5cd292faf18e0894c06e3fdbb7823296b074a544` received `npm ci`.

- All 26 exact `test` commands in `.factory/claims.json`: **PASS**. No
  `EXPECTED_SHA` or other identity override was supplied.
- `npm test`: **PASS** — 6 Rust tests, runtime/default-storage checks,
  shared-storage/topology checks, and 25/25 Chromium tests.
- `npm run lint`: **PASS** — TypeScript, Rust format, and Clippy with warnings
  denied.
- `npm run build`: **PASS** — `dist/` produced; JavaScript 33.90 kB raw / 11.05
  kB gzip; CSS 18.13 kB raw / 5.01 kB gzip.
- `npm audit` during clean `npm ci`: 0 vulnerabilities.

Claim highlights:

- `demo-isolation`, `demo-sample`, and `no-trackers` prove the one-click
  `?demo=1` path, 6/4/2 sample, Reset, private/licence sentinels, same-origin
  traffic, and the 24-hour namespace.
- `workspace-key-recovery` and `workspace-key-auth` prove cross-device restore
  and wrong/missing-key rejection on every private API route.
- `evidence-pack`, CSV matching/import, dates, file types, delete, free limit,
  paid limit, runtime defaults, and restart durability all pass their declared
  sandboxes.
- Hosted checkout returned HTTP 303 to `checkout.dodopayments.com` for product
  `mtd-evidence-rail`, GBP 1500, monthly.
- The three review-3 live commands pass directly from the clean clone. Live
  private and demo workspaces each returned 200 on 100/100 fresh reads. Health
  and the ready image both identify `ba9749453d21`. The 200-request limiter
  check returned 92 HTTP 429 responses, all with `Retry-After: 1`.

## Deployment evidence

The ACR image is
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:ba9749453d21`, digest
`sha256:aba636186b569671c9d50552e92a762a2ec927f84e05c3d29eebad246dba0c39`.
`/health` returns the full product release SHA.

The deployer verified one active and ready revision, one running replica,
Azure Files `mtd-evidence-rail-data` mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`. Before restart, private and demo workspaces each
passed 100/100 reads, 12/12 fresh demo browsers loaded sample data, and a
deleted workspace returned 404 on 20/20 reads. After a real revision restart,
the same demo passed 100/100 reads, deletion still returned 404 on 20/20 reads,
and another 12/12 fresh demo browsers passed. Shared limiter probes returned
101/240 and 97/240 HTTP 429 responses with `Retry-After: 1`.

## Browser, accessibility, privacy, and performance

- Cold `verify-url.sh` checks passed `/` and `/?demo=1`: HTTP 200, route title,
  `lang=en-GB`, one H1, main landmark, no missing alt text, no unlabelled
  buttons, and zero console errors.
- Live Playwright axe integration found zero violations on `/`, `/?demo=1`,
  `/app`, `/privacy`, `/terms`, and the designed HTTP 404.
- Live routing checks passed route-specific titles and canonicals, H1 focus,
  Back navigation, legal links, and the real 404 response.
- Live 390 px keyboard and mobile checks passed. The named sample is visible
  in the first demo viewport; 200% text has no horizontal overflow.
- Live demo isolation, sample reset, same-origin privacy, and offline recovery
  tests passed after deployment.
- Lighthouse mobile: performance 99, accessibility 100, best practices 100,
  SEO 100, LCP 1.9 s, CLS 0, total transfer 177 KiB. INP is not reported for a
  no-interaction lab navigation.

Evidence:

- `.factory/evidence/polish-3/live-root/screenshot-mobile.png`
- `.factory/evidence/polish-3/live-demo/screenshot-mobile.png`
- `.factory/evidence/polish-3/live-root/verify.json`
- `.factory/evidence/polish-3/live-demo/verify.json`
- `.factory/evidence/polish-3/lighthouse-live.json`

## Run and verify

```sh
npm ci
npm test
npm run lint
npm run build
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
```

For the isolated sample, open
<https://mtd-evidence-rail.sociobot.in/?demo=1>.

## Known gaps and next steps

No review finding or required acceptance item remains open. No corrective next
step is required for this work order; routine service monitoring continues
outside the repository.
