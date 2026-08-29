# Repair 7 handoff — PASS

Repair work order `mtd-evidence-rail-repair-7` is deployed to
<https://mtd-evidence-rail.sociobot.in>.

- Product repair commit deployed: `8f8c10ac54e64afc0c928c5c72305a458416ac8b`
- Product repair implementation commit: `2b73dddce6881f038ce648b3866a0041d681aaa3`
- Live image: `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:8f8c10ac54e6`
- ACR image digest: `sha256:c2d4469357968c175802521c43a7960eabdfc500c2fbfac19c380f4826cbbe96`
- Live `/health`: `{"build_sha":"8f8c10ac54e64afc0c928c5c72305a458416ac8b","status":"ok"}`

## Release-blocking repairs

Independent verification 10 correctly found that the source declaration was
not the deployed topology. The generic factory deploy helper replaced the
product's Azure Files mount and one-replica scale with its container-local,
three-replica template. That split SQLite state and multiplied the in-process
rate-limit allowance.

`scripts/deploy.sh` now builds the committed image directly in ACR and applies
that image, `Single` revision mode, exactly one replica, the `/data` Azure
Files mount, and `SQLITE_VFS=unix-dotfile` in one source-owned ARM patch. It
will not complete until the Azure control plane reports that exact image and
topology, then it runs the live workspace, browser, rate-limit, and restart
checks. It cannot delegate this product back to the generic three-replica
helper.

Regression coverage added:

- `scripts/test-deployment-topology.sh` renders the verifier's unsafe
  three-replica payload and asserts the requested image, one replica, mounted
  Azure Files volume, and VFS. It also rejects a deploy script that delegates
  to the generic helper or contains the invalid topology-value probe.
- `scripts/test-live-rate-limit.sh` is the verifier's exact 200 fresh
  HTTP/1.1 `POST /api/demo` burst from one forwarded IP. It requires at least
  one `429` and `Retry-After: 1` on every limited response.
- `.factory/claims.json` includes the new `live-api-rate-limit` claim with its
  exact live test command.

## Verification

Clean-install/local commands completed after the final repair:

```text
npm ci                                      PASS — 34 packages, 0 vulnerabilities
npm test                                    PASS — build, 4 Rust tests, runtime,
                                            durable-storage, shared-storage,
                                            topology, and 25 Chromium tests
npm run lint                                PASS — TypeScript, rustfmt, Clippy -D warnings
cargo build --release --locked              PASS
npm audit --audit-level=low                 PASS — 0 vulnerabilities
npm run test:deployment-topology            PASS
```

The production frontend build produced `dist/` with 33.89 kB raw / 11.05 kB
gzip JavaScript and 18.13 kB raw / 5.01 kB gzip CSS.

The local production URL smoke (`/opt/fleet/lib/verify-url.sh`) passed with:

```text
title: MTD Evidence Rail — link expenses to evidence
lang: en-GB; h1: 1; main: true
missing image alt: 0; unlabeled buttons: 0; console/page errors: 0
```

Playwright's Axe integration passed every route in the 25-test suite. A fresh
live 390 px audit after deployment reported zero Axe violations, zero console
errors, no horizontal overflow, and a focusable skip link. The standalone Axe
CLI was attempted but its bundled ChromeDriver 152 is incompatible with the
worker's supplied Chromium 145; the compatible Playwright Axe runner is the
one used by the product tests.

Live deployment and independent probes passed:

```text
Azure control plane: Single mode; min/max replicas 1/1; one active revision
                     and replica; /data -> mtd-data AzureFile; VFS unix-dotfile
deploy verification: private 100/100 fresh reads = 200
                     demo 100/100 fresh reads = 200
                     12/12 fresh browser demo contexts loaded
                     after revision restart: demo 100/100 reads = 200
                     deleted workspace 20/20 reads = 404 before and after restart
                     limiter: 88/240 then 68/240 requests returned 429 with Retry-After
npm run test:live-workspace-consistency: PASS — private and demo 100/100
npm run test:live-rate-limit: PASS — 77/200 returned 429, each Retry-After: 1
npm run test:live-checkout: PASS — 303 to Dodo, GBP 1500, monthly
```

Live privacy/response-policy smoke for the demo made eight same-origin
requests, no page errors, and no service-worker registrations. The product
does not claim offline operation; its tested offline state shows a recovery
notice. Live `/` returned `nosniff`, strict-origin referrer policy,
permissions policy, CSP with `frame-ancestors 'none'`, and `no-cache`; the
hashed JavaScript returned one-year immutable caching.

## How to operate and verify

```sh
npm ci
npm test
npm run lint
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
bash scripts/deploy.sh
```

`scripts/deploy.sh` is the deployment path for this product. It builds in ACR
because Docker and Podman are not installed in this worker. The script requires
the factory Azure identity and the existing factory Container App, Azure Files
share, custom domain, and billing product.

## Known gaps / next step

There are no remaining release blockers from verification 10. The only tooling
limitation is the worker's standalone Axe CLI/ChromeDriver version mismatch;
the repository's pinned Playwright Axe tests and post-deploy live mobile Axe
audit both pass. Keep the source-owned deploy script as the only rollout path;
running the generic helper alone would recreate the unsafe template it guards
against.
