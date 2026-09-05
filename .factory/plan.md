# MTD Evidence Rail — venture plan

**Plan date:** 5 September 2026

**Product:** `mtd-evidence-rail`

**Public URL:** <https://mtd-evidence-rail.sociobot.in>

**Current milestone:** M1 — accepted

**Next milestone:** M2 — accounts, tenant ownership, and proven subscription lifecycle

This plan is the milestone contract. It distinguishes accepted product
behaviour from fixture-backed demonstrations and future work. Later builders
must keep the current demo and public promises working while implementing only
the active milestone.

## Milestone decision

| Milestone | Status | Decision |
| --- | --- | --- |
| M1 — evidence pack core | **Passed** | Verification 21 accepted the exact live candidate `693a7609d2efb23c6567da5de0b425db92029e5c`. The current live health response still reports that SHA. |
| M2 — customer account and paid service | **Next; not started** | Sign-in and tenant ownership do not exist. Checkout metadata is live, but no successful payment, renewal, cancellation, expiry, or revocation journey has been verified. |
| M3 — reconciled quarter readiness | **Planned; not started** | Current CSV matching and missing-evidence views are useful M1 functions. Persisted reconciliation decisions, import undo, close checks, and an audit manifest are not shipped. |

Only M1 is a known passed venture milestone. M2 and M3 wording below is future
scope and must not appear as shipped capability until its tests pass against a
deployed candidate.

## 1. Product requirements

### Customer and situation

The primary customer is a UK non-accountant sole trader, especially a tutor or
micro-club operator, who must keep digital records for MTD quarterly updates.
They currently collect paper or photographed receipts, copy totals into a
spreadsheet, and assemble evidence close to the deadline. Full accounting
suites feel too broad and difficult to set up for this narrow job.

### Promise

Link every quarter transaction to reviewable evidence, then export one clear
pack for an accountant or filing workflow.

### Three jobs the product must nail

1. Capture income and expenses with their receipt, invoice, or note in the
   correct MTD quarter.
2. Review bank CSV rows, identify likely existing transactions, and import only
   the rows the customer accepts.
3. See every evidence gap early and export a complete, traceable quarter pack.

### Success measure

At least 80% of pilot users finish their evidence pack before the final week of
the period, with fewer than three unresolved transactions per quarter.

This is a product outcome, not a shipped claim. It requires a consented pilot
measurement and is not currently proven.

### Monetisation

- Public offer: free for up to 25 transactions per quarter; £15/month above
  that limit.
- Required payment path: Sociobot billing API only, with Dodo behind the hosted
  checkout. The product must never integrate directly with Dodo.
- Current proof: the live checkout route returns a Dodo-hosted session for the
  correct product, GBP 1500, and monthly cadence. Recorded verification fixtures
  prove the application can store a returned token and enforce the paid limit.
- Not yet proven: a real test purchase and the ensuing active, renewed,
  cancelled, expired, and revoked entitlement states. M1 must therefore not be
  described as a proven paid service.

### Deliberate non-goals through M3

- Filing updates or returns with HMRC.
- HMRC certification, tax calculations, or tax advice.
- Payroll, full double-entry bookkeeping, bank feeds, or open-banking access.
- Sending invoices or evidence by email or chat.
- Automated categorisation presented as authoritative.
- A multi-replica database deployment or shared PostgreSQL.

## 2. Evidence and wedge

### Demand signals

- [Ask HN, 26 February 2026](https://hn.algolia.com/api/v1/items/47171042):
  freelancers and tutors still use spreadsheets or notes, while commenters say
  mainstream tools are hard to set up around the 2026/2027 MTD thresholds.
- [Invoice Ninja issue 12114, 26 July 2026](https://github.com/invoiceninja/invoiceninja/issues/12114):
  a user asks for URL-backed receipt links because uploading documents into a
  general invoicing product is not a workable evidence connection.

### Wedge

Sell evidence completeness before filing. The product does not compete as a
general ledger; it makes the recurring quarter review calm, visible, and
exportable.

### Required discovery before M3 closes

- Observe at least five target users preparing a real or safely redacted
  quarter.
- Measure time to first linked transaction, unresolved items seven days before
  the deadline, and whether the exported pack is usable by an accountant.
- Test the £15/month threshold without implying that a checkout visit is a
  completed subscription.

## 3. Current product audit

### Accepted in M1

- A clear landing page, legal routes, designed 404, and one-click isolated demo.
- A 24-hour server-side demo with six transactions, four linked files, two
  missing items, reset, and separation from private browser state.
- No-account private workspaces protected by a random 64-character bearer key,
  including key copy and recovery on another device.
- Manual income and expense capture in dated MTD quarters.
- PDF, JPG, PNG, WebP, and text evidence up to 5 MiB.
- Bank CSV preview with exact amount-and-date likely-match flags and atomic
  import of accepted new rows.
- A separate missing-evidence view.
- ZIP export containing `transactions.csv` and linked evidence.
- Workspace and evidence deletion.
- A server-enforced 25-transaction free limit.
- SQLite persistence on the product's `/data` mount, one active revision, one
  replica, forwarded-client rate limits, secure headers, and structured logs.
- Keyboard, mobile, reduced-motion, accessibility, performance, privacy, and
  claim-test gates recorded by verification 21.

### Implemented mechanics that are only demonstrated

| Capability | Evidence available | Why it is not a completed venture capability |
| --- | --- | --- |
| Hosted subscription checkout | Live route proves Dodo host, product id, GBP 1500, monthly cadence. | No payment was completed in QA. This proves the checkout contract, not a paying customer. |
| Paid limit enforcement | A recorded valid Sociobot verification response lets the server accept record 26. Invalid live verification and gateway throttling were probed. | No real successful subscription token was exercised through purchase, renewal, cancellation, expiry, and revocation. |
| Workspace separation | Every protected API route rejects missing and unknown 64-character keys. | A bearer key is a capability secret, not sign-in, user ownership, membership, or independently proven tenant isolation. |
| Audit history | The database writes internal entries for record creation and evidence link/removal. | There is no user-visible history, no append-only guarantee, and no audit export. |
| Bank matching | The browser flags equal date and amount and skips likely matches. | Decisions are not persisted; there is no import batch, undo, statement lineage, or false-match measurement. |

### Not implemented

- Sign-in, user accounts, sessions, tenants, memberships, or roles.
- A proven end-to-end paid subscription lifecycle.
- Transactional messaging or deadline reminders.
- HMRC connectivity, filing, certification, or tax advice.
- Automated backups with a tested restore procedure.
- Product metrics for the pilot success measure.

## 4. Architecture and data boundaries

### Current deployed shape

```text
Browser
  ├─ same-origin pages and /api/*
  │       └─ Rust axum service on PORT 8080
  │              └─ SQLite + evidence blobs at /data/evidence-rail.sqlite
  └─ explicit checkout or licence verification action
          └─ api.sociobot.in ── hosted Dodo checkout
```

- Frontend: Vite and vanilla TypeScript, built into `dist/` and served by the
  Rust service.
- Backend: Rust 2021, axum, Tokio, SQLx, SQLite, tower-governor, JSON tracing.
- Deployable: one multi-stage, non-root container; `/health` returns build SHA.
- Production state: one replica using the fleet-created durable `/data` mount
  and `SQLITE_VFS=unix-dotfile`. No shared PostgreSQL exists or is planned.
- Evidence storage: blobs live inside the same SQLite ownership boundary.
- Demo: `demo:<64 hex>` key in `sessionStorage`, server TTL of 24 hours.
- Private M1 workspace: 64-hex key in `localStorage`, sent as
  `X-Workspace-Key` to every private API request.
- Current subscription token: browser storage under the product-specific
  Sociobot key; the server hashes tokens before caching a verdict.

### Current data model

| Entity | Current ownership and purpose |
| --- | --- |
| `workspaces` | Key-addressed private or expiring demo boundary. No user or tenant owner exists. |
| `records` | Transaction plus invoice number and optional evidence blob; owned by `workspace_id`. |
| `audit_log` | Internal action rows by workspace and record; not exposed to users. |
| `license_cache` | SHA-256 token hash, validity, and check time; never stores the raw token server-side. |

### M2 target ownership model

Add, with reversible SQLx migrations:

- `users(id, external_subject, email_normalized, created_at, deleted_at)`;
- `tenants(id, name, created_at, deleted_at)`;
- `memberships(tenant_id, user_id, role, created_at)` with `owner` as the only
  M2 role;
- `sessions(id_hash, user_id, expires_at, created_at, last_seen_at)` if the CIAM
  integration needs a server session after callback;
- `workspace_claims(workspace_id, tenant_id, claimed_at, legacy_key_hash)` to
  migrate an existing key workspace without copying or exposing another
  workspace;
- `subscriptions(tenant_id, provider_product, entitlement_state,
  provider_reference_hash, checked_at, current_period_end)`.

Every query that reads or mutates customer data must include `tenant_id` from a
verified session. A test must attempt every protected route as tenant B against
tenant A's ids and files. Status codes and timing must not reveal whether the
other tenant's object exists. Demo endpoints remain outside the account tables
and cannot read them.

### M3 target records

- `import_batches(id, tenant_id, source_name, source_sha256, imported_at,
  reversed_at)`;
- `bank_rows(id, batch_id, posted_on, description, amount_pence, fingerprint,
  decision, matched_record_id)`;
- `readiness_exceptions(id, tenant_id, quarter_start, record_id, kind, state,
  resolved_at)`; and
- expanded append-only activity events used by the evidence-pack manifest.

### Security, operations, and privacy

- Keep all state under `/data`; environment values may override defaults but
  cannot be required for basic startup.
- Retain one active revision and one replica while SQLite is the store. Every
  release must re-prove mount, VFS, restart persistence, and fresh-connection
  reads.
- Keep all endpoints rate limited except health. Auth and write routes get
  stricter policies and `429` with `Retry-After`.
- Keep CORS same-origin for the product API. External browser requests remain
  limited to explicit Sociobot billing/auth actions documented in privacy copy.
- Evidence remains user-exportable and deletable. M2 deletion must remove
  tenant records, evidence, sessions, subscription references, and audit data
  according to the published retention policy.
- Add a fleet-operated `/data` backup and restore drill in M2. A source-level
  persistence test is not proof of a backup.
- Keep `/health`; add internal operational counters for request errors, rate
  limiting, demo cleanup, storage capacity, and billing/auth dependency errors.
  Do not log workspace keys, session tokens, licences, emails, or file contents.
- Current demo cleanup occurs during demo creation. M2 should add an in-process,
  single-replica expiry job with idempotent deletion and a test clock.
- No runtime AI is planned. Exact matching is explainable, cheap, and sufficient
  for the current job. Any future model feature must use the Sociobot gateway,
  be optional, explicit, reversible, and fixture-tested.

## 5. Design system contract

The source of truth remains [`.factory/design.md`](design.md).

### Direction and tokens

- Direction: surreal editorial paper-moon evidence railway.
- Palette: Ink `#102520`, Night `#092a32`, Paper `#f4efe2`, Chalk `#fffaf0`,
  Moss `#245c4f`, Signal `#e35f3d`, Brass `#e8bf62`, Sage `#c8d8bf`, Fog
  `#66746e`, Danger `#a3362d`.
- Type: self-hosted Fraunces for headings and Atkinson Hyperlegible for body and
  tables.
- Type scale: 16, 18, 23, 32, 48, 64 px. Spacing uses an 8 px base and 4 px
  only within compact status labels.
- Shape: paper labels, ticket corners, rail lines, and brass evidence markers.
- Motion: one 700 ms train arrival and 150–300 ms state changes; no loops;
  instant or opacity-only changes for reduced motion.

### Component inventory and required states

1. site header and four-link navigation;
2. skip link and route announcement;
3. first-screen job statement and facts;
4. primary, secondary, quiet, destructive, and text actions;
5. quarter selector and rail;
6. summary strip;
7. transaction list/table and mobile row;
8. evidence status marker;
9. missing-evidence filter;
10. demo banner with reset and private-workspace action;
11. modal/dialog shell with focus return;
12. labelled text, date, amount, select, and file fields;
13. CSV review table;
14. loading, empty, error, offline, and success notices;
15. import/export progress state;
16. workspace settings and destructive confirmation;
17. subscription ticket and restore form; and
18. legal, footer, and designed 404 surfaces.

M2 adds account status, session-expired recovery, tenant switch guard, and
billing-state panels using the same grammar. M3 adds persisted import batches,
match decisions, readiness exceptions, and activity-manifest views.

### Five key screens

1. Landing: job, audience, sample action, private start, three facts, live
   preview, scope, current price, and legal footer.
2. Demo quarter: populated sample above the fold, persistent isolation banner,
   reset, all core actions, and no private state access.
3. Customer quarter: dated transactions, evidence state, missing queue, and
   export, with M2 account/session status.
4. Bank import review: source summary, likely matches with reasons, explicit
   accept/skip decisions, error recovery, and M3 batch undo.
5. Settings and subscription: export/delete/recovery today; M2 account,
   subscription state, and workspace claim without exposing secrets.

### Responsive and accessibility rules

- Start at 390 px. Stack record metadata and actions; keep named sample content
  in the first demo viewport; tables become labelled rows rather than clipping.
- Body text is at least 16 px, controls at least 44×44 px, adjacent targets have
  at least 8 px, zoom remains enabled, and 200% text introduces no horizontal
  scrolling.
- Every route has one H1, ordered headings, header/nav/main/footer landmarks,
  correct title and canonical, and H1 focus after SPA navigation.
- All forms retain visible labels and assertive error descriptions. Dialogs
  trap focus only while open and return focus to the trigger.
- Focus keeps the 3 px brass outline plus dark surround. State never relies on
  colour alone. WCAG AA contrast and zero serious/critical axe findings are
  milestone gates.

## 6. Milestones

### M1 — evidence pack core

**Status:** Passed and live. Do not reopen without a regression.

**Routes:** `/`, `/demo` and `/?demo=1`, `/app`, `/privacy`, `/terms`, designed
404, `/health`, and current `/api/*` workspace/record/evidence/export routes.

**Definition of done — met**

- A stranger reaches a realistic isolated sample in one click.
- A private workspace completes capture → evidence link → missing review → ZIP
  export without sign-in.
- Bank CSV review identifies the documented exact date/amount suggestion and
  atomically imports accepted new rows.
- User-controlled export and deletion work.
- Every current public claim has one executable test.
- Local test, lint, build, accessibility, mobile, privacy, rate-limit,
  persistence, deployment identity, and live topology gates pass.

**Claims and tests:** [`.factory/claims.json`](claims.json) is canonical.

| Claim group | Claim ids | Required test |
| --- | --- | --- |
| Demo and access | `demo-isolation`, `demo-sample`, `no-account`, `workspace-key-recovery`, `workspace-key-auth` | `npm test -- --grep @claim:<id>` |
| Core records | `quarter-capture`, `calendar-dates`, `evidence-types`, `workspace-delete` | `npm test -- --grep @claim:<id>` |
| Import and readiness | `csv-matching`, `atomic-import`, `missing-review`, `evidence-pack` | `npm test -- --grep @claim:<id>` |
| Limits and licence mechanics | `free-limit`, `paid-limit`, `license-return` | `npm test -- --grep @claim:<id>`; paid tests use recorded verification and do not prove a purchase |
| Privacy | `no-trackers` | `npm test -- --grep @claim:no-trackers` |
| Runtime and storage | `runtime-defaults`, `durable-storage`, `shared-state-boundary`, `production-topology`, `api-rate-limit` | exact command in each claim entry |
| Live release | `hosted-checkout`, `live-workspace-consistency`, `live-release-identity`, `live-api-rate-limit` | exact live command in each claim entry; checkout proves destination/price/cadence only |

**Acceptance evidence:** [verification 21](verification-21.md),
[claim results](evidence/verification-21/claims/results.tsv),
[independent live audit](evidence/verification-21/independent-live-audit.json),
[local test log](evidence/verification-21/local/npm-test.log), and
[Lighthouse summary](evidence/verification-21/lighthouse-summary.json).

**Carried verification work:** after every future deployment, rerun the exact
candidate identity, one-replica `/data` topology, restart persistence, 100/100
private and demo fresh-connection reads, 12-browser demo smoke, and three-wave
rate-limit checks. The verifier environment could not assemble the Docker image
locally; repeat image assembly in the next Docker-capable QA environment.

### M2 — customer account and paid service

**Status:** Next milestone. Not shipped. Blocked from final acceptance by the
external identity, billing-lifecycle, and backup dependencies listed below.

**Goal:** turn the accepted key-based utility into a recoverable customer
service with identity-owned data and a genuinely proven £15/month entitlement.

**Routes/screens to add:** `/sign-in`, `/auth/callback`, `/account`, `/billing`,
account/session states within `/app`, and authenticated API middleware. Keep all
M1 routes and `/demo` working.

**Scope**

- Integrate Sociobot Entra CIAM using authorization code with PKCE and secure,
  HttpOnly, SameSite cookies. Do not invent credentials or accept raw identity
  assertions from the browser.
- Introduce user, tenant, membership, session, workspace-claim, and subscription
  ownership tables.
- Let an authenticated customer claim one existing key workspace after proving
  possession of its key. The operation is transactional, one-time, audited,
  and does not expose whether another tenant owns a workspace.
- Require tenant ownership for every private record, evidence, export, billing,
  and deletion operation. Keep demo traffic outside this boundary.
- Complete the Sociobot-hosted subscription flow and attach the verified
  entitlement to the tenant. Handle active, unavailable, expired, and revoked
  states without blocking the free experience.
- Add account-level export and deletion, session expiry/recovery, dependency
  failure states, operational counters, and a tested `/data` backup restore.

**Definition of done**

- A new target customer can sign in, claim or create a workspace, add evidence,
  and reopen it on another device without copying a bearer key.
- Tenant A cannot observe or mutate tenant B's ids, rows, evidence, exports,
  subscription state, timing-sensitive existence, or deletion results across
  every route.
- A factory-operated non-production billing lifecycle proves successful hosted
  checkout, return, active entitlement, record 26 acceptance, cancellation or
  revocation, and subsequent free-limit enforcement. No production credential
  is given to or requested by the builder.
- Existing anonymous workspaces remain usable and can be claimed safely. No
  M1 user loses export or deletion.
- Account deletion removes all tenant data and invalidates every session.
- A backup is restored into an isolated instance and record/evidence hashes
  match before and after.
- M1 claims remain green. New claims are added to `.factory/claims.json` only
  when the behaviour is ready to ship.

**Planned claims and required tests**

| Planned claim id | Public claim after acceptance | Test |
| --- | --- | --- |
| `account-recovery` | Sign-in opens the same records on another device. | Playwright with two clean contexts and a factory test identity; create in one, sign in in the other, assert identical record and no bearer-key transfer. |
| `tenant-isolation` | Each account can access only its own records and files. | Rust route matrix plus browser/API test across two test tenants and every protected method; assert 404/403 without existence leakage. |
| `workspace-claim` | An existing workspace can be moved into an account with its access key. | Migration integration test; correct key succeeds once, wrong key fails, second tenant cannot claim, records/evidence hashes stay equal. |
| `subscription-lifecycle` | An active £15/month subscription raises the quarter limit. | Factory billing sandbox: complete checkout, verify return, accept row 26, revoke/cancel, then reject the next over-limit write. No mocked verdict for the acceptance run. |
| `account-delete` | Deleting the account removes its records, files, sessions, and subscription reference. | API integration plus second-session browser check and direct database orphan assertions. |
| `backup-restore` | Customer records and evidence can be restored from the product backup. | Restore a fleet snapshot to an isolated product instance and compare record counts and evidence SHA-256 values. Keep this operational claim out of marketing copy unless publicly stated. |

### M3 — reconciled quarter readiness

**Status:** Planned and gated on M2 acceptance. Not shipped.

**Goal:** make the second and third customer jobs reliable: reconcile bank rows
with explicit decisions, then close a quarter with a traceable exception list
and evidence manifest.

**Routes/screens to add:** `/app/imports`, `/app/imports/:id`,
`/app/quarters/:period/readiness`, and an activity/manifest panel in the
quarter export flow.

**Scope**

- Persist CSV files as hashed import batches and normalized bank rows without
  retaining the original file after parsing unless the user explicitly keeps
  it as evidence.
- Show match reasons. Exact date/amount remains a suggestion, never an automatic
  accounting decision.
- Let the user accept, skip, link, or mark a row for review. Persist the decision
  and actor. Support one-click transactional undo of an import batch.
- Detect repeated source files and repeated row fingerprints before mutation.
- Extend readiness beyond missing files to unresolved bank rows, duplicate
  candidates, and evidence-link changes. Never block export; label incomplete
  packs clearly.
- Add an evidence manifest with file hashes and relevant activity events to the
  existing ZIP. Keep the readable transaction CSV and files.
- Measure the pilot outcome with consented, privacy-minimal product events or a
  documented manual pilot process. Do not add advertising analytics.

**Definition of done**

- Three representative bank CSV formats import through preview and explicit
  decisions; malformed and repeated inputs recover without partial writes.
- Match precision and false-match behaviour are tested on a labelled fixture
  corpus. No row is silently linked.
- Import undo restores the prior record/readiness state atomically.
- Readiness counts equal unresolved database rows at quarter boundaries and
  after evidence changes, deletion, import, and undo.
- Export includes the transaction CSV, evidence, manifest, hashes, and honest
  incomplete-state note. An accountant can verify the manifest offline.
- M1 and M2 claims remain green and live deployment topology is reverified.

**Planned claims and required tests**

| Planned claim id | Public claim after acceptance | Test |
| --- | --- | --- |
| `persisted-match-review` | Bank matches stay in review until the customer decides. | Import labelled fixtures, reload and sign in from another context, assert decisions persist and no suggestion auto-links. |
| `duplicate-import` | Re-importing the same bank file is detected before records change. | Submit identical and reordered fixture files; assert warning, stable counts, and no mutation before confirmation. |
| `import-undo` | A bank import can be undone without removing earlier records. | Import one batch, capture ids, undo, assert only batch-created records/rows disappear and activity records the reversal. |
| `quarter-readiness` | The quarter shows every unresolved evidence and bank-row exception. | Seed boundary-date and exception fixtures; assert UI and database counts across resolve/reopen operations. |
| `evidence-manifest` | The exported pack contains a verifiable evidence manifest. | Download ZIP, recompute file hashes, compare manifest, and assert incomplete packs are labelled. |

## 7. Exact external dependencies

| Dependency | Current state | Milestone effect and owner |
| --- | --- | --- |
| Sociobot Entra CIAM product registration | **Unavailable; sign-in is not implemented.** Issuer/discovery URL, client registration, allowed callback/logout URLs, and factory test identities are not present in this repository. | Blocks M2 identity and tenant acceptance. Factory/platform owner supplies configuration through the supported runtime mechanism and runs the test-identity setup. The product worker must not request or receive production credentials. |
| Sociobot billing subscription lifecycle | **Partly reachable, not end-to-end proven.** Checkout currently reports the correct product, GBP 1500, and monthly cadence; fixture tests cover valid entitlement mechanics. | Blocks M2 paid-service acceptance until the factory provides a non-production successful purchase plus cancellation/revocation path and verifier control. Builder uses only `api.sociobot.in`; no direct Dodo integration or production credential. |
| Dodo Payments | **Indirect hosted checkout only.** No product-owned integration or credential exists. | Not a direct builder dependency. Sociobot is the sole billing boundary and merchant integration. |
| Fleet `/data` mount | **Available and accepted for M1.** Live QA proves one replica, Azure Files at `/data`, and `unix-dotfile`. | Required for every milestone. Factory deployment must preserve it. A future rollout that loses the mount is a release blocker, not a reason to move to shared PostgreSQL. |
| Fleet backup/restore facility | **No accepted restore evidence.** Restart persistence is proven; backup recovery is not. | Blocks the M2 backup DoD. Factory/operator runs an isolated snapshot-and-restore drill without exposing storage credentials to the builder. |
| Transactional messaging | **Unavailable and not implemented.** | Not required for M1–M3 and must not be promised. Deadline email/SMS is deferred to a later operations milestone after an approved provider and consent model exist. |
| HMRC API access or certification | **Unavailable and deliberately out of scope.** | No M1–M3 blocker because the product does not file. Do not request credentials or imply compatibility/certification. |
| Pilot users and redacted bank CSV corpus | **Not yet evidenced.** | Needed to validate M3 matching and the venture success measure. Product owner recruits consented UK sole-trader/tutor/micro-club pilots; builders use only synthetic or explicitly redacted fixtures. |

## 8. Risks and experiments

| Risk or unknown | Experiment that retires it | Decision gate |
| --- | --- | --- |
| Sign-in may add more friction than key recovery removes. | Five moderated first-use sessions comparing the M1 key flow with M2 sign-in and workspace claim. | At least four of five reopen their workspace unaided on a second device. |
| A bearer-key migration could attach data to the wrong tenant. | Adversarial two-tenant claim tests with retries, concurrent claims, guessed ids, and post-claim old-key use. | Exactly one owner; no cross-tenant read/write; documented old-key outcome. |
| Customers may not pay £15/month for a narrow evidence rail. | Factory sandbox lifecycle first, then an honest paid pilot offer to the target audience. | Do not call billing shipped until one complete test lifecycle passes; do not use checkout visits as paid conversion. |
| Exact date/amount matching may create false duplicates. | Label at least 200 synthetic/redacted bank rows including same-day equal amounts and measure suggestion precision. | No silent decisions; false positives remain reviewable and below the pilot-agreed threshold. |
| SQLite plus evidence blobs may exhaust or slow the mounted share. | Load a one-year upper-bound fixture, measure p95 reads/writes/export, file size, lock time, and restore time. | Keep p95 interactions usable and establish storage alerts before M2 acceptance. |
| Internal audit rows may be mistaken for a legal audit trail. | Define the accountant-facing manifest fields and tamper checks with an accountant before M3 implementation. | Until accepted, call it activity history, not a certified audit trail. |
| MTD rules or dates may change. | Quarterly copy/legal review against official public guidance, without connecting to HMRC. | Update explanatory copy and date fixtures; never infer filing certification. |
| The success measure could encourage tracking financial behaviour. | Use consented, minimal milestone timestamps or a manual pilot log with no document contents. | No advertising identifiers, third-party analytics, or evidence content in metrics. |

## 9. Release discipline

- A milestone passes only from a clean checkout with all declared claim commands,
  `npm test`, `npm run lint`, `npm run build`, locked release build, audit,
  accessibility, mobile, security, performance, and live candidate/topology
  verification green.
- Demo mode must remain a separate ephemeral boundary through every milestone.
- Claims for planned features enter public copy and `.factory/claims.json` only
  in the milestone that implements them.
- Review and polish findings remain open until the next independent verification
  explicitly closes them. Historical failures are not current defects, but
  their regression tests and topology checks must be preserved.
- Planner documentation is committed and pushed but is not deployed or passed
  through a product build wrapper.
