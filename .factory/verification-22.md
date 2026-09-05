# Verification 22 — link expenses to evidence for an MTD quarter

**Work order:** `mtd-evidence-rail-verify-22`

**Verified:** 5 September 2026 UTC

**Current milestone:** M1 — evidence pack core; independent acceptance

**Implementation candidate:** `f87a563751c31cd5ca612f396d86c59c6c5d76b9`

**Tested documentation baseline supplied:** `bc7c440f961bec611820c35b4faae5e7382e354d`

**Final repair report supplied:** `2f9cd4bb49dbd8680db4caef5018d3f6c95d7776`

**Clean verification checkout:** `aafbf2ca327191b19f670303b1c0fd7450bd8410`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

## Verdict

**FAIL — do not accept this release.**

- Findings: **1 high, 0 critical, 0 medium, 0 low**.
- Declared claim commands: **23 passed, 3 failed**.
- Untested public claims: **0**.
- Unlisted public claims: **0**.

The M1 product behavior works and the live JavaScript and CSS are byte-identical
to the implementation candidate. Acceptance still fails because the public
service is serving an unrecorded report/Graphify wrapper image.
Live health and the ready image now identify `aafbf2ca…`, while
`.factory/release.json` and the work order identify `f87a563…`. The three exact
live claim commands stop at that identity guard.

This is a release-control finding. It does not require a product-code repair.

## Finding

### F-22-1 — High — the live image does not identify the recorded implementation

At verification time the live service reported:

```text
health build: aafbf2ca327191b19f670303b1c0fd7450bd8410
ready image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:aafbf2ca3271
revision: sf-mtd-evidence-rail--0000075
mode: Single
replicas: 1/1; running: 1
storage: Azure Files mounted at /data
SQLite VFS: unix-dotfile
```

The release record requires `f87a563…`, and the supplied handoff says revision
`0000074` still serves that build. Therefore these commands failed exactly as
declared:

```text
npm run test:live-workspace-consistency
npm run test:live-release
npm run test:live-rate-limit
```

Each reported `expected_sha=f87a563…` and `live_sha=aafbf2c…` before its
functional probe. This is the same class of exact-command failure previously
reported as F-5-1.

The difference from `f87a563…` to `aafbf2c…` contains only `.factory` reports,
the release record, venture-plan text, and Graphify output. It contains no
frontend, backend, dependency, migration, Docker, or deployment-contract
change. The live JavaScript and CSS hashes match the clean candidate build.

Separate diagnostics using the explicitly observed wrapper SHA passed:

- `/health`, ready image, revision, one replica, `/data`, and VFS agreed;
- new private and demo workspaces each returned 100/100 fresh reads;
- three 200-request limiter waves returned 176, 176, and 175 HTTP 429 responses;
- every 429 included `Retry-After: 1`; and
- a product-only restart preserved 100/100 demo reads and 20/20 deleted-state
  reads, followed by 12/12 successful fresh demo browsers.

Those diagnostics prove that the runtime behavior is sound. They do not turn
the three failed declared commands into passes.

Required disposition: restore the recorded `f87a563…` image as the ready image,
or deliberately record and accept a different implementation through the
normal release process. Then rerun all three exact live commands. Do not change
product code merely to address this finding.

Evidence: `/work/.evidence/verification-22/claims/23-live-workspace-consistency.log`,
`24-live-release-identity.log`, `26-live-api-rate-limit.log`,
`live-current-wrapper-diagnostic.log`, and
`/work/.evidence/verification-22/browser/live-restart-topology.log`.

## First screen before scrolling

Fresh 1440×900 and 390×844 browser contexts answered the required questions
without scrolling:

- Job: **Link each expense to evidence**.
- Audience: **UK sole traders, tutors, and small club operators preparing an
  MTD quarterly update**.
- First action: **Try it with sample data**.

The title is **MTD Evidence Rail — link expenses to evidence**. The adjacent
text says the action opens a ready quarter in a 24-hour demo. All three plain
facts were inside both first viewports. No metaphor heading or vague first
action was found.

Evidence: `browser/fresh-context-audit.json`, `desktop-cold.png`, and
`phone-cold.png` under `/work/.evidence/verification-22`.

## One-click sample, reset, and real-data isolation

The sample loaded in one click with six realistic transactions, four linked
files, and two missing items. The persistent label says **Demo — sample data.
Nothing is saved to your private workspace.** It keeps **Reset demo** and
**Start a private workspace** visible.

Reset issued a fresh demo key and restored the 6/4/2 counts. Seeded private
workspace, subscription token, and cached-verdict values were unchanged.
Direct demo traffic stayed same-origin and sent no subscription header. No
console or page error occurred on desktop or phone.

## Normal, invalid, boundary, and recovery paths

Independent live checks passed:

- £0 showed **Enter an amount greater than zero**; £0.01 then saved.
- A CSV missing Amount showed a corrective error.
- A valid two-row CSV marked one amount-and-date match and imported only the
  new row.
- Reset removed both test mutations and restored the sample.
- Impossible dates returned 400; an invalid mixed import saved no row.
- PDF, JPG, PNG, WebP, and text evidence worked at 5 MiB; 5 MiB plus one byte
  returned 413.
- The free 26th transaction returned 402, while the recorded active-verdict
  fixture allowed 26.
- ZIP export contained `transactions.csv` and linked evidence.
- Missing and unknown private keys were rejected; key recovery reopened the
  same records.
- Workspace deletion required confirmation and the deleted key returned 404.

Two fresh private workspaces were also exercised. A record created in A was
absent from B. A delete attempt using B's valid key did not remove A's record.
This proves the shipped M1 workspace-key boundary; it is not M2 account-tenant
isolation.

Evidence: `browser/normal-invalid-recovery.json`, `workspace-isolation.json`,
and `live-playwright.log` under `/work/.evidence/verification-22`.

## Claims gate

The repository has 26 unique claim ids and exactly one `@claim:<id>` marker for
each across tests, scripts, and backend source. I created a detached clean
checkout at `aafbf2c…`, confirmed empty Git porcelain, ran `npm ci`, and then
ran every declared `test` string literally and serially.

| # | Claim | Exact command result |
| ---: | --- | --- |
| 1 | `demo-isolation` | PASS |
| 2 | `no-account` | PASS |
| 3 | `workspace-key-recovery` | PASS |
| 4 | `workspace-key-auth` | PASS |
| 5 | `quarter-capture` | PASS |
| 6 | `csv-matching` | PASS |
| 7 | `atomic-import` | PASS |
| 8 | `calendar-dates` | PASS |
| 9 | `evidence-types` | PASS |
| 10 | `missing-review` | PASS |
| 11 | `demo-sample` | PASS |
| 12 | `evidence-pack` | PASS |
| 13 | `workspace-delete` | PASS |
| 14 | `free-limit` | PASS |
| 15 | `paid-limit` | PASS with the declared recorded verdict fixture |
| 16 | `hosted-checkout` | PASS — Dodo, GBP 1500, monthly; no purchase made |
| 17 | `license-return` | PASS with the declared response fixture |
| 18 | `no-trackers` | PASS |
| 19 | `runtime-defaults` | PASS |
| 20 | `durable-storage` | PASS |
| 21 | `shared-state-boundary` | PASS |
| 22 | `production-topology` | PASS |
| 23 | `live-workspace-consistency` | **FAIL — F-22-1** |
| 24 | `live-release-identity` | **FAIL — F-22-1** |
| 25 | `api-rate-limit` | PASS |
| 26 | `live-api-rate-limit` | **FAIL — F-22-1** |

All observable behavior behind the three failed commands was subsequently
exercised against the actual live wrapper. Accordingly there are zero untested
claims, but the claims gate remains 23/26 because exact command failures cannot
be waived.

Landing, app, privacy, terms, README, and demo text were mapped to the manifest.
No unlisted public promise was found. `/terms` no longer promises renewal,
cancellation, or pre-payment disclosures.

## Clean quality gates

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — 9 Rust tests and 27 Chromium tests |
| `npm run lint` | PASS — TypeScript, rustfmt, and warning-denied Clippy |
| `npm run build` | PASS — `dist/` produced |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=high` | PASS — 0 vulnerabilities |

The build produced 33.87 kB JavaScript raw / 11.04 kB gzip and 18.13 kB CSS
raw / 5.01 kB gzip. Docker and Podman were unavailable. The Dockerfile remains
multi-stage, uses `rust:1-slim`, declares `ARG BUILD_SHA=dev`, runs as UID
10001, exposes 8080, and the independently compiled payloads pass.

## Accessibility, privacy, routes, and performance

- The production-compatible live suite passed 26/26 tests.
- Axe found zero violations on `/`, `/demo`, `/app`, `/privacy`, `/terms`, and
  the designed 404.
- The URL verifier passed root and demo with `lang=en-GB`, one H1, one main,
  complete image alternatives, labelled buttons, and zero console errors.
- Keyboard order starts with the skip link. Dialog initial focus, Escape, focus
  return, and visible focus treatment pass.
- Visible tested controls meet 44×44 px. At 390 px and 200% text there was no
  horizontal overflow.
- Reduced-motion contexts had zero running animation.
- Every route has its own title and one H1. The unknown route deliberately
  returned HTTP 404 with a designed way home; that expected 404 is not a defect.
- All internal links and the Param Factory link returned 200. Mail links are
  explicit. The checkout behavior is covered by its live claim.
- `robots.txt`, `sitemap.xml`, favicon, touch icon, and social image returned
  200.
- CSP, one-year HSTS, `nosniff`, referrer policy, permissions policy, and
  no-cache HTML headers are present.
- Demo traffic was same-origin, used no tracker or third-party script, and did
  not send private or subscription credentials.
- Privacy and Terms describe hosted records, key handling, deletion, export,
  supported files, and the tested monthly checkout without claiming M2 work.
- The product makes no offline-use or update-install promise. Its online-only
  recovery notice and asset revalidation test pass; no service worker exists.
- Mobile Lighthouse scored **100 performance, 100 accessibility, 100 best
  practices, and 100 SEO**. FCP was 1.1 s, LCP 1.9 s, TBT 0 ms, CLS 0, and
  transfer was 181,690 bytes.

No runtime AI is needed for M1. Deterministic amount-and-date matching is the
appropriate explainable action, so the missed-leverage check found no missing
AI feature.

## Earlier review finding disposition

| Finding | Current disposition |
| --- | --- |
| F-1-1 demo touched private subscription state | Fixed; seeded private and subscription state stayed unchanged, with same-origin demo traffic and no licence header. |
| F-1-2 unlisted HMRC/tax promise | Fixed; removed copy remains absent. |
| F-1-3 decorative label | Fixed; the label names MTD quarter evidence. |
| F-1-4 inconsistent transaction term | Fixed; current copy uses transaction. |
| F-1-5 vague headings | Fixed; headings name their sections. |
| F-1-6 README length and deployment jargon | Fixed; the removed wording remains absent. |
| F-1-7 broad network-only promise | Fixed; the broad promise is absent and scoped demo privacy passes. |
| F-2-1 split live workspace state | Fixed at runtime; one replica, fresh reads, and restart persistence pass. |
| F-2-2 sample absent from first phone screen | Fixed; the sample quick look is visible on the 390×844 phone. |
| F-2-3 narrowed audience | Fixed; the full audience is above the fold. |
| F-2-4 unlisted every-quarter promise | Fixed; removed wording remains absent. |
| F-2-5 unlisted refund promise | Fixed; removed wording remains absent. |
| F-2-6 unlisted private API boundary | Fixed; the claim and live route matrix pass. |
| F-2-7 vague CSP promise | Fixed; copy is absent and response headers pass. |
| F-2-8 unlisted runtime statements | Fixed; current runtime statements map to tests. |
| F-2-9 untested sample composition | Fixed; 6/4/2 passes before and after reset. |
| F-2-10 unlisted SQLite layout | Fixed; public copy states tested restart behavior. |
| F-2-11 mismatched section heading | Fixed; “What this tool covers” matches its content. |
| F-2-12 rate-limit jargon | Fixed; public wording is plain and runtime allowance passes. |
| F-2-13 misleading checkout action | Fixed; the action says “Open £15/month checkout.” |
| F-2-14 no workspace recovery | Fixed; copy, key validation, and reopen behavior pass. |
| F-3-1 live workspace command failure | **Reopened as F-22-1 by the new unrecorded live wrapper.** |
| F-3-2 live release command failure | **Reopened as F-22-1 by the new unrecorded live wrapper.** |
| F-3-3 live rate command failure | **Reopened as F-22-1 by the new unrecorded live wrapper.** |
| F-3-4 vague “Start for real” | Fixed; the action says “Start a private workspace.” |
| F-4-1 unlisted comparative limiter claim | Fixed; removed comparison remains absent. |
| F-4-2 “namespace” jargon | Fixed; the replacement directly states demo/private separation. |
| F-5-1 three exact live commands rejected docs HEAD | The repair works for a report/Graphify checkout, but the later wrapper was deployed and reopens the runtime mismatch as F-22-1. |
| F-5-2 untested renewal, cancellation, and pre-payment promises | Fixed; all three promises are absent from live Terms and the regression passes. |

## Earlier verification finding disposition

| Earlier reports | Finding class | Current disposition |
| --- | --- | --- |
| 1, 2, 3, 5, 7, 10, 11 | Split or temporary SQLite state, unreliable deletion, and multiplied limits | Fixed at runtime: one replica, `/data`, 100/100 reads, persistent deletion, restart survival, and one-process limiter bounds pass. |
| 1 | TypeScript failure, partial import, impossible dates, legal contrast, small targets, pinned Rust, soft 404, stale assets | Fixed: typecheck, atomic import, date rejection, zero axe violations, 44 px checks, `rust:1-slim`, HTTP 404, and revalidation pass. |
| 3 | Absolute unlimited/unguessable claims, small inline targets, metaphor headings | Fixed: absolutes and metaphor headings are absent; target checks pass. |
| 4 | Wrong one-time cadence, incomplete price test, banner landmark, 200% overflow | Fixed: monthly GBP 1500 checkout test, complementary banner, and 200% layout pass. |
| 5 | Deletion appeared successful while data remained; allowance multiplied | Fixed in current runtime and across restart. |
| 6, 12, 13, 15, 16, 17, 18, 20 | Candidate/image/revision/topology drift and stale live guards | Topology is safe and product assets match, but identity drift is **reopened as F-22-1**. |
| 17 | First limiter run timed out; HSTS missing | Fixed in runtime: all 600 diagnostic responses completed with 429 headers; HSTS is present. Exact current claim still fails earlier on F-22-1. |
| 20 | Demo banner lacked “nothing is saved” | Fixed; exact required wording is persistent. |
| 8, 9, 14, 19, 21 | Passing verification rounds | Product behavior remains passing; the current failure is later deployment identity drift. |

## Current milestone and external dependencies

M1 is the only implemented milestone. Capture, evidence linking, CSV review,
missing-evidence review, export, deletion, isolated demo, workspace-key
separation, durable SQLite, and request limits work. This report does not
present M2 or M3 as shipped.

| External dependency | Current status | Milestone effect |
| --- | --- | --- |
| Sociobot Entra CIAM registration and test identities | Not available | M2 accounts, ownership, memberships, and true tenant isolation remain unshipped; not an M1 defect. |
| Sociobot billing lifecycle sandbox | Checkout is proven; purchase, renewal, cancellation, expiry, and revocation are not | Blocks M2 paid-service acceptance; not promised by current Terms. |
| Dodo Payments | Reached only through the Sociobot checkout | No direct product integration or credential is needed. |
| Fleet `/data` mount | Available and restart-tested | M1 persistence passes. |
| Fleet backup and isolated restore | No accepted restore drill | Required in M2; restart persistence is not a backup. |
| Pilot users and redacted CSV corpus | Not yet evidenced | Needed for M3 matching validation and the venture success measure. |
| HMRC filing or certification | Unavailable and out of scope | Not an M1–M3 blocker; the product does not claim filing. |

## Final decision

**FAIL. Finding count: 1. Untested claim count: 0.** The live M1 behavior has
no observed product defect, but three mandatory exact claim commands fail
because the ready build is not the recorded implementation.
