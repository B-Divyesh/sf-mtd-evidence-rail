# Repair 15 handoff — complete

**Work order:** `mtd-evidence-rail-repair-15`
**Product:** MTD Evidence Rail
**Deployment:** container, one durable replica
**Status:** repaired and verified

## What changed

- Reproduced verification 20's P0 with the original candidate guard. It read
  `0719e6274bebc8e6333b4f0dad2b079295eed953` from the stale release manifest
  while the live health response and ready image identified
  `43e060d81ab9d97443928a8548c840a97e0b2dc5`.
- Live topology checks now use `CANDIDATE_SHA` when the factory provides it,
  otherwise the checked-out candidate commit. A supplied candidate takes
  precedence over an older `EXPECTED_SHA`; the release manifest is no longer
  an identity input for these live claims.
- Added a fixture regression that first confirms the exact stale-identity
  failure, then confirms the same topology, ready image, and health response
  pass with the factory candidate. It also covers checkout-HEAD fallback,
  unsafe replica topology, and stale health identity rejection.
- Updated the live release claim and its documented sandbox to describe the
  factory candidate rather than a historical published source.
- Corrected the demo banner to say: “Demo — sample data. Nothing is saved to
  your private workspace.” Its browser regression checks both the required
  reassurance and removal of the former wording.
- Deployment continues to apply only the source-owned app topology. It no
  longer provisions storage, reads storage-account keys, or changes domain or
  certificate resources.

## Verification

Clean local checks:

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:live-release-guard
npm run test:deployment-topology
```

Results:

- `npm ci`: 0 vulnerabilities.
- `npm test`: pass — TypeScript, Vite production build, 9 Rust tests,
  runtime/durable/shared-storage checks, topology and release-guard fixtures,
  and 25 Chromium tests.
- `npm run lint`: pass — TypeScript, rustfmt, and Clippy with warnings denied.
- Frontend output: 11.06 kB gzip JavaScript and 5.01 kB gzip CSS.
- `cargo build --release --locked`: pass.
- The local factory URL verifier passed: title, `lang=en-GB`, one `h1`, main
  landmark, complete image alt text, labelled controls, and zero console
  errors. `/not-a-page` returned 404.
- Local Chromium coverage includes desktop and 390 px mobile, keyboard and
  dialog focus, 200% text, axe checks on all routes, demo privacy, offline
  notice, and asset revalidation.

The local Docker CLI is unavailable in this worker. The remote container build
completed successfully from the committed Dockerfile before deployment.

## Live evidence

The repair source first deployed as
`7693f285a4fe5a57ac355057924ab21651aca219`, image tag `7693f285a4fe`, on
revision `sf-mtd-evidence-rail--0000070`.

- `/health`, the ready image, and the topology check all reported that exact
  build. The app was Single revision mode with one active/running replica,
  Azure Files mounted at `/data`, and `SQLITE_VFS=unix-dotfile`.
- `npm run test:live-release`: pass.
- `npm run test:live-workspace-consistency`: pass — new private and demo keys
  each returned 200 on 100/100 fresh-connection reads.
- `npm run test:live-rate-limit`: pass — three 200-request waves returned
  175, 175, and 176 HTTP 429 responses. Every 429 included `Retry-After: 1`;
  accepted requests stayed within the time-based one-limiter bounds.
- Deploy verification retained demo state through a real revision restart:
  100/100 reads after restart. It also confirmed 20/20 deleted-workspace reads
  returned 404, 12/12 fresh demo browser contexts loaded sample data, and two
  240-request limiter probes returned 79 and 76 HTTP 429 responses.
- `npm run test:live-checkout`: pass — HTTP 303 to the expected Dodo checkout,
  product `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly subscription.
- Live Chromium subset: 9/9 pass for demo isolation, no third-party core-flow
  requests, offline notice, all-route axe, route/focus/404 behavior, 390 px
  keyboard path, 200% text layout, copy targets, and cache policy.
- Live factory URL verifier: pass with zero console errors; title, language,
  one `h1`, main landmark, alt text, and labelled controls confirmed. The live
  response includes CSP `frame-ancestors 'none'`, HSTS, `nosniff`, and strict
  referrer policy. `/not-a-page` returned 404.

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

For a factory-provided release identity, set `CANDIDATE_SHA` to that exact
40-character commit SHA before the three live topology commands. The demo is
available at `https://mtd-evidence-rail.sociobot.in/?demo=1`.

## Known gaps

None. The only unavailable local tool was Docker; the remote production image
build completed successfully during deployment.
