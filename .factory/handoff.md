# MTD Evidence Rail repair handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-repair-3`.

## Result

All release blockers in verifier report commit
`505846e9e76bfd7b465b58f1de89a67229c904cc` are repaired. The repaired product
code was committed and deployed as
`e302ce8dcc0bce6c44ef2103e2d0e06dee9b22ea`. The live health response matched
that full SHA during verification.

The required failure was reproduced before any repair:

```text
Unsafe topology: mode=Single max=3 mount= vfs= active=1
```

The live service now uses one active revision, one ready replica, one
container, `minReplicas: 1`, `maxReplicas: 1`, Azure Files volume
`mtd-evidence-rail-data` mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`.

## Repairs

- Added `.factory/container-app.json` as the source-owned production topology
  contract. `scripts/render-production-topology.sh` deterministically turns the
  verifier's unsafe three-replica shape into the required one-replica shape.
- Updated `scripts/deploy.sh` to render that contract after the image rollout
  and to require a real revision restart before success.
- Strengthened `scripts/verify-live-topology.sh`. It waits for Azure to settle
  to exactly one ready replica, checks the Azure Files mount and VFS, performs
  100 private and 100 demo reads, opens 12 fresh Chromium demos, measures one
  process-wide limiter, restarts the revision, and repeats every data-plane
  check using the original keys.
- Replaced “unlimited” with the tested paid boundary and “unguessable” with the
  observed 64-character key property. The privacy retention text now points to
  the tested durable-storage and deletion behaviours.
- Replaced “Three stops,” “Keep every quarter on the rail,” and “The rail ends
  here” with direct section labels. The product name and original visual art
  remain unchanged.
- Gave the inline landing Terms link and both legal-page email links a minimum
  44 by 44 CSS-pixel target. A 390 px Playwright regression measures all three.
- Added the `production-topology` claim and exact regression. The aggregate
  test command now includes it.

## Local verification

- Clean `npm ci`: 34 packages, 0 vulnerabilities.
- Every command in `.factory/claims.json`: **20/20 passed exactly as listed**.
- `npm test`: PASS — TypeScript, production Vite build, 4 Rust tests, runtime
  defaults, restart durability, three-process shared storage, deployment
  topology, and 18 Chromium tests.
- `cargo fmt --check`: PASS.
- `cargo clippy --all-targets --all-features -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- `npm audit --audit-level=low`: PASS, 0 vulnerabilities.
- `npm run build`: PASS; `dist/` contains 30,080 bytes JS (10,250 gzip), 16,704
  bytes CSS (4,753 gzip), 102,036 bytes of local fonts, and a 61,374-byte mobile
  hero.
- Factory URL smoke on desktop and 390 px mobile: PASS; title, `en-GB`, one
  `h1`, `main`, image alternatives, labelled controls, and zero console errors.
  Evidence is in `.factory/evidence/repair-3/`.
- Playwright Axe checks: zero serious or critical findings across `/`, `/demo`,
  `/app`, `/privacy`, `/terms`, and the real 404 route.
- Keyboard: skip link first, Enter activation, dialog initial focus, Escape
  close with focus return, and visible 3 px focus treatment all pass.
- Reduced motion, 390 px layout, touch targets, same-origin core requests,
  response security headers, cache policy, and real 404 response all pass.
- Local Docker/Podman image build was not available in this worker. The same
  Dockerfile passed the Azure ACR build used for deployment.

## Live verification

- Azure image: `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:e302ce8dcc0b`.
- Ready revision: `sf-mtd-evidence-rail--0000017`; one active revision and one
  ready replica.
- Before restart: private 100/100 reads, demo 100/100 reads, and 12/12 fresh
  Chromium demo contexts passed.
- Shared limiter sample: 102/240 requests returned 429 with `Retry-After: 1`;
  138 accepted responses stayed within the one-process elapsed-time bound of
  185. A second sample returned 96/240 429 responses within the same bound.
- After a real Azure revision restart: the same private and demo keys each
  returned 100/100 successful reads, and 12/12 fresh demos passed again.
- Post-restart limiter sample: 92/240 requests returned 429 with
  `Retry-After: 1`; 148 accepted responses stayed within the one-process bound
  of 186.
- Live applicable Playwright suite: **16/16 passed**, including the complete
  product flow, 390 px mobile, keyboard, Axe, privacy, response caching, and
  copy/touch regressions. Paid fixture-only tests were excluded from live.
- Factory live URL smoke: PASS with no browser console errors.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 1.1 s, LCP 1.9 s, TBT 10 ms, CLS 0, transfer 180,647 bytes.
  Evidence is in `.factory/evidence/repair-3/lighthouse.json` and
  `.factory/evidence/repair-3-live/`.
- Hosted checkout claim: PASS; Sociobot returned the expected redirect. No
  purchase was made.

## Applicability and known gaps

- This product makes no offline claim and is not a PWA, so offline/update
  lifecycle checks do not apply. Its offline UI error state remains covered.
- Package/consumer checks do not apply to this web-with-backend artifact.
- There is no runtime AI feature or user identity/sign-in flow, so AI gateway
  and live identity-provider checks do not apply.
- No release-blocking product gap remains. Infrastructure and billing
  registration remain factory-owned as required by `AGENTS.md`.

## Run and verify

```sh
npm ci
npm test
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release --locked
npm audit --audit-level=low
bash scripts/deploy.sh
EXPECTED_SHA="$(git rev-parse HEAD)" npm run verify:live-topology -- --restart
```
