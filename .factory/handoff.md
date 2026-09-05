# Venture plan handoff

**Work order:** `mtd-evidence-rail-plan-1`

**Date:** 5 September 2026

**Scope:** planning and verification only; no product code or deployment change

## Outcome

Created [`.factory/plan.md`](plan.md) as the M1–M3 venture contract. It records
M1 as the only accepted milestone, makes M2 the next milestone, and keeps M3
future work. It separates accepted core behaviour from fixture-backed billing
mechanics and from unavailable sign-in, messaging, and HMRC capabilities.

Also wrote `/work/.evidence/venture-plan.json` with the next milestone,
external dependencies, and evidence paths for the known M1 pass.

## Current milestone decision

- **M1 — passed:** verification 21 accepted the live core evidence workflow at
  candidate `693a7609d2efb23c6567da5de0b425db92029e5c`.
- **M2 — next, not started:** add Sociobot Entra sign-in, tenant ownership,
  safe anonymous-workspace claiming, and an end-to-end proven £15/month
  subscription lifecycle.
- **M3 — planned, not started:** persist bank reconciliation decisions, support
  import undo, calculate readiness exceptions, and export an evidence manifest.

Checkout destination, price, currency, and cadence are live and tested. No
payment was completed, so real billing is not marked implemented. The current
64-character workspace-key boundary is tested, but it is not called tenant
isolation or sign-in.

## Verification performed

- Read the brief, visual thesis, current source, migrations, tests, claims,
  demo documentation, README, all verification/review/polish reports, and the
  retained QA evidence index.
- `npm ci` — passed; 34 packages, zero vulnerabilities.
- `npm test` — passed; 9 Rust tests and 25 Chromium tests. The Vite build wrote
  `dist/` with 11.06 kB gzip JavaScript and 5.01 kB gzip CSS.
- `npm run lint` — passed TypeScript, rustfmt, and Clippy with warnings denied.
- Live `/health` on 5 September 2026 — HTTP 200, status `ok`, build
  `693a7609d2efb23c6567da5de0b425db92029e5c`.
- Live root headers — HTTP 200 with CSP, HSTS, `nosniff`, strict-origin referrer
  policy, restricted permissions, and `no-cache`.
- Live browser smoke — 12/12 fresh demo contexts loaded the named sample and
  the explicit “nothing is saved to your private workspace” banner.
- `npm run test:live-checkout` — HTTP 303 to hosted Dodo checkout for the
  correct product, GBP 1500, monthly. This did not complete a purchase.

Latest retained acceptance evidence:

- [verification report](verification-21.md)
- [claim results](evidence/verification-21/claims/results.tsv)
- [independent live audit](evidence/verification-21/independent-live-audit.json)
- [local test log](evidence/verification-21/local/npm-test.log)
- [lint log](evidence/verification-21/local/lint.log)
- [Lighthouse summary](evidence/verification-21/lighthouse-summary.json)

## Exact dependencies and gaps

- Sociobot Entra CIAM registration and factory test identities are unavailable;
  sign-in and tenant ownership cannot be accepted until the platform provides
  its supported configuration. Product workers must not request production
  credentials.
- The Sociobot checkout contract is reachable, but a successful non-production
  payment, renewal/cancellation, expiry, and revocation lifecycle is not
  verified. M2 billing remains blocked on factory-operated lifecycle access.
- Restart persistence is accepted. A fleet backup restoration is not yet
  proven and is part of M2's definition of done.
- Messaging is unavailable and not needed in M1–M3. HMRC access and
  certification are unavailable and deliberately out of scope.
- Docker/Podman was unavailable in verification 21, so local image assembly
  remains a next-Docker-capable-QA check. Locked frontend/backend builds and
  the deployed image identity passed.
- Historical deployment regressions repeatedly lost the single-replica durable
  topology. Every later deployment must retain and rerun the exact topology,
  restart, 100/100 workspace-read, multi-browser demo, and rate-limit checks.

## Repository note

Pre-existing Graphify output changes were present before planning and were not
edited or included in this work order's commit. No product source, runtime,
infrastructure, DNS, secrets, or billing configuration was changed. This plan
must not be deployed.
