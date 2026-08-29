# Adversarial first-read review 2 — FAIL

**Reviewed:** 29 August 2026

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Source commit:** `4902a0c9597df3d3ad5b4052d007cbc6f86f35d5`
**Live build:** `c088767e95c03bf45f72f36f8bef5b1ecf7a71cc`

## Verdict

**FAIL.** The deployed service does not provide a reliable workspace. A newly
created demo or private key is often unknown on the very next request. The
one-click demo consequently failed in 10 of 10 fresh browser contexts during
the repeated check. Even when the demo loaded earlier in this review, its 390
px first screen showed controls but no sample transaction or result. Those are
blocking failures. There are also copy, claim-registration, and recovery gaps.

## Cold first read

Fresh Chromium contexts were opened at 390 × 844 and 1440 × 1000. Before any
scrolling, my answers were:

- **What it does:** links expenses to evidence and exports a quarter evidence
  pack.
- **For whom:** sole traders preparing an MTD quarterly update.
- **What to click first:** **Try it with sample data**.

This gate passes. The exact first-screen copy was “Link each expense to
evidence”, “For sole traders who need a reviewable record before each MTD
quarterly update”, and “Try it with sample data”. Both widths had zero
horizontal overflow and no console error on the cold landing page. Finding
F-2-3 covers the narrower audience wording.

## Findings

### F-2-1 — BLOCKING — Live workspaces are split across service processes

**Location and exact copy:** demo banner, “Demo — sample data. Changes stay in
this 24-hour demo.” README, “Production uses one app instance. Its database is
stored on the mounted `/data` volume.” Claims `shared-state-boundary` and
`production-topology` make the same deployed-storage promise.

**Observed:** `POST /api/demo` returned 201 and a fresh demo key. The immediate
`GET /api/workspace` returned 404 with “This workspace was not found. Start a
new workspace.” Ten of ten fresh browser contexts failed to show sample data.
Five of five private-workspace creates and five of five demo creates also
returned 404 on their immediate read. For one demo key, 20 fresh reads produced
7 HTTP 200 responses and 13 HTTP 404 responses in a repeating pattern.

**Why this blocks:** a first-time visitor cannot reliably enter the demo or use
a private workspace. A successful write may disappear on the next request.
The passing local shared-storage and rendered-topology tests do not verify the
deployed topology, so they cannot prove the copy visitors rely on.

**Concrete fix:** serve all traffic through one active revision and one replica
with the same mounted database, or move workspace state to a genuinely shared
store. Add a public black-box claim test that creates private and demo keys and
requires 100/100 fresh-connection reads before deployment is accepted. The
test must fail if any read returns 404.

### F-2-2 — BLOCKING — The successful mobile demo first screen shows no sample data

**Location and exact copy:** 390 × 844 `/?demo=1`, after clicking “Try it with
sample data”. The visible screen ended after “Workspace settings”. The six
transactions, two missing-evidence count, totals, and “Teaching card supplies”
were below the fold.

**Why this blocks:** the demo contract requires the first screen after one
click to already look like the product in use. The desktop screen showed four
totals and the first realistic transaction; the phone screen showed setup and
controls only.

**Concrete fix:** on demo phones, put a compact sample summary and at least one
named sample transaction before the action toolbar, or shorten/collapse the
masthead and toolbar. Add a 390 × 844 test that asserts “Teaching card
supplies” and a sample result are within the initial viewport.

### F-2-3 — Medium — The first screen narrows the brief's audience

**Location and exact copy:** landing, “For sole traders who need a reviewable
record before each MTD quarterly update.” README, “MTD Evidence Rail is for UK
sole traders, tutors, and small club operators.” The brief says “UK sole
traders, tutors, and micro-club operators.”

**Why it matters:** tutors may identify with sole traders, but a club operator
need not. The same audience has three different descriptions.

**Concrete fix:** use one audience sentence everywhere: “For UK sole traders,
tutors, and small club operators preparing an MTD quarterly update.” Update the
brief terminology only if “micro-club” is intentionally being retired.

### F-2-4 — Medium — “Every quarter” is an unlisted universal claim

**Location and exact quote:** landing price heading, “Use one workspace for
every quarter.”

**Why it matters:** `quarter-capture` checks one dated quarter. No claim entry
creates records in two quarters and confirms that both remain available under
one key.

**Concrete fix:** add `multi-quarter-workspace` to `claims.json` and test two
quarters under one workspace key. Otherwise rename the heading “Monthly
subscription limits”.

### F-2-5 — Medium — Refund handling is an unlisted claim

**Location and exact quote:** landing price panel, “Sociobot and Dodo handle
subscription checkout and refunds.”

**Why it matters:** `hosted-checkout` proves the Dodo checkout destination,
price, and cadence. It does not prove refund handling.

**Concrete fix:** write “Checkout opens on Dodo through Sociobot.” If refund
handling remains, add a sandboxed claim and observable refund-policy check.

### F-2-6 — Medium — The API-wide workspace-key boundary is unlisted

**Location and exact quote:** README, “A 64-character workspace key scopes
every API request.”

**Why it matters:** `no-account` proves key creation and browser storage. It
does not assert that every protected API route rejects missing and wrong keys.
“Scopes” is also backend jargon.

**Concrete fix:** write “Every private API request must include the
workspace's 64-character key.” Add `workspace-key-auth` tests for every private
route with a valid, missing, and wrong key.

### F-2-7 — Medium — The CSP statement is vague, jargon-heavy, and unlisted

**Location and exact quote:** README, “Security headers include a restrictive
CSP.”

**Why it matters:** “restrictive” gives no verifiable boundary, and CSP is
unexplained. No claim entry checks the live document and API headers.

**Concrete fix:** either remove the sentence or write “Browser security
headers block scripts and connections the product does not use.” Add a claim
test for the exact live headers and a zero-console-error page load.

### F-2-8 — Medium — Container runtime statements are unlisted

**Location and exact quotes:** README, “The runtime image runs as a non-root
user.” and “It reads `PORT` and serves `/health` with the supplied
`BUILD_SHA`.”

**Why it matters:** `runtime-defaults` starts the compiled binary, not the
container, and only checks `status: ok`. It does not prove the container UID or
the returned build SHA.

**Concrete fix:** add one `container-runtime` claim that builds the image,
asserts a non-zero runtime UID, starts it with a known `BUILD_SHA`, and checks
that exact SHA at `/health`. Remove the sentences where Docker is unavailable
to the required verifier.

### F-2-9 — Medium — The documented sample composition is not one tested claim

**Location and exact quote:** README, “It contains six realistic transactions,
four linked files, and two missing items.”

**Why it matters:** existing tests separately observe six transactions and two
missing rows. No claim entry and tagged test assert all three counts, including
four linked files, from a clean demo.

**Concrete fix:** add `demo-sample` with this exact claim and assert 6 total, 4
linked, and 2 missing after one click and after reset.

### F-2-10 — Medium — The SQLite storage statement is unlisted

**Location and exact quote:** README, “Records and evidence are stored in
SQLite under `DATA_DIR`.”

**Why it matters:** this affects backup and deployment decisions.
`durable-storage` proves restart persistence but not this stated storage
location and format.

**Concrete fix:** add a storage-layout claim that starts the service with a
temporary `DATA_DIR`, saves a record and file, and verifies the SQLite database
and evidence data there. Otherwise describe only the tested outcome:
“Workspace data remains available after a service restart.”

### F-2-11 — Minor — The “does not do” section names no limitation

**Location and exact copy:** “What this record tool does not do” followed by
“Organise source records before your filing” and “Add transactions and linked
evidence. Export the pack when you are ready to file.”

**Why it matters:** the heading promises a boundary, but every following
sentence describes what the product does. “Source records” is accounting
jargon.

**Concrete fix:** use “What this tool covers”, “Organise evidence before you
file”, and “Add transactions and evidence. Export a copy when you are ready to
file.” If a non-goal is shown instead, register and test that boundary.

### F-2-12 — Minor — The rate-limit sentence is operator jargon

**Location and exact quote:** README, “API endpoints enforce per-IP burst
limits and respect the first `X-Forwarded-For` hop.”

**Why it matters:** “burst limits”, the header name, and “hop” require proxy
knowledge before the behavior is clear.

**Concrete fix:** “The API temporarily blocks a client that sends too many
requests. Behind a proxy, it identifies the client from the first forwarded IP
address.”

### F-2-13 — Minor — The checkout action names a result it does not complete

**Location and exact button:** “Start monthly subscription”.

**Why it matters:** clicking opens checkout; a subscription has not started.

**Concrete fix:** rename the action “Open £15/month checkout”.

### F-2-14 — Medium — A no-account workspace has no recovery or transfer path

**Location:** workspace settings contains export and delete only. The README
says the 64-character key stays in the browser.

**Why it matters:** clearing browser storage or changing phones permanently
loses access even though the backend still has the workspace. A user also
cannot intentionally open the same records on another device.

**Concrete fix:** add “Copy workspace access key” and “Open an existing
workspace” actions with a clear warning that anyone with the key can access the
records. Add claims for key restoration and wrong-key rejection. This is the
obvious missing sync/recovery step; receipt AI is not required by the brief.

## Demo, privacy, and sandbox evidence

The first successful phone and desktop demo load contained six named
transactions. The banner, **Reset demo**, and **Start for real** were present.
A sample transaction was added, Reset generated a different `demo:` session
key and restored six rows, and Start for real returned to a seeded private
transaction. The private workspace key, subscription token, and licence cache
did not change. Every demo request was same-origin and none sent an
`X-License-Key` header.

That successful isolation check confirms earlier F-1-1 remains fixed. It does
not excuse F-2-1: later fresh workspaces were routed to inconsistent live
stores and failed. No offline-use claim appears on the landing page or README;
the product instead displays a reconnect notice, so there was no offline claim
to prove.

## Claims

A clean local clone at source commit `4902a0c` received `npm ci`. Every exact
command in `.factory/claims.json` exited 0:

| Claim | Exact command | Result |
| --- | --- | --- |
| `demo-isolation` | `npm test -- --grep @claim:demo-isolation` | PASS |
| `no-account` | `npm test -- --grep @claim:no-account` | PASS |
| `quarter-capture` | `npm test -- --grep @claim:quarter-capture` | PASS |
| `csv-matching` | `npm test -- --grep @claim:csv-matching` | PASS |
| `atomic-import` | `npm test -- --grep @claim:atomic-import` | PASS |
| `calendar-dates` | `npm test -- --grep @claim:calendar-dates` | PASS |
| `evidence-types` | `npm test -- --grep @claim:evidence-types` | PASS |
| `missing-review` | `npm test -- --grep @claim:missing-review` | PASS |
| `evidence-pack` | `npm test -- --grep @claim:evidence-pack` | PASS |
| `workspace-delete` | `npm test -- --grep @claim:workspace-delete` | PASS |
| `free-limit` | `npm test -- --grep @claim:free-limit` | PASS |
| `paid-limit` | `npm test -- --grep @claim:paid-limit` | PASS |
| `hosted-checkout` | `npm run test:live-checkout` | PASS |
| `license-return` | `npm test -- --grep @claim:license-return` | PASS |
| `no-trackers` | `npm test -- --grep @claim:no-trackers` | PASS |
| `runtime-defaults` | `npm run build && cargo build && npm run test:runtime-defaults` | PASS |
| `durable-storage` | `npm run build && cargo build && npm run test:durable-storage` | PASS |
| `shared-state-boundary` | `npm run build && cargo build && npm run test:shared-storage` | PASS locally; contradicted live |
| `production-topology` | `npm run test:deployment-topology` | PASS rendered config; contradicted live |
| `api-rate-limit` | `cargo test api_rate_limit_returns_retry_after` | PASS |

The clean clone's full `npm test` also passed: typecheck, production build, four
Rust tests, runtime/storage/topology scripts, and 21/21 Chromium tests. The
build produced 30.51 kB JavaScript raw / 10.32 kB gzip. Passing local tests do
not override the live failures or the unlisted claims above.

## Earlier finding verification

Every finding from review 1 was checked on the live site and in current source:

| Earlier finding | Current verification |
| --- | --- |
| F-1-1 demo reads/writes real subscription state | **Fixed.** Demo code skips licence capture, headers, and cache access. A seeded live flow left all private keys unchanged and sent only same-origin requests. |
| F-1-2 unlisted HMRC filing/tax promise | **Fixed.** The wording is absent from live landing, README, legal copy, and current source. |
| F-1-3 decorative “Quarterly evidence, in order” | **Fixed.** Live and source say “Evidence for your MTD quarter”. |
| F-1-4 “Bank lines” terminology | **Fixed.** Live and source use “transactions”. |
| F-1-5 vague “Clear boundaries” / “under your control” headings | **Fixed as written.** Both phrases are removed. F-2-11 is a new content mismatch in the replacement section. |
| F-1-6 28-word deployment sentence | **Fixed.** It is absent; no current README sentence exceeds 22 words. |
| F-1-7 untested only-network-destination claim | **Fixed.** The “contacts ... only” statement is removed. |

No earlier finding is being reopened under its old ID. F-2-1 is a new deployed
shared-state regression.

## Structure, accessibility, and links

The live site passes the structural checks: route-specific titles, one H1 and
one main landmark, `lang=en-GB`, meta description, route canonical, OG image,
SVG favicon, 180 × 180 apple icon, and a 1200 × 630 social image. `/`, `/demo`,
`/app`, `/privacy`, and `/terms` returned 200. The designed unknown route
returned a real 404 with a home action. Push navigation and Back moved focus to
the new H1. Header and footer were consistent across routes.

All internal links returned 200; checkout returned the expected 303 to Dodo;
the external factory link returned 200; mail links were exempt. Playwright axe
reported zero violations on all six routes. The landing had no console error.
The demo console error is the F-2-1 workspace 404, not an accessibility issue.
The paper railway, night palette, local type, ticket corners, and original hero
art are product-specific rather than a generic SaaS template.

## Copy audit

Counts below use visible word-like tokens; punctuation-only marks are not
words, and hyphenated or slashed compounds count as one. Repeated navigation
and footer labels are listed once. Code blocks are commands, not sentences.

### Landing page

| Sentence, heading, label, or action | Words | Flag |
| --- | ---: | --- |
| MTD Evidence Rail | 3 | — |
| Home / Demo / Price / Privacy / Terms | 1 each | — |
| Evidence for your MTD quarter | 5 | — |
| Link each expense to evidence | 5 | — |
| For sole traders who need a reviewable record before each MTD quarterly update. | 13 | F-2-3 |
| Try it with sample data | 5 | — |
| See a ready quarter. | 4 | — |
| Changes stay in this 24-hour demo. | 6 | F-2-1 live contradiction |
| Start a private workspace | 4 | — |
| Your workspace needs no account. | 5 | — |
| £15/month for more than 25 transactions. | 6 | — |
| Export a ZIP evidence pack. | 5 | — |
| A paper train carries expense records towards a moon-shaped archive. | 10 | useful image alt |
| A quarter at a glance | 5 | — |
| See what still needs evidence | 5 | — |
| Transactions, invoices, and receipts appear in one dated view. | 9 | — |
| Missing evidence stays visible until you link it. | 8 | — |
| 6 Apr – 5 Jul 2026 | 5 | — |
| Capture / Match / Review / Export | 1 each | — |
| Quarter record / 6 transactions / 2 need evidence | 2 / 2 / 3 | — |
| Teaching card supplies | 3 | — |
| Materials · £32.99 | 2 | — |
| Evidence linked | 2 | — |
| Train to client session | 4 | — |
| Travel · £27.80 | 2 | — |
| Evidence missing | 2 | — |
| Spring maths tutoring | 3 | — |
| Invoice INV-026 · £120.00 | 3 | — |
| How it works | 3 | — |
| Prepare the quarter while it happens | 6 | — |
| Add each transaction | 3 | — |
| Record income or expenses. | 4 | — |
| You can also import a bank CSV. | 7 | — |
| Link the evidence | 3 | — |
| Add a receipt, invoice, or note. | 6 | — |
| Likely CSV matches are flagged before import. | 7 | — |
| Export the evidence pack | 4 | — |
| Download one ZIP with a transaction CSV and every linked file. | 11 | — |
| What this record tool does not do | 7 | F-2-11 |
| Organise source records before your filing | 6 | F-2-11 |
| Add transactions and linked evidence. | 5 | — |
| Export the pack when you are ready to file. | 9 | — |
| Workspace privacy, export, and deletion | 5 | — |
| Workspace keys are stored on this device. | 7 | — |
| Demo records use a separate 24-hour workspace. | 7 | F-2-1 live contradiction |
| You can export or delete your workspace. | 7 | — |
| No advertising trackers or third-party scripts run here. | 8 | — |
| Monthly subscription | 2 | — |
| Use one workspace for every quarter | 6 | F-2-4 |
| The free workspace accepts 25 transactions in a quarter. | 9 | — |
| A £15/month subscription accepts more than 25. | 7 | — |
| £15 per month | 3 | — |
| The server verifies an active subscription before accepting more than 25 transactions. | 12 | — |
| Receipt and invoice evidence | 4 | — |
| Bank CSV review | 3 | — |
| Accountant evidence packs | 3 | — |
| Start monthly subscription | 3 | F-2-13 |
| Sociobot and Dodo handle subscription checkout and refunds. | 8 | F-2-5 |
| See the terms. | 3 | — |
| Have a subscription token? | 4 | — |
| Paste it here. | 3 | — |
| Restore subscription access | 3 | — |
| Link each expense to evidence before your quarterly update. | 9 | — |
| Built by Param Factory (external site) | 6 | — |
| Version 1.0 · Build 2026.08 · Generated hero imagery is original to this product. | 12 | provenance |

### README

| Sentence or heading | Words | Flag |
| --- | ---: | --- |
| MTD Evidence Rail | 3 | — |
| Link each expense to evidence before your quarterly update. | 9 | — |
| MTD Evidence Rail is for UK sole traders, tutors, and small club operators. | 13 | F-2-3 terminology |
| It keeps transactions, receipts, and invoices together without adding a full accounting suite. | 13 | — |
| Use it to organise evidence before your own filing. | 9 | — |
| What it does | 3 | — |
| Adds income and expenses to a dated quarter view. | 9 | — |
| Imports bank CSV files and flags likely amount-and-date matches before import. | 11 | — |
| Links PDF, JPG, PNG, WebP, or text evidence to a transaction. | 10 | — |
| Keeps missing evidence visible as a separate review queue. | 9 | — |
| Exports a ZIP evidence pack with a transaction CSV and linked files. | 12 | — |
| Deletes a workspace and its files on request. | 8 | — |
| A workspace needs no account. | 5 | — |
| Its 64-character key stays in the browser. | 6 | — |
| The free plan accepts 25 transactions per quarter. | 8 | — |
| A £15/month subscription accepts more than 25. | 7 | — |
| Checkout and subscription checks use the Sociobot billing API and open a Dodo-hosted checkout. | 14 | — |
| Try the isolated demo | 4 | F-2-1 live contradiction |
| Open the sample workspace, or use http://localhost:8080/?demo=1 locally. | 8 | — |
| It contains six realistic transactions, four linked files, and two missing items. | 12 | F-2-9 |
| Demo changes stay in a separate workspace for 24 hours. | 10 | F-2-1 live contradiction |
| See .factory/demo.md. | 3 | — |
| Run locally | 2 | — |
| Requirements: Node 22+, current stable Rust, and SQLite build support. | 10 | necessary setup terms |
| Open http://localhost:8080. | 2 | — |
| The server starts with no required environment variables. | 8 | — |
| PORT defaults to 8080, DATA_DIR to data, and STATIC_DIR to dist. | 11 | necessary setup terms |
| For frontend work, run the API and npm run dev in separate terminals. | 13 | necessary setup terms |
| Vite proxies /api and /health to port 8080. | 8 | necessary setup terms |
| Test and build | 3 | — |
| npm test builds the frontend, runs the Rust tests, starts the complete server, and runs Playwright in Chromium. | 16 | — |
| Claim tests are listed in .factory/claims.json. | 6 | — |
| Data and security | 3 | — |
| Records and evidence are stored in SQLite under DATA_DIR. | 9 | F-2-10 |
| Production uses one app instance. | 5 | F-2-1 live contradiction |
| Its database is stored on the mounted /data volume. | 9 | F-2-1 live contradiction |
| A 64-character workspace key scopes every API request. | 8 | F-2-6 |
| Demo keys use a separate browser and database namespace. | 9 | — |
| API endpoints enforce per-IP burst limits and respect the first X-Forwarded-For hop. | 12 | F-2-12 |
| Security headers include a restrictive CSP. | 6 | F-2-7 |
| There are no advertising trackers or third-party runtime scripts. | 9 | — |
| The server enforces the free quarter limit even if browser storage is changed. | 13 | — |
| See /privacy and /terms in the running product. | 8 | — |
| Deploy | 1 | — |
| The root Dockerfile builds the Vite frontend and Rust server in separate stages. | 13 | necessary deployment terms |
| The runtime image runs as a non-root user. | 8 | F-2-8 |
| It reads PORT and serves /health with the supplied BUILD_SHA. | 10 | F-2-8 |
| The factory owns product registration and billing configuration. | 7 | — |
| Deployment details are recorded in the handoff. | 7 | — |
| Licence | 1 | — |
| MIT. | 1 | — |
| Generated hero artwork is original to this product. | 8 | required provenance |
| Its prompt and provenance are recorded in .factory/design.md. | 9 | required provenance |

No landing or README sentence exceeds 22 words. There are no banned marketing
words. Apart from F-2-13, actions name their result. The terminology and jargon
flags are F-2-3, F-2-6, F-2-7, F-2-11, and F-2-12.

## What would make this perfect

Restore one shared live workspace store and prove 100/100 fresh reads for both
demo and private keys. Put a realistic sample record in the first phone
viewport. Then register or remove every unlisted claim, apply the copy fixes,
and add safe key recovery. A later review must repeat the whole live flow; the
local green suite is not sufficient for a PASS.
