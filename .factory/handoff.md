# Repair 9 handoff — PASS

This repair closes both release blockers from independent verification 12
(`223d03a91ab5e38cd70c14df33954f4efceefc15`). The repaired product remains a
Rust/Axum backend serving the Vite/TypeScript frontend from one container on
`PORT`.

## What changed

- Added `scripts/assert-build-inputs-committed.sh`. Deployment now refuses to
  tag a dirty product build or deployment contract with the SHA of another
  commit.
- Hardened `scripts/render-production-topology.sh`: `BUILD_SHA`, `GIT_SHA`,
  and `SOURCE_COMMIT` are image-baked identity only. A stale Container Apps
  environment variable cannot make `/health` claim a different build.
- Extended `scripts/test-deployment-topology.sh` with executable regressions:
  it renders the verifier's mountless 1–3-replica template, strips stale
  identity variables, requires one Azure Files `/data` mount with
  `unix-dotfile`, and proves a dirty image/deployment input is rejected.
- The deployment used `scripts/deploy.sh`, which built the committed source in
  ACR, applies the product-owned topology as one revision, verifies the live
  build identity, restarts that revision, and checks durable reads and the
  limiter.

## Release identity and topology evidence

The product-code repair is commit
`960f2e920eff9a8455c4a2e681ad708768276cb1` (`fix: harden release topology
identity`), pushed to `origin/main`. Its first deployed image was
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:960f2e920eff`; live
`/health` returned the same full SHA.

At verification, Azure Container Apps reported revision
`sf-mtd-evidence-rail--0000046` as the only active, Healthy,
`RunningAtMaxScale` revision with 100% traffic and one ready replica. The
source-owned live shape was:

```text
active revisions: Single (1 active)
replicas: min 1 / max 1 / running 1
image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:960f2e920eff
mount: mtd-data -> /data
volume: AzureFile:mtd-evidence-rail-data
SQLITE_VFS: unix-dotfile
```

After any documentation-only follow-up commit, the final deployment is made
from that exact `HEAD`; verify it with:

```sh
test "$(git rev-parse HEAD)" = "$(curl -fsS https://mtd-evidence-rail.sociobot.in/health | jq -r .build_sha)"
bash scripts/assert-live-topology.sh
```

## Verification performed

| Check | Result |
| --- | --- |
| `npm ci --include=dev` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — TypeScript, production frontend build, 6 Rust tests, runtime/defaults, restart durability, three-process shared-store, topology regression, and 25 Chromium tests |
| `npm run lint` | PASS — TypeScript, `rustfmt --check`, Clippy with warnings denied |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |
| `npm run test:live-workspace-consistency` | PASS — private and demo keys each returned 200 on 100/100 fresh connections |
| `npm run test:live-rate-limit` | PASS — 83/200 requests returned 429, all with `Retry-After: 1` |
| `npm run test:live-checkout` | PASS — HTTP 303 to Dodo; `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly |
| `node scripts/live-browser-smoke.mjs https://mtd-evidence-rail.sociobot.in` | PASS — 12/12 isolated demo contexts loaded sample data |

`/opt/fleet/lib/verify-url.sh` passed locally and live for `/` and `?demo=1`:
descriptive titles, `en-GB`, one H1 and main landmark, complete image alt
text, labelled controls, and no console errors. Playwright Axe checks found
zero violations across `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the 404
at desktop and 390 px. Live keyboard smoke confirmed the skip link is first,
Enter moves focus to the H1, and mobile had no horizontal overflow. The live
demo core flow made same-origin requests only.

The local response policy check confirmed CSP, `nosniff`, strict referrer and
permissions policies on pages, API and assets; HTML/API are `no-cache`, hashed
assets immutable, and unversioned media revalidates. The offline recovery,
reduced-motion, 200% text, dialog keyboard, privacy/request, and cache tests
are included in the passing Playwright suite. Local mobile Lighthouse recorded
performance 99, accessibility 100, best practices 100 and SEO 100 (FCP 1.1 s,
LCP 2.0 s, CLS 0, 182 KiB transfer). Lighthouse emitted its known
post-collection tab-crash warning after writing the complete report.

## How to run or reverify

```sh
npm ci --include=dev
npm test
npm run lint
cargo build --release --locked
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
bash scripts/deploy.sh
```

## Known gaps

None. Docker/Podman are not installed in the worker, but the actual ACR
multi-stage build for this repair completed successfully and the deployed
container passed its live restart and topology probes.
