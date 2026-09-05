# Review 5 — link expenses to evidence for an MTD quarter

**Reviewed:** 5 September 2026 UTC

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Current milestone:** M1 — evidence pack core

**Implementation reviewed:** `693a7609d2efb23c6567da5de0b425db92029e5c`

**Documentation baseline:** `41a1e5262fdc5639ea907bfd4a776e35e4b27659`

## Verdict

**FAIL — 2 findings and 2 untested public claims.**

The deployed M1 product works, matches implementation `693a7609…`, and passes
the fresh browser, backend, accessibility, performance, and restart checks.
The release cannot pass the claims contract. Three of the 26 exact claim
commands fail from the clean documentation checkout. The Terms page also makes
two billing promises that are absent from `.factory/claims.json` and have no
observable test.

This review does not require M2 accounts, tenant ownership, a completed payment
lifecycle, backups, or M3 reconciliation work. Those remain future milestones.

## Findings

### F-5-1 — High — three live claim commands reject the documentation checkout

The following exact commands fail from a clean detached checkout at
`41a1e5262fdc5639ea907bfd4a776e35e4b27659`:

```text
npm run test:live-workspace-consistency  FAIL
npm run test:live-release                FAIL
npm run test:live-rate-limit             FAIL
```

Each command expects repository HEAD, `41a1e526…`, to be deployed. Live health
and the ready image correctly identify the last implementation candidate,
`693a7609…`. The commits after that candidate contain verification evidence,
the venture plan, handoff text, and Graphify output rather than a new product
image. The commands stop at identity validation before running their declared
workspace or rate-limit probe.

This reopens the exact-command failure condition covered by review 3 findings
F-3-1, F-3-2, and F-3-3, and review 4's F-3-2 regression. The live behavior is
not broken: supplying the accepted implementation SHA made all three probes
pass, and the independent restart check below passed. The declared commands
still fail without that undeclared override, so the claims gate is 23/26.

Required fix: record `693a7609…` as the current implementation in one committed
source of truth. Make each exact command resolve that implementation while
allowing later numbered reports, review evidence, the venture plan, handoff,
and Graphify output. Product or deployment changes must still require a new
image. Add a fixture for the exact `plan.md` descendant now causing the failure.

Evidence: [claim results](evidence/review-5/claims/results.tsv),
[workspace failure](evidence/review-5/claims/23-live-workspace-consistency.log),
[identity failure](evidence/review-5/claims/24-live-release-identity.log),
[rate-limit failure](evidence/review-5/claims/26-live-api-rate-limit.log), and
[successful runtime probes with the implementation SHA](evidence/review-5/live-claims-with-implementation-sha.log).

### F-5-2 — High — two public subscription promises are unlisted and untested

The live `/terms` page says:

> It renews monthly until you cancel.

It also says:

> Subscription billing terms appear before you pay.

Neither promise appears in `.factory/claims.json`. The `hosted-checkout` test
proves the Dodo host, product, GBP 1500 price, and monthly cadence. It does not
complete or observe a renewal, prove cancellation, or assert which billing
terms are shown before payment. The new venture plan explicitly records the
renewal and cancellation lifecycle as unproved M2 work.

These are current legal-page promises, not future plan text. Remove or narrow
them for M1, or add claim entries and tests that prove the stated behavior. A
real payment is not required merely to retain the accepted M1 checkout claim;
it is required before presenting the M2 lifecycle as working.

Evidence: [billing claim audit](evidence/review-5/billing-claim-audit.json).

## First screen before scrolling

Fresh Chromium contexts at 1440×900 and 390×844 answered all three questions:

- Job: **“Link each expense to evidence.”**
- Audience: **UK sole traders, tutors, and small club operators preparing an
  MTD quarterly update.**
- First action: **“Try it with sample data.”**

The next-step text says the action opens a ready quarter and keeps changes in a
24-hour demo. All three items fit in the first viewport. The title is **“MTD
Evidence Rail — link expenses to evidence.”** The live section headings use
plain task names. No banned marketing words, metaphor headings, or inconsistent
transaction terms were found.

Evidence: [desktop result](evidence/review-5/desktop-flow.json),
[phone result](evidence/review-5/mobile-accessibility-privacy.json),
[desktop capture](evidence/review-5/cold-desktop.png), and
[phone demo capture](evidence/review-5/demo-mobile.png).

## One-click sample and core job

One click opened a server-side demo with six realistic transactions, four
linked files, and two missing items. The persistent label says **“Demo — sample
data. Nothing is saved to your private workspace.”** It keeps **Reset demo**
and **Start a private workspace** visible.

The fresh desktop flow proved:

- £0 was rejected, then £0.01 saved successfully;
- a CSV without Amount was rejected with a corrective message;
- a valid two-row CSV flagged one exact date-and-amount match and imported the
  other row;
- an evidence pack downloaded as a ZIP containing `transactions.csv`;
- Reset created a new demo key, restored 6 transactions and 2 missing items,
  and removed both review mutations; and
- normal requests and the complete demo flow produced no console or page
  errors.

A separate seeded-state context retained the private workspace key,
subscription token, and cached verdict unchanged. Every demo request stayed on
the product origin and sent no subscription header. The sample did not read or
change private data.

## Claims

The checkout was a new local clone, detached at documentation SHA `41a1e526…`,
with empty Git porcelain. `npm ci` installed the documented packages first.
All 26 `test` strings were then executed literally and serially.

| Claim | Result |
| --- | --- |
| `demo-isolation` | PASS |
| `no-account` | PASS |
| `workspace-key-recovery` | PASS |
| `workspace-key-auth` | PASS |
| `quarter-capture` | PASS |
| `csv-matching` | PASS |
| `atomic-import` | PASS |
| `calendar-dates` | PASS |
| `evidence-types` | PASS |
| `missing-review` | PASS |
| `demo-sample` | PASS |
| `evidence-pack` | PASS |
| `workspace-delete` | PASS |
| `free-limit` | PASS |
| `paid-limit` | PASS with the declared recorded verdict fixture |
| `hosted-checkout` | PASS; Dodo, GBP 1500, monthly; no purchase made |
| `license-return` | PASS with its declared response fixture |
| `no-trackers` | PASS |
| `runtime-defaults` | PASS |
| `durable-storage` | PASS |
| `shared-state-boundary` | PASS |
| `production-topology` | PASS |
| `live-workspace-consistency` | **FAIL — F-5-1** |
| `live-release-identity` | **FAIL — F-5-1** |
| `api-rate-limit` | PASS |
| `live-api-rate-limit` | **FAIL — F-5-1** |

All 26 ids are unique and each has exactly one `@claim:<id>` marker. Two other
public claims are unlisted under F-5-2. Result: **23 passed, 3 failed, 2
unlisted and untested public claims**.

## Clean quality gates

| Check | Result |
| --- | --- |
| `npm ci` | PASS; 34 packages, 0 vulnerabilities |
| `npm test` | PASS; 9 Rust tests and 25 Chromium tests |
| `npm run lint` | PASS; TypeScript, rustfmt, and Clippy with warnings denied |
| `npm run build` | PASS; `dist/` produced |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=high` | PASS; 0 vulnerabilities |

The production build contains 33,913 bytes of JavaScript, 18,132 bytes of CSS,
102,036 bytes of local fonts, and a 61,374-byte phone hero. Docker and Podman
are unavailable in this reviewer image. The Dockerfile uses `rust:1-slim`, a
multi-stage build, `ARG BUILD_SHA=dev`, a non-root user, and port 8080. The
deployed container was inspected through its product-owned control plane.

Evidence: [quality log](evidence/review-5/clean-quality-gates.log) and
[claim-tag audit](evidence/review-5/claim-tag-audit.json).

## Live backend and deployment

- `/health` returned 200, `status: ok`, and build `693a7609…`.
- The ready image is `sf-mtd-evidence-rail:693a7609d2ef` on one active revision
  and one running replica.
- The Azure Files volume is mounted at `/data`; SQLite uses `unix-dotfile`.
- Local JS and CSS hashes exactly match the live assets.
- Two fresh private workspaces remained separate. A record in workspace A did
  not appear in B. A B-key deletion attempt did not change A.
- Missing and malformed keys returned 401; an unknown 64-character key returned
  404.
- Zero amount, impossible date, unknown kind, and 121-character description
  returned 400. An invalid second import row saved no first row.
- A 5 MiB plus 1 byte file returned 413. A valid text file succeeded afterward.
- Both review workspaces rejected deletion without confirmation, then returned
  204 with confirmation and 404 on the next read.
- Before restart, private and demo workspaces returned 100/100 fresh reads.
  After the product's own revision restart, the demo returned 100/100 reads and
  the deleted private workspace returned 404 on 20/20 reads.
- Three independent 200-request demo waves accepted 25 and limited 175 each.
  Every 429 included `Retry-After: 1`.

M1 has key-separated workspaces, not account tenants. Account identity and a
full two-tenant authorization matrix belong to M2. The current key boundary was
tested without presenting it as M2 tenant isolation.

Evidence: [API boundaries](evidence/review-5/live-api-boundaries.json),
[restart and topology](evidence/review-5/live-restart-topology.log), and
[asset identity](evidence/review-5/live-asset-identity.log).

## Accessibility, routes, privacy, and performance

- Fresh desktop and phone browser checks found no console errors or horizontal
  overflow.
- The skip link was first in keyboard order. The transaction dialog focused
  Type, Escape closed it, and focus returned to Add a transaction.
- Every tested header, footer, and visible button target was at least 44×44 px.
- At 200% text size the 390 px page remained 390 px wide.
- Reduced-motion emulation left no animation running.
- Axe found zero violations on `/`, `/demo`, `/app`, `/privacy`, `/terms`, and
  the designed 404.
- Every route had `lang=en-GB`, one H1, one main landmark, its route-specific
  title, and working legal/footer structure.
- The unknown route deliberately returned HTTP 404 with the designed recovery
  link. It is expected behavior, not a defect.
- All internal links returned 200. Sociobot returned 200. Checkout returned the
  expected 303 to Dodo. Privacy and support use explicit `mailto:` links.
- CSP, HSTS, `nosniff`, referrer policy, permissions policy, and `no-cache`
  headers are present.
- Lighthouse scored 100 performance, 100 accessibility, 100 best practices,
  and 100 SEO. LCP was 1.88 s, TBT 25 ms, CLS 0, and transfer was 181,769 bytes.
- The product makes no offline-use or update claim and has no service worker.
  Its online-only offline notice appeared as designed.
- This is not a CLI, library, desktop app, or installable PWA, so installed
  consumer-artifact checks do not apply.

Evidence: [live Playwright, 24/24 applicable tests](evidence/review-5/live-playwright.log),
[browser/accessibility audit](evidence/review-5/mobile-accessibility-privacy.json),
[link audit](evidence/review-5/link-audit.json),
[root URL check](evidence/review-5/root/verify.json),
[demo URL check](evidence/review-5/demo/verify.json), and
[Lighthouse](evidence/review-5/lighthouse-summary.json).

## Earlier review findings

Every prior review finding was checked in current source and live behavior.

| Finding | Current disposition |
| --- | --- |
| F-1-1 demo touched private subscription state | Fixed. Seeded private values stayed unchanged; demo stayed same-origin and sent no licence header. |
| F-1-2 unlisted HMRC and tax promise | Fixed. The quoted promise remains absent. |
| F-1-3 decorative landing label | Fixed. The label names MTD quarter evidence. |
| F-1-4 inconsistent transaction term | Fixed. Current copy uses transaction. |
| F-1-5 vague headings | Fixed. Current headings name their content. |
| F-1-6 README length and deployment jargon | Fixed. No quoted jargon or over-22-word sentence remains. |
| F-1-7 broad network-only promise | Fixed. The broad promise is absent; demo traffic was independently same-origin. |
| F-2-1 split live workspace state | Fixed in runtime. Fresh reads and restart persistence passed. |
| F-2-2 sample absent from first phone screen | Fixed. “Teaching card supplies” ended at 363 px in an 844 px viewport. |
| F-2-3 narrowed audience | Fixed. Landing and README name the same three audiences. |
| F-2-4 unlisted “every quarter” promise | Fixed. The phrase remains absent. |
| F-2-5 unlisted refund promise | Fixed. The promise remains absent. |
| F-2-6 unlisted private API key boundary | Fixed. The claim and route matrix pass. |
| F-2-7 vague CSP promise | Fixed. The copy is absent; live response headers pass. |
| F-2-8 unlisted runtime statements | Fixed. Current runtime statements map to tests. |
| F-2-9 untested sample composition | Fixed. Counts pass before and after reset. |
| F-2-10 unlisted SQLite layout statement | Fixed. README states tested restart behavior. |
| F-2-11 heading did not match its section | Fixed. “What this tool covers” matches its content. |
| F-2-12 rate-limit jargon | Fixed. Current copy describes temporary blocking plainly. |
| F-2-13 misleading checkout action | Fixed. The action says “Open £15/month checkout.” |
| F-2-14 no workspace recovery | Fixed. Copy and reopen tests pass. |
| F-3-1 live workspace command failure | **Regressed under F-5-1.** Runtime passes with the implementation SHA, but the exact command fails at docs HEAD. |
| F-3-2 live release command failure | **Regressed under F-5-1.** Live identity is correct; the exact command expects docs HEAD. |
| F-3-3 live rate command failure | **Regressed under F-5-1.** Runtime 429 behavior passes; the exact command stops before its probe. |
| F-3-4 vague “Start for real” | Fixed. The action says “Start a private workspace.” |
| F-4-1 unlisted comparative limiter claim | Fixed. The comparison remains absent. |
| F-4-2 “namespace” jargon | Fixed. Current wording directly states demo/private separation. |

## Earlier verification findings

| Reports | Earlier issue | Current evidence |
| --- | --- | --- |
| 1, 2, 3, 5, 7, 10, 11 | Split or temporary SQLite state broke demo, records, or deletion. | One replica and `/data` mount; 100/100 reads before and after restart; confirmed deletion stayed deleted. |
| 6, 12, 13, 15, 16, 17, 18, 20 | Candidate, image, revision, or topology identity drift; live claim guards failed. | Live health, image, active revision, topology, and asset hashes match `693a7609…`. The new docs-HEAD command regression is separately reported as F-5-1. |
| 1, 4 | Checkout unavailable, limit bypass, wrong one-time cadence, and incomplete price test. | Dodo checkout, product id, GBP 1500, monthly cadence, server limit, and recorded valid-verdict behavior pass. Full billing lifecycle remains M2. |
| 1, 3 | Missing or absolute claims, including unlimited and “unguessable”. | Those absolutes remain absent and the 26 listed ids each have one tag. New legal-page gaps are F-5-2. |
| 1 | TypeScript failed; import was partial; dates were shape-only. | Typecheck passes; atomic import and calendar validation pass live and locally. |
| 1, 3, 4 | Contrast, touch targets, banner landmark, metaphor headings, and 200% overflow. | Zero axe violations, 44 px targets, complementary demo landmark, plain headings, and no 200% overflow. |
| 1, 17 | Soft 404, stale unversioned caching, and missing HSTS. | Designed HTTP 404, one-hour revalidation, and one-year HSTS pass. |
| 5, 10, 11, 17 | Replica-multiplied or unstable request allowance. | One limiter is active; three 200-request waves returned 175 HTTP 429 responses each with `Retry-After: 1`. |
| 8, 9, 14, 19, 21 | Passing verification rounds. | No runtime regression was found. The present failure is the post-verification claims/docs mismatch and the two legal claims. |

## Current milestone and external dependencies

M1 remains the current implemented milestone. Its capture, evidence, CSV
review, missing-evidence queue, export, deletion, and key-separated demo work
end to end. This review does not promote M2 or M3 features to shipped status.

| External dependency | Current status | Effect |
| --- | --- | --- |
| Sociobot Entra CIAM registration and test identities | Unavailable | M2 sign-in and tenant ownership remain unshipped. Not an M1 defect. |
| Sociobot billing lifecycle sandbox | Checkout is reachable; purchase, renewal, cancellation, expiry, and revocation are not proven | Blocks M2 paid-service acceptance. It also makes the two current Terms promises findings. |
| Dodo Payments | Reached only through Sociobot checkout | No product-owned integration or credential is required. |
| Fleet `/data` mount | Available and freshly verified | M1 persistence passes. Future deployments must preserve one replica and the mount. |
| Fleet backup and restore | No accepted restore drill | Blocks the M2 backup requirement. Restart persistence is not a backup. |
| Transactional messaging | Unavailable and not promised | Not required through M3. |
| HMRC access or certification | Unavailable and out of scope | Not an M1–M3 blocker; the product does not present filing as shipped. |
| Pilot users and a redacted CSV corpus | Not yet evidenced | Needed for M3 matching validation and the venture success measure, not M1. |

## Final decision

**FAIL.** Finding count: **2**. Untested public claim count: **2**. The live M1
runtime has no observed product defect, but a PASS requires all exact claim
commands to pass and every public claim to be listed and tested.
