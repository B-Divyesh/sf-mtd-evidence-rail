# Repair 16 handoff

**Work order:** `mtd-evidence-rail-repair-16`

**Date:** 5 September 2026 UTC

**Milestone:** M1 — evidence pack core; repair candidate deployed, independent acceptance pending

**Implementation SHA:** `f87a563751c31cd5ca612f396d86c59c6c5d76b9`

**Documentation baseline tested:** `0a86918d231ce63e27757c77aa6b2259d41040d3`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

## Outcome

Review 5's two findings are fixed at their causes.

- Live claim commands now validate a clean checkout against
  `.factory/release.json`. A later numbered report, review evidence, venture
  plan, handoff, or Graphify commit resolves the recorded implementation.
- Product or deployment-input changes still fail the published-source guard
  until that exact source is deployed and recorded.
- Outcome fixtures reproduce the later `plan.md` documentation commit. They
  accept the earlier live implementation and reject the documentation SHA as
  runtime identity.
- `/terms` no longer promises renewal, cancellation, or pre-payment billing
  disclosures. It states only the tested £15 monthly checkout, active-limit
  effect, and Dodo-through-Sociobot destination.
- A browser regression checks the rendered Terms outcome. The copy audit now
  includes every billing sentence on that page.
- The required job, audience, sample action, and three plain facts now fit in a
  1440 × 900 first screen. A browser test measures the rendered result.

The product still names the job as **Link each expense to evidence**, serves UK
sole traders, tutors, and small club operators, and puts **Try it with sample
data** first. No M2 or M3 feature was presented as shipped.

## Deployment

`scripts/deploy.sh` built and pushed:

```text
sociobotregistry.azurecr.io/sf-mtd-evidence-rail:f87a563751c3
```

The product-owned revision is `sf-mtd-evidence-rail--0000074`. Deployment
kept Single revision mode, one running replica, and the existing Azure Files
volume `mtd-data` mounted at `/data`. `SQLITE_VFS=unix-dotfile` remains set.
No storage, DNS, certificate, secret, billing, or unrelated service setting
was created or changed.

The deployment check proved:

- live `/health` and the ready image identify the implementation SHA;
- private and demo workspaces returned 100/100 fresh-connection reads;
- the demo returned 100/100 reads after a product-only revision restart;
- a deleted workspace returned 404 for 20/20 reads before and after restart;
- 12/12 fresh browser contexts loaded the populated demo before and after
  restart; and
- the shared limiter returned 429 with `Retry-After: 1` within one-process
  bounds.

## Local verification

The documented setup began with `npm ci` and installed 34 packages with zero
vulnerabilities. These checks pass:

```text
npm test
npm run lint
npm run build
cargo build --release --locked
npm audit --audit-level=high
npm run test:published-source-guard
npm run test:live-release-guard
```

`npm test` includes 9 Rust tests, runtime/defaults, durable and shared storage,
deployment topology, both release guards, and 27 Chromium tests. `dist/` is
produced. The built JavaScript is 33.87 kB raw and 11.04 kB gzip; CSS is 18.13
kB raw and 5.01 kB gzip.

## Claims and browser evidence

`.factory/claims.json` remains the canonical list of 26 current claims. The
three live claim commands resolve the implementation recorded in
`.factory/release.json`; explicit `CANDIDATE_SHA` remains available only for
verifying a newly deployed image before its later release record exists.

From a clean detached checkout of documentation baseline `0a86918…`, `npm ci`
installed the locked dependencies and every declared claim command was run
literally. All 26 passed. In particular:

- `test:live-workspace-consistency` returned 100/100 successful reads for new
  private and demo workspaces;
- `test:live-release` matched `/health`, the ready image, revision `0000074`,
  one replica, the `/data` mount, and `unix-dotfile` to `f87a563…`; and
- `test:live-rate-limit` completed three 200-request waves. Each accepted 24
  demo requests and returned 176 HTTP 429 responses with `Retry-After: 1`.

The release-guard fixtures accept a later venture-plan and handoff checkout,
resolve the recorded implementation, and reject the documentation SHA as a
runtime identity. Product, dependency, test, migration, and deployment-input
changes still require a newly recorded implementation.

Fresh 1440×900 and 390×844 browsers showed the job, full audience, sample
action, and all three facts before scrolling. One click loaded the 6/4/2
sample. The persistent banner stated that nothing is saved to the private
workspace and retained Reset demo plus Start a private workspace. Reset and
the isolation claim left seeded private workspace and subscription state
unchanged.

The root and demo URL verifier reports each contain the correct title,
`lang=en-GB`, one H1, one main landmark, complete image alternatives, labelled
buttons, and no console errors. The browser suite found zero axe violations on
the landing, demo, app, privacy, terms, and designed HTTP 404 routes. Keyboard,
focus return, 44 px targets, 200% text, reduced motion, route titles, links,
offline recovery copy, and the rendered Terms regression passed.

Fresh mobile Lighthouse scored 100 for performance, accessibility, best
practices, and SEO. FCP was 1.05 s, LCP 1.88 s, TBT 22 ms, CLS 0, and transfer
was 181,690 bytes. Worker evidence is under
`/work/.evidence/repair-16-final-claims`, `repair-16-browser`,
`repair-16-verify-root`, `repair-16-verify-demo`, and
`repair-16-lighthouse.json`.

## Paid offer

The existing public offer remains £15 per month for more than 25 transactions
in a quarter. The live Sociobot route already opens the registered Dodo-hosted
subscription checkout for GBP 1500 with monthly cadence. No billing
registration file is required by this repair. A checkout redirect is not
recorded as proof of purchase or entitlement.

## Known gaps and external dependencies

- M2 is not shipped. Sociobot Entra registration and test identities are still
  required for accounts and tenant ownership.
- A controlled Sociobot billing lifecycle is still required to prove purchase,
  renewal, cancellation or revocation, expiry, and later limit enforcement.
- A fleet backup and isolated restore drill is still required for M2. Restart
  persistence is not a backup.
- M3 is not shipped. Pilot users and a consented redacted CSV corpus are still
  needed for matching and readiness validation.
- HMRC filing, certification, tax advice, payroll, and full accounting remain
  out of scope. No offline-use claim or runtime AI feature is present.

Pre-existing `graphify-out` working-tree changes remain untouched and
uncommitted.
