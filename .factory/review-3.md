# Adversarial first-read review 3 — FAIL

**Reviewed:** 29 August 2026

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Source commit:** `ec565569146bf69fec474c646670462afed9c215`

**Live build:** `bf15534cef6692e35f5ad62b610eb51648dcfe88`

## Verdict

**FAIL.** The product itself is clear and the live demo works, but three exact
claim commands fail from a clean clone because the repository and deployed
release identities differ. The README also regresses an earlier plain-language
finding, which the review contract requires reopening as blocking. One demo
action remains vague. A PASS requires zero findings and no failed claim test.

## Findings

### F-3-1 — BLOCKING — The live workspace claim command fails from the clean clone

**Location:** `.factory/claims.json`, claim `live-workspace-consistency`.

**Exact command:** `npm run test:live-workspace-consistency`

**Observed output:** “Unsafe live release: expected_sha=ec565569146bf69fec474c646670462afed9c215 live_sha=bf15534cef6692e35f5ad62b610eb51648dcfe88”.

**Why this blocks:** the required test stops at release identity and never
tests the promised live workspace consistency. A visitor can rely on the live
workspace behavior, but the exact verifier command cannot prove it from the
current clean clone.

**Concrete fix:** make the exact command resolve the latest committed product
build input revision, or read a committed release manifest, instead of assuming
repository HEAD is deployed. Then run the command without an extra environment
variable and require 100/100 private and demo reads.

### F-3-2 — BLOCKING — The live release identity claim command fails

**Location:** `.factory/claims.json`, claim `live-release-identity`.

**Exact command:** `npm run test:live-release`

**Observed output:** the command expects image tag `ec565569146b`, while the
ready image and `/health` identify `bf15534cef66`.

**Why this blocks:** the claim says the deployed health response and ready
image identify the exact published source revision. Its declared test returns
exit code 1 from the requested clean clone.

**Concrete fix:** record the deployed product revision in one committed source
of truth and make this command compare health and the ready image with that
revision. The exact command in `claims.json` must pass without a manual
`EXPECTED_SHA` override.

### F-3-3 — BLOCKING — The live rate-limit claim command fails before its probe

**Location:** `.factory/claims.json`, claim `live-api-rate-limit`.

**Exact command:** `npm run test:live-rate-limit`

**Observed output:** the same `expected_sha=ec565569…` versus
`live_sha=bf15534…` guard exits 1 before sending the declared 200-request probe.

**Why this blocks:** no passing result exists for the exact listed test, so the
deployed rate-limit claim is untested under the required procedure.

**Concrete fix:** use the same durable release manifest described in F-3-2,
then run the exact command and assert at least one 429, `Retry-After: 1` on
every limited response, and the one-limiter acceptance bound.

### F-1-6 — BLOCKING REGRESSION — Deployment jargon has returned to README

**Location:** `README.md`, Deploy.

**Exact quotes:** “It checks the source identity, image, mount, VFS, replica
count, workspace reads, restart recovery, and rate limiter.” and “It exits
before serving traffic if a later generic rollout replaces the durable
topology with container-local storage.”

**Why this blocks:** `VFS`, `generic rollout`, `durable topology`, and
`container-local storage` are unexplained implementation terms. F-1-6 required
internal deployment detail to move to the handoff; polish 1 recorded that fix.
The detail is back, so the history rule makes the regression blocking under the
same ID. Both sentences are under 22 words, but they still fail the jargon rule.

**Concrete fix:** keep the operator action in README and move the internal
checks back to the handoff. If retained, use: “It checks the deployed source,
container image, storage mount, database locking, replica count, workspace
reads, restart recovery, and request limit.” Then write: “It stops before
serving requests if a deployment replaces shared storage with temporary
container storage.”

### F-3-4 — Minor — “Start for real” does not name its result

**Location:** persistent demo banner.

**Exact action:** “Start for real”.

**Why it matters:** “real” does not tell a first-time visitor whether the link
creates an account, imports the sample, or opens a private workspace. It also
uses different words from the landing action for the same result.

**Concrete fix:** rename it **“Start a private workspace”**.

## Cold first read

Fresh Chromium contexts opened `/` at 390 × 844 and 1440 × 1000. Before
scrolling, my answers were:

- **What it does:** links each expense to evidence and exports an evidence pack.
- **For whom:** UK sole traders, tutors, and small club operators preparing an
  MTD quarterly update.
- **What to click first:** **Try it with sample data**; the adjacent text says
  it opens a ready quarter in a 24-hour demo.

This gate passes at both sizes. The exact first-screen text is “Link each
expense to evidence”, “For UK sole traders, tutors, and small club operators
preparing an MTD quarterly update”, and “Try it with sample data”. At 390 px,
all three facts and both alternative workspace actions also fit before the
first-screen artwork. There was no horizontal overflow or normal-load console
error.

## Demo, sandbox, and privacy evidence

One click opened `/?demo=1`. At 390 × 844, the first named sample transaction,
“Teaching card supplies”, ended at 344.53 px, inside the first viewport. The
screen already showed six transactions, two missing items, the sample amount,
quarter picker, and product actions.

The persistent banner, **Reset demo**, and F-3-4's action were present. The
sample contained six transactions, four linked files, and two missing items.
The missing-evidence filter showed exactly two rows. A live sample mutation was
exported as `evidence-pack-2026-27-Q1.zip`; its bytes began with `PK`. Reset
created a different `demo:` key, removed the added row, and restored the 6/4/2
sample.

Before entering the demo, I seeded private-workspace, subscription-token, and
subscription-cache sentinels. They were byte-for-byte unchanged after entry and
reset. The demo used only `sessionStorage` key
`demo:mtd-evidence-rail:workspace`; every observed request was same-origin and
none carried a licence header. The same demo key returned HTTP 200 on 100/100
fresh reads. No offline-use claim is made; the product instead gives a reconnect
notice.

A separate live private-workspace check created a record, cleared browser
storage, reopened the same record with its 64-character key, and deleted the
temporary workspace with HTTP 204.

## Claims matrix

A literal clean clone at source commit `ec565569…` received `npm ci`. Every
`test` value in `.factory/claims.json` was then run individually and exactly as
written. Twenty-three passed and three failed.

| Claim | Exact command | Result |
| --- | --- | --- |
| `demo-isolation` | `npm test -- --grep @claim:demo-isolation` | PASS |
| `no-account` | `npm test -- --grep @claim:no-account` | PASS |
| `workspace-key-recovery` | `npm test -- --grep @claim:workspace-key-recovery` | PASS |
| `workspace-key-auth` | `npm test -- --grep @claim:workspace-key-auth` | PASS |
| `quarter-capture` | `npm test -- --grep @claim:quarter-capture` | PASS |
| `csv-matching` | `npm test -- --grep @claim:csv-matching` | PASS |
| `atomic-import` | `npm test -- --grep @claim:atomic-import` | PASS |
| `calendar-dates` | `npm test -- --grep @claim:calendar-dates` | PASS |
| `evidence-types` | `npm test -- --grep @claim:evidence-types` | PASS |
| `missing-review` | `npm test -- --grep @claim:missing-review` | PASS |
| `demo-sample` | `npm test -- --grep @claim:demo-sample` | PASS |
| `evidence-pack` | `npm test -- --grep @claim:evidence-pack` | PASS |
| `workspace-delete` | `npm test -- --grep @claim:workspace-delete` | PASS |
| `free-limit` | `npm test -- --grep @claim:free-limit` | PASS |
| `paid-limit` | `npm test -- --grep @claim:paid-limit` | PASS |
| `hosted-checkout` | `npm run test:live-checkout` | PASS — Dodo, GBP 1500, monthly |
| `license-return` | `npm test -- --grep @claim:license-return` | PASS |
| `no-trackers` | `npm test -- --grep @claim:no-trackers` | PASS |
| `runtime-defaults` | `npm run build && cargo build && npm run test:runtime-defaults` | PASS |
| `durable-storage` | `npm run build && cargo build && npm run test:durable-storage` | PASS |
| `shared-state-boundary` | `npm run build && cargo build && npm run test:shared-storage` | PASS |
| `production-topology` | `npm run test:deployment-topology` | PASS |
| `live-workspace-consistency` | `npm run test:live-workspace-consistency` | **FAIL — F-3-1** |
| `live-release-identity` | `npm run test:live-release` | **FAIL — F-3-2** |
| `api-rate-limit` | `cargo test api_rate_limit_returns_retry_after` | PASS |
| `live-api-rate-limit` | `npm run test:live-rate-limit` | **FAIL — F-3-3** |

For diagnosis only, all three failing commands passed when run with
`EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88`: the live topology was
Single with one running replica and Azure Files at `/data`; private and demo
keys each passed 100/100 reads; and the rate probe returned 80 limited responses
with `Retry-After: 1`. Those overrides confirm healthy deployed behavior but do
not change the required exact-command failures.

Every claim-like landing and README product statement maps to a current
`claims.json` entry. The generated-art statement is treated as required asset
provenance and is backed by the retained source image, prompt sidecar, and
`.factory/design.md`, rather than as runtime product behavior.

## Copy audit

Counts use visible word tokens. Hyphenated terms, paths, and slash forms count
as one word; punctuation-only rail marks do not. Repeated header/footer labels
are listed once. Commands inside fenced code blocks are commands, not
sentences. No sentence exceeds 22 words and no banned marketing adjective is
present. F-1-6 and F-3-4 are the remaining plain-word failures.

### Landing page

| Exact copy | Words | Flag |
| --- | ---: | --- |
| Skip to main content | 4 | — |
| MTD Evidence Rail | 3 | — |
| Home / Demo / Price / Privacy | 1 each | — |
| Evidence for your MTD quarter | 5 | — |
| Link each expense to evidence | 5 | — |
| For UK sole traders, tutors, and small club operators preparing an MTD quarterly update. | 13 | — |
| Try it with sample data | 5 | — |
| See a ready quarter. | 4 | — |
| Changes stay in this 24-hour demo. | 6 | — |
| Start a private workspace | 4 | — |
| Open an existing workspace | 4 | — |
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
| Teaching card supplies / Materials · £32.99 / Evidence linked | 3 / 2 / 2 | — |
| Train to client session / Travel · £27.80 / Evidence missing | 4 / 2 / 2 | — |
| Spring maths tutoring / Invoice INV-026 · £120.00 / Evidence linked | 3 / 3 / 2 | — |
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
| What this tool covers | 4 | — |
| Organise evidence before you file | 5 | — |
| Add transactions and evidence. | 4 | — |
| Export a copy when you are ready to file. | 9 | — |
| Workspace privacy, export, and deletion | 5 | — |
| Workspace keys are stored on this device. | 7 | — |
| Demo records use a separate 24-hour workspace. | 7 | — |
| You can export or delete your workspace. | 7 | — |
| No advertising trackers or third-party scripts run here. | 8 | — |
| Monthly subscription | 2 | — |
| Monthly subscription limits | 3 | — |
| The free workspace accepts 25 transactions in a quarter. | 9 | — |
| A £15/month subscription accepts more than 25. | 7 | — |
| £15 / per month | 1 / 2 | — |
| The server verifies an active subscription before accepting more than 25 transactions. | 12 | — |
| Receipt and invoice evidence / Bank CSV review / Accountant evidence packs | 4 / 3 / 3 | — |
| Open £15/month checkout | 3 | — |
| Checkout opens on Dodo through Sociobot. | 6 | — |
| See the terms. | 3 | — |
| Have a subscription token? | 4 | — |
| Paste it here. | 3 | — |
| Restore subscription access | 3 | — |
| Link each expense to evidence before your quarterly update. | 9 | — |
| Privacy / Terms | 1 each | — |
| Built by Param Factory (external site) | 6 | — |
| Version 1.0 · Build 2026.08 · Generated hero imagery is original to this product. | 12 | provenance |

### README

| Exact copy | Words | Flag |
| --- | ---: | --- |
| MTD Evidence Rail | 3 | — |
| Link each expense to evidence before your quarterly update. | 9 | — |
| MTD Evidence Rail is for UK sole traders, tutors, and small club operators preparing an MTD quarterly update. | 18 | — |
| It keeps transactions, receipts, and invoices together in a dated quarter view. | 12 | — |
| What it does | 3 | — |
| Adds income and expenses to a dated quarter view. | 9 | — |
| Imports bank CSV files and flags likely amount-and-date matches before import. | 11 | — |
| Links PDF, JPG, PNG, WebP, or text evidence to a transaction. | 10 | — |
| Keeps missing evidence visible as a separate review queue. | 9 | — |
| Exports a ZIP evidence pack with a transaction CSV and linked files. | 12 | — |
| Deletes a workspace and its files on request. | 8 | — |
| A workspace needs no account. | 5 | — |
| Its 64-character key stays in the browser. | 7 | — |
| The free plan accepts 25 transactions per quarter. | 8 | — |
| A £15/month subscription accepts more than 25. | 7 | — |
| Checkout and subscription checks use the Sociobot billing API and open a Dodo-hosted checkout. | 14 | — |
| Copy the workspace access key to open the same records on another device. | 12 | — |
| Anyone with this key can change the records, so keep it private. | 12 | — |
| Try the isolated demo | 4 | — |
| Open the sample workspace, or use http://localhost:8080/?demo=1 locally. | 8 | — |
| It contains six realistic transactions, four linked files, and two missing items. | 12 | — |
| Demo changes stay in a separate workspace for 24 hours. | 10 | — |
| See .factory/demo.md. | 2 | — |
| Run locally | 2 | — |
| Requirements: Node 22+, current stable Rust, and SQLite build support. | 10 | — |
| Open http://localhost:8080. | 2 | — |
| The server starts with no required environment variables. | 8 | — |
| PORT defaults to 8080, DATA_DIR to data, and STATIC_DIR to dist. | 11 | — |
| For frontend work, run the API and npm run dev in separate terminals. | 13 | — |
| Vite proxies /api and /health to port 8080. | 8 | necessary setup term |
| Test and build | 3 | — |
| npm test builds the frontend, runs the Rust tests, starts the complete server, and runs Playwright in Chromium. | 16 | — |
| Claim tests are listed in .factory/claims.json. | 6 | — |
| Data and security | 3 | — |
| Workspace data remains available after a service restart. | 8 | — |
| Production uses one app instance with shared durable storage. | 9 | — |
| Every private API request must include the workspace's 64-character key. | 10 | — |
| Demo keys use a separate browser and database namespace. | 9 | — |
| The API temporarily blocks a client that sends too many requests. | 10 | — |
| Behind a proxy, it identifies the client from the first forwarded IP address. | 13 | operator context |
| There are no advertising trackers or third-party runtime scripts. | 9 | — |
| The server enforces the free quarter limit even if browser storage is changed. | 13 | — |
| See /privacy and /terms in the running product. | 8 | — |
| Deploy | 1 | — |
| The root Dockerfile builds the Vite frontend and Rust server in separate stages. | 12 | necessary deployment term |
| Run scripts/deploy.sh through the factory work order. | 7 | — |
| It builds the committed image, then applies that image with the one-replica Azure Files topology in one revision. | 18 | operator context |
| It checks the source identity, image, mount, VFS, replica count, workspace reads, restart recovery, and rate limiter. | 17 | **F-1-6** |
| At startup, an Azure Container Apps revision checks that /data is a dedicated mount. | 14 | operator context |
| It exits before serving traffic if a later generic rollout replaces the durable topology with container-local storage. | 16 | **F-1-6** |
| The factory owns product registration and billing configuration. | 8 | — |
| Deployment details are recorded in the handoff. | 7 | — |
| If the work-order runner builds the image first, run the same command with PREBUILT_IMAGE set to that exact commit-tagged image. | 20 | operator context |
| The script skips the second build but still applies and verifies the product topology. | 13 | operator context |
| Licence | 1 | — |
| MIT. | 1 | — |
| Generated hero artwork is original to this product. | 8 | provenance |
| Its prompt and provenance are recorded in .factory/design.md. | 8 | provenance |

### Demo action checked outside the landing audit

| Exact copy | Words | Flag |
| --- | ---: | --- |
| Demo — sample data. Changes stay in this 24-hour demo. | 9 | — |
| Reset demo | 2 | — |
| Start for real | 3 | **F-3-4** |

## Earlier finding verification

Every earlier review, polish record, and current handoff was read. Each earlier
finding was checked in live behavior and current source.

| Earlier finding | Current result |
| --- | --- |
| F-1-1 demo read/wrote real subscription state | **Fixed.** Seeded private and licence values stayed unchanged; demo requests were same-origin with no licence header. |
| F-1-2 unlisted HMRC/tax promise | **Fixed.** The promise is absent from landing, README, legal copy, and frontend source. |
| F-1-3 decorative quarterly label | **Fixed.** Live and source say “Evidence for your MTD quarter”. |
| F-1-4 “Bank lines” terminology | **Fixed.** Landing and app consistently use “transaction”. |
| F-1-5 vague boundary/privacy headings | **Fixed.** The current headings name their sections. |
| F-1-6 long deployment jargon | **REGRESSED — BLOCKING.** Sentence length is fixed, but unexplained deployment jargon has returned to README. |
| F-1-7 untested only-network-destination claim | **Fixed.** The broad “only” promise remains absent. |
| F-2-1 split live workspace state | **Fixed.** With the deployed build identity supplied, private and demo workspaces each returned 100/100 reads; topology is one active revision and one replica. F-3-1 is a test-command defect, not a repeated split-state observation. |
| F-2-2 no sample data in the first mobile demo screen | **Fixed.** “Teaching card supplies” ends at 344.53 px in an 844 px viewport. |
| F-2-3 inconsistent audience | **Fixed.** Landing, README, and brief use UK sole traders, tutors, and small club operators. |
| F-2-4 unlisted “every quarter” claim | **Fixed.** The phrase is absent; the heading is “Monthly subscription limits”. |
| F-2-5 unlisted refund claim | **Fixed.** Refund wording is absent; checkout copy names Dodo through Sociobot. |
| F-2-6 unlisted API key boundary | **Fixed.** `workspace-key-auth` is listed, uniquely tagged, and passes. |
| F-2-7 vague CSP claim | **Fixed.** The sentence remains absent; live headers and normal loads were clean. |
| F-2-8 unlisted container runtime statements | **Fixed as originally quoted.** The non-root and prose BUILD_SHA claims remain absent. |
| F-2-9 unlisted sample composition | **Fixed.** `demo-sample` asserts 6/4/2 before and after reset. |
| F-2-10 unlisted SQLite storage layout | **Fixed.** README states the tested restart outcome instead. |
| F-2-11 mismatched “does not do” section | **Fixed.** The section now says “What this tool covers” and describes its scope. |
| F-2-12 rate-limit jargon | **Fixed.** The two replacement sentences from review 2 are present. |
| F-2-13 misleading subscription action | **Fixed.** The action says “Open £15/month checkout”. |
| F-2-14 missing recovery/transfer | **Fixed.** A live created record reopened after local storage was cleared; the temporary workspace was then deleted. |

## Structure, accessibility, routes, and identity

The structure gate passes. `/`, `/demo`, `/app`, `/privacy`, and `/terms`
returned 200 with route-specific titles, one H1, one main landmark,
`lang=en-GB`, a description, route canonical, OG image, Twitter card, favicon,
apple-touch icon, header, footer, skip link, Privacy, and Terms. The unknown
route returned a designed HTTP 404 with a home action. `robots.txt` and
`sitemap.xml` list the routes.

Internal links, the Param Factory link, and hosted checkout resolved; mail links
were treated as explicit mail actions. SPA navigation and Back focused the new
H1 and restored the home route. Playwright axe found zero violations on all six
checked routes at 390 px. Reduced motion disables animation and transitions.
The production JavaScript is 33,893 bytes raw and 11,046 bytes gzip.

The paper railway, cabinet moon, dark teal and cream palette, local serif/sans
pairing, ticket corners, and rail details are specific to this product. The site
does not present as a generic SaaS template.

## Quality gates and missed leverage

From the clean clone, `npm test` passed all six Rust tests and 25/25 Playwright
tests. `npm run lint` passed TypeScript, rustfmt, and Clippy. `npm run build`
produced `dist/`. These passes do not override the three failed exact claim
commands.

The brief's obvious adjacent capabilities are present: bank CSV import with
match review, evidence linking, missing-evidence review, ZIP export, deletion,
and access-key recovery across devices. The core job does not need an AI step;
adding one would introduce unnecessary data transfer and cost. No decorative AI
feature or embedded provider key was found.

## What would make this perfect

Make the three exact live claim commands resolve the deployed product revision
without a manual override and pass from the current clean clone. Remove or
rewrite the regressed README jargon, and rename “Start for real” to “Start a
private workspace”. Then repeat the full live, claims, copy, history, route, and
accessibility review; PASS requires zero remaining findings.
