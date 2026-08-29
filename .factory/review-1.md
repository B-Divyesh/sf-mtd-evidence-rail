# Adversarial first-read review 1 — FAIL

**Reviewed:** 29 August 2026
**Live URL:** <https://mtd-evidence-rail.sociobot.in>
**Source commit:** d1470eb88c9c4964b357758b481381ca66feacbd
**Live build:** 8c2d0755f2ea2987332f1c97939c66bcb64ec56b

## Verdict

**FAIL.** The sample is clear and works for a new visitor, but demo mode is not
an isolated sandbox when the browser already contains a real subscription
token. It reads real local storage, sends the token to Sociobot, and writes the
real licence cache while the demo banner says nothing is saved. This is
blocking. The landing and README also contain unlisted claims and plain-word
copy failures.

## Cold first read

Fresh Chromium contexts at 390 × 844 and 1440 × 1000 required no scroll.

- **What it does:** “Link each expense to evidence.”
- **For whom:** “For sole traders who need a reviewable record before each MTD
  quarterly update.”
- **Click first:** “Try it with sample data,” with “See a ready quarter.
  Nothing is saved.”

This mandatory first-read gate passes. At 390 px, the CTA was 366 × 55 px,
there was no horizontal overflow, and cold load had no console errors.

## Findings

### F-1-1 — BLOCKING — Demo reads and writes real subscription state

**Location:** live /demo and frontend/src/main.ts: api() always reads
localStorage.getItem(LICENSE_KEY); captureLicense() reads and may update the
same real keys before rendering a route.

**Exact conflicting copy:** “Demo — sample data, nothing is saved to your
workspace.”

**Reproduction:** In a fresh context, set only the real
sb_license:mtd-evidence-rail local-storage key to real-subscription-token, then
open /demo. The product correctly made a separate demo:… session key, but it
also:

- sent X-License-Key: real-subscription-token on the demo
  /api/workspace?... request;
- requested https://api.sociobot.in/api/v1/products/mtd-evidence-rail/verify?license=real-subscription-token;
- wrote sb_license_cache:mtd-evidence-rail in real local storage while the demo
  banner was visible.

**Why this blocks:** The demo contract says real data is never read or written
in demo mode. A real subscription token and cache are real user data. The
existing @claim:demo-isolation test only checks the private workspace key, so
it cannot prove the advertised sandbox boundary.

**Fix:** In demo mode, never read, write, or send real licence keys or cache.
Use only a demo: namespace for a canned entitlement, or omit the licence header
and restoration controls. Extend @claim:demo-isolation to seed real workspace
and licence keys, assert they stay unchanged, assert no real key is in a
request header, and assert all demo requests are same-origin. Then change the
banner to “Demo — sample data. Changes stay in this 24-hour demo.”

### F-1-2 — BLOCKING — HMRC no-filing/no-tax promise is unlisted

**Location:** landing, “This record aid does not file with HMRC.” and “It does
not calculate tax or send an update to HMRC.” README: “It does not calculate
tax or file with HMRC.”

**Why this blocks:** These are reliance claims, but .factory/claims.json has no
no-filing/no-tax entry or sandbox assertion. The claims contract requires one
for every claim-like sentence.

**Fix:** Add a no-hmrc-filing claim that runs the full demo flow, asserts no HMRC
request, and asserts no filing action or endpoint exists. If that boundary
cannot be proved, use the narrower product description: “Use this to organise
evidence before you file your own update.”

### F-1-3 — Medium — Decorative, non-informative landing label

**Location:** “QUARTERLY EVIDENCE, IN ORDER”.

**Why it fails:** This is a mood slogan, not a section name or instruction.

**Fix:** Delete it or use “Evidence for your MTD quarter”.

### F-1-4 — Medium — Inconsistent term for transaction

**Location:** “Bank lines, invoices, and receipts share one dated view.”

**Why it fails:** The documented terminology calls the financial item a
**transaction**. “Bank lines” is a second term and excludes manually entered
income.

**Fix:** “Transactions, invoices, and receipts appear in one dated view.
Missing evidence stays visible until you link it.”

### F-1-5 — Medium — Vague, untestable headings

**Location:** “Clear boundaries” and “Your records stay under your control”.

**Why it fails:** Neither names its section when heard alone. “Under your
control” is a vague reassurance.

**Fix:** Rename to “What this record tool does not do” and “Workspace privacy,
export, and deletion”.

### F-1-6 — Medium — README sentence is 28 words and deployment jargon

**Location:** “The work-order deployment is wrapped by scripts/deploy.sh; it
mounts Azure Files at /data and pins the app to one replica because SQLite is a
single-writer database.”

**Why it fails:** It exceeds 22 words and mixes internal infrastructure terms
into basic product instructions.

**Fix:** Move this implementation detail to handoff. In README write:
“Production uses one app instance. Its database is stored on the mounted
/data volume.”

### F-1-7 — Medium — README network-boundary claim is not tested

**Location:** “The product contacts api.sociobot.in only to verify subscription
access or start checkout.”

**Why it fails:** no-trackers records a clean demo only. It does not exercise
stored licence state or prove the stated “only” boundary; F-1-1 demonstrates
the missing case.

**Fix:** Add an allowlist request-log claim covering stored licence and checkout
handoff, or reduce the copy to a demonstrated claim after F-1-1 is fixed.

## Demo and functional evidence

For a new browser, one click opened a ready Q1 2026 workspace with six
realistic transactions, four linked files, and two missing-evidence rows. The
persistent banner, **Reset demo**, and **Start for real** appeared. Reset
changed the demo: session key, left the private workspace key absent, and
loaded the sample again. Start for real created a separate 64-character private
key and empty workspace. Missing-evidence review showed exactly the two
unlinked rows.

The clean demo request log was same-origin. The seeded-real-licence request log
had both the product origin and https://api.sociobot.in; that is the blocking
exception above.

## Claims and quality gates

A fresh clone received npm ci. Every exact command in .factory/claims.json
passed: demo-isolation, no-account, quarter-capture, csv-matching,
atomic-import, calendar-dates, evidence-types, missing-review, evidence-pack,
workspace-delete, free-limit, paid-limit, hosted-checkout, license-return,
no-trackers, runtime-defaults, durable-storage, shared-state-boundary,
production-topology, and api-rate-limit.

hosted-checkout observed HTTP 303 to Dodo for mtd-evidence-rail, GBP 1500,
monthly. Full npm test passed typecheck, build, four Rust tests, runtime and
storage checks, and 21 Playwright tests. npm run build produced dist/
(30.36 kB JS raw; 10.31 kB gzip). Passing tests do not resolve F-1-1 or
unlisted claims.

## Earlier history

I read .factory/handoff.md, .factory/verification.md, and
.factory/verification-2.md through .factory/verification-8.md. No prior
review-* or polish-* file exists. The historical split-workspace, paid-limit,
atomic-import, date-validation, typecheck, contrast, touch-target, soft-404,
and cache findings are fixed in current source/live behavior: the full suite
passed, checkout reaches Dodo, an unknown live route returns designed HTTP 404,
and the 390 px cold landing had no overflow or console error. F-1-1 is a new
reproduced sandbox defect.

## Structure and missed leverage

The following checks pass: route-specific product-and-purpose titles; one H1,
main, lang=en-GB, description, canonical, OG, favicon, and apple touch
metadata; 200 for /, /demo, /app, /privacy, /terms; designed HTTP 404; working
landing, checkout, and factory links; H1 focus on SPA navigation and Back;
consistent privacy/terms header/footer; header CSP frame-ancestors 'none'; and
product-specific paper-cut railway art, local fonts, ticket shapes, and
palette. Import, missing-evidence review, export, and private storage are
present. The brief does not imply an AI action, so no AI feature is missing
leverage.

## Copy audit

Word counts are per visible sentence or label. † identifies a finding above.
No landing sentence exceeds 22 words. Buttons use result-naming verbs.

### Landing

| Copy | Words | Result |
| --- | ---: | --- |
| Quarterly evidence, in order | 4 | † F-1-3 |
| Link each expense to evidence | 5 | clear H1 |
| For sole traders who need a reviewable record before each MTD quarterly update. | 13 | clear |
| Try it with sample data | 5 | action |
| See a ready quarter. / Nothing is saved. | 4 / 3 | F-1-1 affects second promise |
| Start a private workspace | 4 | action |
| Your workspace needs no account. | 5 | no-account |
| £15/month for more than 25 transactions. | 7 | pricing |
| This record aid does not file with HMRC. | 8 | † F-1-2 |
| A quarter at a glance / See what still needs evidence | 5 / 5 | useful headings |
| Bank lines, invoices, and receipts share one dated view. | 9 | † F-1-4 |
| Missing files stay visible until you link them. | 8 | missing-review |
| 6 Apr – 5 Jul 2026; Capture; Match; Review; Export | 5; 1; 1; 1; 1 | preview labels |
| Quarter record; 6 transactions; 2 need evidence | 2; 2; 3 | sample data |
| Teaching card supplies; Materials · £32.99; Evidence linked | 3; 3; 2 | sample data |
| Train to client session; Travel · £27.80; Evidence missing | 4; 3; 2 | sample data |
| Spring maths tutoring; Invoice INV-026 · £120.00; Evidence linked | 3; 4; 2 | sample data |
| How it works / Prepare the quarter while it happens | 3 / 6 | useful headings |
| Add each transaction / Link the evidence / Export the evidence pack | 3 / 3 / 4 | clear steps |
| Record income or expenses. / You can also import a bank CSV. | 5 / 6 | clear |
| Add a receipt, invoice, or note. / Likely CSV matches are flagged before import. | 6 / 7 | clear / csv-matching |
| Download one ZIP with a transaction CSV and every linked file. | 11 | evidence-pack |
| Clear boundaries | 2 | † F-1-5 |
| A record aid, not tax software | 6 | useful boundary |
| MTD Evidence Rail helps you organise source records. | 7 | description |
| It does not calculate tax or send an update to HMRC. | 12 | † F-1-2 |
| Your records stay under your control | 6 | † F-1-5 |
| Workspace keys are stored on this device. | 7 | no-account |
| Demo records use a separate 24-hour workspace. | 7 | F-1-1 coverage gap |
| You can export or delete your workspace. | 7 | declared claims |
| No advertising trackers or third-party scripts run here. | 8 | no-trackers |
| Monthly subscription / Use one workspace for every quarter | 2 / 6 | useful headings |
| The free workspace accepts 25 transactions in a quarter. | 9 | free-limit |
| A £15/month subscription accepts more than 25. | 8 | paid-limit |
| £15 / per month | 1 / 2 | price |
| The server verifies an active subscription before accepting more than 25 transactions. | 12 | paid-limit |
| Receipt and invoice evidence; Bank CSV review; Accountant evidence packs | 4; 3; 3 | feature labels |
| Start monthly subscription | 3 | action |
| Sociobot and Dodo handle subscription checkout and refunds. / See the terms. | 8 / 3 | checkout / link |
| Have a subscription token? Paste it here. / Restore subscription access | 7 / 3 | prompt / action |
| Footer: Link each expense to evidence before your quarterly update. | 9 | clear |
| Footer: Built by Param Factory. | 4 | attribution |
| Footer: Version 1.0 · Build 2026.08 · Generated hero imagery is original to this product. | 10 | provenance |

### README

| Copy | Words | Result |
| --- | ---: | --- |
| Link each expense to evidence before your quarterly update. | 9 | clear |
| MTD Evidence Rail is for UK sole traders, tutors, and small club operators. | 13 | clear |
| It keeps transactions, receipts, and invoices together without adding a full accounting suite. | 13 | description |
| It does not calculate tax or file with HMRC. | 9 | † F-1-2 |
| Adds income and expenses to a dated quarter view. | 9 | clear |
| Imports bank CSV files and flags likely amount-and-date matches before import. | 11 | clear |
| Links PDF, JPG, PNG, WebP, or text evidence to a transaction. | 10 | declared claim |
| Keeps missing evidence visible as a separate review queue. | 9 | declared claim |
| Exports a ZIP evidence pack with a transaction CSV and linked files. | 12 | declared claim |
| Deletes a workspace and its files on request. | 8 | declared claim |
| A workspace needs no account. / Its 64-character key stays in the browser. | 5 / 6 | declared claim |
| The free plan accepts 25 transactions per quarter. / A £15/month subscription accepts more than 25. | 8 / 7 | declared claims |
| Checkout and subscription checks use the Sociobot billing API and open a Dodo-hosted checkout. | 13 | checkout claim |
| Open the sample workspace, or use localhost locally. | 8 | clear |
| It contains six realistic transactions, four linked files, and two missing items. | 12 | sample description |
| Demo workspaces are separate from private workspaces and expire after 24 hours. | 12 | F-1-1 gap |
| See .factory/demo.md. | 3 | clear |
| Requirements: Node 22+, current stable Rust, and SQLite build support. | 10 | clear |
| Open localhost. / The server starts with no required environment variables. | 2 / 8 | clear / claim |
| PORT defaults to 8080, DATA_DIR to data, and STATIC_DIR to dist. | 11 | clear |
| For frontend work, run the API and npm run dev in separate terminals. / Vite proxies /api and /health to port 8080. | 13 / 7 | clear |
| npm test builds the frontend, runs the Rust tests, starts the complete server, and runs Playwright in Chromium. | 16 | clear |
| Claim tests are listed in .factory/claims.json. | 5 | clear |
| Records and evidence are stored in SQLite under DATA_DIR. | 8 | declared claim |
| Production mounts that directory from Azure Files and runs one replica, so every request reaches the same durable database. | 18 | declared claim |
| Its deployment-only SQLITE_VFS=unix-dotfile setting uses lock files supported by SMB; the one-replica policy remains mandatory. | 15 | internal jargon; move to handoff |
| A 64-character workspace key scopes every API request. | 9 | clear |
| Demo keys use a separate browser and database namespace. | 9 | F-1-1 gap |
| API endpoints enforce per-IP burst limits and respect the first X-Forwarded-For hop. | 14 | declared claim |
| Security headers include a restrictive CSP. | 6 | security statement |
| There are no advertising trackers or third-party runtime scripts. | 9 | declared claim |
| The product contacts api.sociobot.in only to verify subscription access or start checkout. | 13 | † F-1-7 |
| The server enforces the free quarter limit even if browser storage is changed. | 12 | declared claim |
| See /privacy and /terms in the running product. | 8 | clear |
| The root Dockerfile builds the Vite frontend and Rust server in separate stages. | 12 | implementation detail |
| The runtime image runs as a non-root user, reads PORT, and serves /health with the supplied BUILD_SHA. | 18 | implementation detail |
| The work-order deployment is wrapped by scripts/deploy.sh; it mounts Azure Files at /data and pins the app to one replica because SQLite is a single-writer database. | 28 | † F-1-6 |
| The source-owned container-app contract is applied after the factory image rollout. | 11 | internal detail |
| Deployment fails unless control-plane topology, cross-request reads, one shared limiter, 12 fresh browsers, and restart persistence pass. | 16 | internal jargon; move to handoff |
| The factory owns product registration and billing configuration. | 7 | clear ownership |
| Generated hero artwork is original to this product. / Its prompt and provenance are recorded in .factory/design.md. | 7 / 8 | provenance |

## What would make this perfect

Make demo mode a real storage and network sandbox even with existing private
workspace and subscription state, and prove it in the claim test. Then test or
remove the HMRC and network-boundary promises, and apply the four copy rewrites.
A later review can pass only with zero findings.
