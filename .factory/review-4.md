# Adversarial first-read review 4 — FAIL

**Reviewed:** 30 August 2026

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Candidate:** `5995607104fdec40b52f6555fe98ae88684aedaa`

**Live build:** `b8408a552f17a2094e8e87f989cdab94d175af2f`

## Verdict

**FAIL.** The landing page and isolated sample are clear and usable, but one
listed claim test fails from the required clean clone. Two earlier copy and
claim-test fixes have also regressed. The README contains one further unlisted
claim and one unexplained technical term. PASS requires zero findings.

## Findings

### F-3-2 — BLOCKING REGRESSION — The live release claim command fails

**Location:** `.factory/claims.json`, `live-release-identity`; source script
`scripts/assert-published-source.sh`.

**Exact command:** `npm run test:live-release`

**Observed:** exit 1 from a clean clone at the candidate. The guard reports:

> Release-neutral candidate 5995607104fdec40b52f6555fe98ae88684aedaa changes product or deployment inputs

It then lists `.factory/evidence/verification-19/**` and
`.factory/verification-19.md`. Those committed verification files are outside
the guard's allowlist. The live health response and ready image both identify
`b8408a552f17a2094e8e87f989cdab94d175af2f`, but the exact claim command stops
before comparing them.

**Why this blocks:** a listed claim has a failing test. This is the same failure
condition as review 3's F-3-2, despite polish 3 recording it as fixed.

**Concrete fix:** define one consistent release-neutral allowlist that includes
committed verification evidence, or keep that evidence outside candidate
history. Add a regression fixture containing the exact
`.factory/evidence/verification-*` and `.factory/verification-*.md` paths.
Then require `npm run test:live-release` to reach the live health/image checks
and exit 0 from the clean candidate with no override.

### F-1-6 — BLOCKING REGRESSION — Deployment jargon and a 27-word sentence returned

**Location:** `README.md`, **Deploy**.

**Exact copy:**

> An Azure revision never opens SQLite on the container filesystem.

> If a later factory rollout omits the storage settings, that replica asks Azure to restore the last ready image with the source-owned topology, then exits before serving.

> `npm run test:verification-16-regression` covers that complete recovery path with local managed-identity and management-API fixtures.

**Why this blocks:** the second sentence has 27 words. “Azure revision”,
“container filesystem”, “source-owned topology”, “managed-identity”, and
“management-API fixtures” require infrastructure knowledge. Review 1's
F-1-6 required deployment internals to move out of the README, and polish 3
said they had been removed. The history rule therefore makes this regression
blocking under the original ID.

**Concrete fix:** move all three sentences to `.factory/handoff.md`. Keep one
README sentence: “The deployment stops if shared storage is unavailable.” If
that sentence remains, map it explicitly to `production-topology`.

### F-4-1 — Medium — README makes an unlisted comparative rate-limit claim

**Location:** `README.md`, **Data and security**.

**Exact copy:**

> Demo creation has a stricter limit because it writes the six sample records.

**Why this fails:** “stricter” compares two limits without giving either
number. Neither `api-rate-limit` nor `live-api-rate-limit` states this
comparison as its claim. Their tests cannot make this extra claim discoverable
or keep its wording accurate.

**Concrete fix:** delete the sentence because it does not help a user operate
the product. If operators need it, list a quantitative claim such as “Demo
creation allows 20 requests per client before temporary blocking” and test
that exact threshold and refill rule.

### F-4-2 — Minor — README uses “namespace” instead of describing the separation

**Location:** `README.md`, **Data and security**.

**Exact copy:**

> Demo keys use a separate browser and database namespace.

**Why this fails:** “namespace” is implementation jargon and does not tell a
reader whether demo activity can reach private data.

**Concrete fix:** “Demo keys and data are kept separate from private
workspaces.”

## Cold first read

Fresh Chromium contexts opened `/` at 390 × 844 and 1440 × 1000. Before
scrolling, the first screen answered all three required questions:

- **What it does:** links each expense to evidence and exports a ZIP evidence
  pack.
- **For whom:** UK sole traders, tutors, and small club operators preparing an
  MTD quarterly update.
- **What to click first:** **Try it with sample data**. Adjacent text says it
  opens a ready quarter and that changes stay in a 24-hour demo.

The exact supporting copy is “Link each expense to evidence”, “For UK sole
traders, tutors, and small club operators preparing an MTD quarterly update”,
and “See a ready quarter. Changes stay in this 24-hour demo.” At 390 px, the
primary action ended at 446 px and all three plain facts ended at 714 px. There
was no horizontal overflow or console error at either width.

## Demo, sandbox, and privacy

The landing action opened `/?demo=1` in one click. On the 390 × 844 first
screen, “6 transactions” and the named sample “Teaching card supplies” ended at
363 px. The screen already looked populated before any second action.

The persistent banner said “Demo — sample data. Changes stay in this 24-hour
demo.” It included **Reset demo** and **Start a private workspace**. Reset
replaced the `demo:` session key and restored the sample.

Before entry, the browser was seeded with a real private workspace containing
“Review sentinel”, a subscription token, and a subscription cache. After demo
entry and Reset:

- all three private values were byte-for-byte unchanged;
- the real workspace still returned the sentinel record;
- the demo used only `demo:mtd-evidence-rail:workspace` in `sessionStorage`;
- every demo request was same-origin;
- no demo request sent `X-License-Key`;
- the console remained clear.

The temporary private and current demo workspaces created by this successful
check were deleted afterward. No offline-use claim appears; the product instead
shows a reconnect notice.

## Claims matrix

A committed clean clone at candidate `5995607` received `npm ci`. Every `test`
value in `.factory/claims.json` was run individually and exactly as written.
Twenty-five passed and one failed.

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
| `live-workspace-consistency` | `npm run test:live-workspace-consistency` | PASS — 100/100 private and 100/100 demo reads |
| `live-release-identity` | `npm run test:live-release` | **FAIL — F-3-2** |
| `api-rate-limit` | `cargo test api_rate_limit_returns_retry_after` | PASS |
| `live-api-rate-limit` | `npm run test:live-rate-limit` | PASS — three 200-request waves; every 429 had `Retry-After: 1` |

The landing statements map to listed claims. F-4-1 is the only additional
claim-like README sentence without a matching claim statement. There is no
untested claim: it was identified as a finding instead of being assumed true.

## Copy audit

Counts use visible word-like tokens. Hyphenated terms, slash forms, URLs, paths,
and identifiers count as one. Punctuation-only marks do not count. Repeated
navigation and footer labels are listed once. README command blocks are
commands, not sentences, so they are excluded; their surrounding prose is
included. Headings, labels, alt text, and actions are included because the
plain-words rules apply to them.

### Landing page

| Exact copy | Words | Result |
| --- | ---: | --- |
| Skip to main content | 4 | Clear |
| MTD Evidence Rail | 3 | Product name |
| Home / Demo / Price / Privacy | 1 each | Clear navigation |
| Evidence for your MTD quarter | 5 | Clear section label |
| Link each expense to evidence | 5 | Clear H1 |
| For UK sole traders, tutors, and small club operators preparing an MTD quarterly update. | 14 | Clear audience |
| Try it with sample data | 5 | Result-naming action |
| See a ready quarter. | 4 | Clear |
| Changes stay in this 24-hour demo. | 6 | Listed claim |
| Start a private workspace | 4 | Result-naming action |
| Open an existing workspace | 4 | Result-naming action |
| Your workspace needs no account. | 5 | Listed claim |
| £15/month for more than 25 transactions. | 6 | Listed claim |
| Export a ZIP evidence pack. | 5 | Listed claim |
| A paper train carries expense records towards a moon-shaped archive. | 10 | Useful image alt |
| A quarter at a glance | 5 | Clear heading |
| See what still needs evidence | 5 | Clear heading |
| Transactions, invoices, and receipts appear in one dated view. | 9 | Listed claim |
| Missing evidence stays visible until you link it. | 8 | Listed claim |
| 6 Apr – 5 Jul 2026 | 5 | Sample data |
| Capture / Match / Review / Export | 1 each | Clear stages |
| Quarter record / 6 transactions / 2 need evidence | 2 / 2 / 3 | Sample data |
| Teaching card supplies / Materials · £32.99 / Evidence linked | 3 / 2 / 2 | Sample data |
| Train to client session / Travel · £27.80 / Evidence missing | 4 / 2 / 2 | Sample data |
| Spring maths tutoring / Invoice INV-026 · £120.00 / Evidence linked | 3 / 3 / 2 | Sample data |
| How it works | 3 | Clear heading |
| Prepare the quarter while it happens | 6 | Clear heading |
| Add each transaction | 3 | Clear step |
| Record income or expenses. | 4 | Clear |
| You can also import a bank CSV. | 7 | Clear |
| Link the evidence | 3 | Clear step |
| Add a receipt, invoice, or note. | 6 | Clear |
| Likely CSV matches are flagged before import. | 7 | Listed claim |
| Export the evidence pack | 4 | Clear step |
| Download one ZIP with a transaction CSV and every linked file. | 11 | Listed claim |
| What this tool covers | 4 | Clear heading |
| Organise evidence before you file | 5 | Clear heading |
| Add transactions and evidence. | 4 | Clear |
| Export a copy when you are ready to file. | 9 | Clear |
| Workspace privacy, export, and deletion | 5 | Clear heading |
| Workspace keys are stored on this device. | 7 | Listed claim |
| Demo records use a separate 24-hour workspace. | 7 | Listed claim |
| You can export or delete your workspace. | 7 | Listed claims |
| No advertising trackers or third-party scripts run here. | 8 | Listed claim |
| Monthly subscription | 2 | Clear section label |
| Monthly subscription limits | 3 | Clear heading |
| The free workspace accepts 25 transactions in a quarter. | 9 | Listed claim |
| A £15/month subscription accepts more than 25. | 7 | Listed claim |
| £15 / per month | 1 / 2 | Clear price |
| The server verifies an active subscription before accepting more than 25 transactions. | 12 | Listed claim |
| Receipt and invoice evidence / Bank CSV review / Accountant evidence packs | 4 / 3 / 3 | Clear features |
| Open £15/month checkout | 3 | Result-naming action |
| Checkout opens on Dodo through Sociobot. | 6 | Listed claim |
| See the terms. | 3 | Clear link |
| Have a subscription token? | 4 | Clear prompt |
| Paste it here. | 3 | Clear instruction |
| Restore subscription access | 3 | Result-naming action |
| Link each expense to evidence before your quarterly update. | 9 | Clear footer summary |
| Privacy / Terms | 1 each | Clear links |
| Built by Param Factory (external site) | 6 | Clear attribution |
| Version 1.0 · Build 2026.08 · Generated hero imagery is original to this product. | 12 | Provenance |

No landing sentence exceeds 22 words, contains a banned marketing adjective,
uses an inconsistent product term, or uses a non-result-naming button.

### README

| Exact copy | Words | Result |
| --- | ---: | --- |
| MTD Evidence Rail | 3 | Product name |
| Link each expense to evidence before your quarterly update. | 9 | Clear summary |
| MTD Evidence Rail is for UK sole traders, tutors, and small club operators preparing an MTD quarterly update. | 18 | Clear audience |
| It keeps transactions, receipts, and invoices together in a dated quarter view. | 12 | Clear |
| What it does | 3 | Clear heading |
| Adds income and expenses to a dated quarter view. | 9 | Listed claim |
| Imports bank CSV files and flags likely amount-and-date matches before import. | 11 | Listed claim |
| Links PDF, JPG, PNG, WebP, or text evidence to a transaction. | 11 | Listed claim |
| Keeps missing evidence visible as a separate review queue. | 9 | Listed claim |
| Exports a ZIP evidence pack with a transaction CSV and linked files. | 12 | Listed claim |
| Deletes a workspace and its files on request. | 8 | Listed claim |
| A workspace needs no account. | 5 | Listed claim |
| Its 64-character key stays in the browser. | 7 | Listed claim |
| The free plan accepts 25 transactions per quarter. | 8 | Listed claim |
| A £15/month subscription accepts more than 25. | 7 | Listed claim |
| Checkout and subscription checks use the Sociobot billing API and open a Dodo-hosted checkout. | 14 | Listed claims |
| Copy the workspace access key to open the same records on another device. | 12 | Listed claim |
| Anyone with this key can change the records, so keep it private. | 12 | Useful warning |
| Try the isolated demo | 4 | Clear heading |
| Open the sample workspace, or use http://localhost:8080/?demo=1 locally. | 8 | Clear instruction |
| It contains six realistic transactions, four linked files, and two missing items. | 12 | Listed claim |
| Demo changes stay in a separate workspace for 24 hours. | 10 | Listed claim |
| See .factory/demo.md. | 2 | Clear link |
| Run locally | 2 | Clear heading |
| Requirements: Node 22+, current stable Rust, and SQLite build support. | 10 | Necessary setup terms |
| Open http://localhost:8080. | 2 | Clear instruction |
| The server starts with no required environment variables. | 8 | Listed claim |
| PORT defaults to 8080, DATA_DIR to data, and STATIC_DIR to dist. | 11 | Necessary setup terms |
| For frontend work, run the API and npm run dev in separate terminals. | 13 | Clear instruction |
| Vite proxies /api and /health to port 8080. | 8 | Necessary setup terms |
| Test and build | 3 | Clear heading |
| npm test builds the frontend, runs the Rust tests, starts the complete server, and runs Playwright in Chromium. | 18 | Clear developer instruction |
| Claim tests are listed in .factory/claims.json. | 6 | Clear |
| Data and security | 3 | Clear heading |
| Workspace data remains available after a service restart. | 8 | Listed claim |
| Production uses one app instance with shared durable storage. | 9 | Listed claim |
| Every private API request must include the workspace's 64-character key. | 10 | Listed claim |
| Demo keys use a separate browser and database namespace. | 9 | **F-4-2: jargon** |
| The API temporarily blocks a client that sends too many requests. | 11 | Listed claim |
| Behind a proxy, it identifies the client from the first forwarded IP address. | 13 | Necessary operator detail |
| Demo creation has a stricter limit because it writes the six sample records. | 13 | **F-4-1: vague, unlisted claim** |
| There are no advertising trackers or third-party runtime scripts. | 9 | Listed claim |
| The server enforces the free quarter limit even if browser storage is changed. | 13 | Listed claim |
| See /privacy and /terms in the running product. | 8 | Clear links |
| Deploy | 1 | Clear heading |
| The root Dockerfile builds the Vite frontend and Rust server in separate stages. | 13 | Necessary build detail |
| Run scripts/deploy.sh through the factory work order. | 7 | Clear operator action |
| It deploys the committed product and checks the live service before it finishes. | 13 | Listed release behavior |
| The committed .factory/release.json records which source revision is live. | 9 | Listed release behavior |
| The candidate is that revision or a descendant whose cumulative changes are limited to release evidence and the factory-generated code map. | 21 | Listed claim; test fails under F-3-2 |
| The factory owns product registration and billing configuration. | 8 | Clear ownership |
| Deployment details are recorded in the handoff. | 7 | Clear location |
| An Azure revision never opens SQLite on the container filesystem. | 10 | **F-1-6: jargon regression** |
| If a later factory rollout omits the storage settings, that replica asks Azure to restore the last ready image with the source-owned topology, then exits before serving. | 27 | **F-1-6: over 22 words and jargon** |
| npm run test:verification-16-regression covers that complete recovery path with local managed-identity and management-API fixtures. | 12 | **F-1-6: jargon regression** |
| If the work-order runner builds the image first, pass that image to the same script with PREBUILT_IMAGE. | 17 | Clear operator instruction |
| Licence | 1 | Clear heading |
| MIT. | 1 | Clear licence |
| Generated hero artwork is original to this product. | 8 | Provenance |
| Its prompt and provenance are recorded in .factory/design.md. | 8 | Provenance location |

Terminology is otherwise consistent: **transaction**, **evidence**,
**quarter**, **evidence pack**, **missing evidence**, **workspace**,
**workspace access key**, and **subscription token** each name one concept.

## Earlier finding verification

Every `review-*.md`, `polish-*.md`, and the prior handoff was read. Each earlier
finding was checked against both live behavior and current source.

| Earlier finding | Current result |
| --- | --- |
| F-1-1 demo read or wrote private subscription state | **Fixed.** Seeded workspace, token, and cache values stayed unchanged; requests were same-origin with no licence header. |
| F-1-2 unlisted HMRC and tax promises | **Fixed.** The quoted promises remain absent from live and source. |
| F-1-3 decorative quarterly label | **Fixed.** Live and source say “Evidence for your MTD quarter”. |
| F-1-4 inconsistent “bank lines” term | **Fixed.** Current copy uses “transaction”. |
| F-1-5 vague section headings | **Fixed.** Current headings name their content. |
| F-1-6 README deployment jargon | **REGRESSED — BLOCKING.** See the reopened finding above. |
| F-1-7 broad network-only promise | **Fixed.** The promise remains absent. |
| F-2-1 split deployed workspace state | **Fixed.** The exact live command passed 100/100 reads for fresh private and demo workspaces. |
| F-2-2 no sample result in the phone's first demo screen | **Fixed.** Named sample content ended at 363 px in the 844 px viewport. |
| F-2-3 inconsistent audience | **Fixed.** Landing, README, and brief use the same audience. |
| F-2-4 unlisted “every quarter” claim | **Fixed.** The phrase remains absent. |
| F-2-5 unlisted refund claim | **Fixed.** Refund wording remains absent. |
| F-2-6 unlisted API key boundary | **Fixed.** The listed key-auth test passed. |
| F-2-7 vague CSP claim | **Fixed.** The copy remains absent; response headers and normal loads were clean. |
| F-2-8 unlisted container runtime claims | **Fixed as quoted.** Non-root and prose build-SHA promises remain absent. |
| F-2-9 unlisted sample composition | **Fixed.** `demo-sample` passed before and after Reset. |
| F-2-10 unlisted SQLite storage layout | **Fixed as quoted.** README states the tested restart outcome instead. |
| F-2-11 mismatched scope section | **Fixed.** “What this tool covers” matches its content. |
| F-2-12 rate-limit jargon | **Fixed as specified.** The two plain replacement sentences remain. F-4-1 concerns a new comparative sentence. |
| F-2-13 misleading subscription action | **Fixed.** The action says “Open £15/month checkout”. |
| F-2-14 missing workspace recovery | **Fixed.** Recovery UI and both key tests are present and pass. |
| F-3-1 live workspace command failed | **Fixed.** The exact command passed. |
| F-3-2 live release command failed | **REGRESSED — BLOCKING.** See the reopened finding above. |
| F-3-3 live rate-limit command failed | **Fixed.** The exact command completed all three waves. |
| F-3-4 vague “Start for real” action | **Fixed.** Live and source say “Start a private workspace”. |

## Structure, accessibility, and links

The live structure passes at 390 px on `/`, `/demo`, `/app`, `/privacy`,
`/terms`, and an unknown route:

- each route has `lang=en-GB`, one H1, one `main`, a route title, canonical,
  description, OG image, favicon, apple-touch icon, header, and footer;
- `/demo` is titled `Demo — MTD Evidence Rail`, `/privacy` and `/terms` use the
  corresponding legal-title pattern, and the unknown route returns HTTP 404;
- SPA navigation and Back update the title and move focus to the new H1;
- Privacy and Terms are present in every footer, and the skip link is present;
- Playwright axe reports zero violations across all six routes;
- internal routes, `robots.txt`, `sitemap.xml`, metadata assets, and the Param
  Factory link return 200; checkout returns the expected 303 to Dodo;
- normal routes have no console errors or horizontal overflow.

The unknown route produces Chromium's expected failed-main-resource console
entry because its document status is genuinely 404; its designed content,
navigation, and accessibility checks still render correctly.

The paper railway, cabinet moon, dark teal and cream palette, local serif/sans
pairing, ticket edges, and rail marks match `.factory/design.md`. The result is
product-specific and not a generic SaaS template. Production JavaScript is
33.90 kB raw and 11.05 kB gzip.

## Quality gates and missed leverage

From the clean clone, `npm test` passed 9 Rust tests and 25/25 Chromium tests.
`npm run lint` and `npm run build` passed; `dist/` was produced. These passes do
not override F-3-2.

The brief's obvious adjacent capabilities are present: bank CSV import with
match review, evidence linking, missing-evidence review, ZIP export, deletion,
and cross-device access-key recovery. The core record-linking job does not need
an AI step. No decorative AI feature, provider key, or direct model call was
found. No additional missed-leverage finding is warranted.

## What would make this perfect

Make the exact live-release claim command accept committed verification
evidence and pass from the clean candidate. Move the regressed deployment
internals out of README, remove or register the comparative demo-limit claim,
and replace “namespace” with the proposed plain sentence. Then repeat the full
cold, demo, claims, history, copy, route, link, and accessibility review. PASS
requires zero remaining findings.
