# Independent product verification 2 — FAIL

Verified on 28 August 2026 for work order
`mtd-evidence-rail-verify-2`.

- Candidate: `9a357651212a07db848e3857217cfa1bc91240ca`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — do not release**

The clean local candidate passes its declared claims and quality gates. The
exact candidate is deployed. Production nevertheless splits workspace state
between multiple runtime instances or equivalent isolated storage domains.
The mandatory one-click demo and private workspaces therefore fail in normal
use.

## Release blocker

### Critical — live workspace state is split across three request targets

A fresh browser can create a demo successfully, then immediately receive 404
for the workspace it just created. Fresh evidence after all local checks:

- 12 new Chromium contexts opened `/demo`; **0/12 loaded sample data**.
- Each context recorded `POST /api/demo` = 201 followed by
  `GET /api/workspace` = 404.
- Every failure displayed: “The quarter could not load. This workspace was not
  found. Start a new workspace.”
- For one newly created demo key, 40 sequential reads returned 13 HTTP 200 and
  27 HTTP 404. The exact repeating sequence was `404, 404, 200`.
- For one newly created private key, 30 sequential reads returned 10 HTTP 200
  and 20 HTTP 404, with the same `404, 404, 200` sequence.
- A 180-request fixed-client API burst accepted 145 requests and limited 35.
  This inflated allowance is consistent with independent per-process limiters.

All 100 concurrent `/health` requests returned 200 and the candidate SHA, so
this is not stale code. The evidence indicates three healthy instances (or
three equivalent routing targets) using non-shared SQLite state. The current
README and previous handoff say production has one replica and shared durable
storage; observed production behavior contradicts both.

This breaks the real job-to-be-done: demo, capture, evidence linking, export,
deletion, and later retrieval depend on a request reaching the instance that
owns the workspace. It also falsifies the live durability and demo claims.
Occasional success does not mitigate the defect: the 15-test live suite passed
once immediately before the fresh-context run, demonstrating nondeterminism.

No separate high-, medium-, or low-severity defects were confirmed. All other
applicable gates described below passed; they do not offset the critical live
failure.

## Mandatory first-read and demo gate

The cold landing screen itself passes:

- **What it does:** “Link each expense to evidence.”
- **For whom:** “For sole traders who need a reviewable record before each MTD
  quarterly update.”
- **What to click first:** “Try it with sample data,” beside “See a ready
  quarter. Nothing is saved.”

The action is visible without scrolling on desktop and 390 px mobile. The
candidate still fails this mandatory gate because its one-click result failed
in all 12 final fresh contexts.

## Claims gate

`.factory/claims.json` exists and contains 18 claims. After `npm ci` in a
detached clean worktree at the candidate, every listed command was run exactly
and exited 0:

| Claim | Result | Evidence exercised |
| --- | --- | --- |
| `demo-isolation` | PASS locally | Separate `demo:` key, 24-hour response, reset |
| `no-account` | PASS locally | Private key created without credentials |
| `quarter-capture` | PASS locally | Income and expense in selected quarter |
| `csv-matching` | PASS locally | One likely match skipped, one row imported |
| `atomic-import` | PASS locally | Invalid batch returned 400 and saved zero rows |
| `calendar-dates` | PASS locally | Impossible date returned 400 |
| `evidence-types` | PASS locally | Five types and exact 5 MiB boundary |
| `missing-review` | PASS locally | Exactly two missing records shown |
| `evidence-pack` | PASS locally | ZIP signature, CSV, and evidence entries |
| `workspace-delete` | PASS locally | Deleted workspace returned 404 |
| `free-limit` | PASS locally | 26th unlicensed transaction returned 402 |
| `paid-limit` | PASS locally | Recorded valid verdict allowed 26 rows |
| `hosted-checkout` | PASS live | Sociobot returned hosted checkout redirect |
| `license-return` | PASS locally | Token stored, verified, and stripped from URL |
| `no-trackers` | PASS locally | Core demo flow remained same-origin |
| `runtime-defaults` | PASS locally | Service started with only `PORT` |
| `durable-storage` | PASS locally | Workspace survived a local service restart |
| `api-rate-limit` | PASS locally | Request 41 returned 429 and `Retry-After: 1` |

Passing single-process claim tests do not override the contradictory live
evidence. In particular, the local durability and demo tests cannot detect the
deployed split-state topology.

## Clean install, tests, type checks, and production build

All commands ran from the detached clean checkout, not the pre-existing dirty
shared tree.

| Command | Result |
| --- | --- |
| `npm ci` | PASS; 34 packages, 0 vulnerabilities |
| All 18 exact claim commands | PASS |
| `npm test` | PASS; typecheck, build, 4 Rust tests, runtime checks, 17 Chromium tests |
| `npm audit --audit-level=low` | PASS; 0 vulnerabilities |
| `cargo fmt --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run build` | PASS; produced `dist/` |

The exact frontend build is 30,079 bytes JS (10.26 kB gzip) and 16,617 bytes
CSS (4.73 kB gzip). Dockerfile review passes the mandated shape: separate
Node/Rust stages, `rust:1-slim`, `ARG BUILD_SHA=dev`, non-root runtime user,
`PORT=8080`, and no `.git` dependency. Docker and Podman are not installed in
the verifier container, so a second local image build was not possible.

## Functional and recovery checks

The full suite was also pointed at production, excluding the two tests that
require a recorded licence-verification fixture. It passed 15/15 once,
covering demo data, capture, CSV matching, atomic rejection, invalid dates,
file types and sizes, export, deletion, free enforcement, privacy, all routes,
Axe, keyboard behavior, mobile layout, and caching. The subsequent 12/12 demo
failure and repeating API probe show why one green run is not release evidence.

Against the clean local production server, independent boundary and recovery
checks passed:

- accepted £0.01 and £1,000,000, 120-character descriptions, 40-character
  categories, and both sides of the 5 July/6 July quarter boundary;
- rejected zero, negative, and over-limit amounts, 121-character descriptions,
  41-character categories, unknown kinds, malformed JSON, and 30 February;
- showed a useful zero-amount error, then saved after correction;
- rejected an unsupported evidence file, then linked a text file;
- rejected malformed CSV headings, then imported a corrected CSV;
- rendered an HTML payload as text without creating an element or executing it;
- downloaded a correctly named ZIP containing `transactions.csv` and evidence;
- deleted the workspace, removed its browser key, and returned home.

## Accessibility, responsive behavior, and motion

- `/opt/fleet/lib/verify-url.sh` passed: title, `en-GB`, one `h1`, `main`, image
  alternatives, labelled buttons, and no cold-load console errors.
- Playwright Axe found no serious or critical findings on `/`, `/demo`, `/app`,
  `/privacy`, `/terms`, or the real 404 route.
- Keyboard checks passed: skip link first, Enter opens the demo, dialog focus
  starts on the first field, Escape closes it, and focus returns to its trigger.
- The visible focus treatment measured a 3 px brass outline plus a dark 5 px
  halo.
- At 390 px, there was no normal horizontal overflow; all visible header and
  footer targets measured at least 44 px in both dimensions.
- Reduced motion produced `animation-name: none`, `transition-duration: 0s`,
  and `scroll-behavior: auto`.
- At 200% root text size the content and primary action remained present. The
  document measured 394 px against a 390 px viewport, without observed content
  loss.

## Privacy, headers, links, and deployment identity

- Cold load and the successful core demo privacy test made same-origin
  requests only. There are no analytics or third-party runtime scripts.
- Licence verification is the documented request to `api.sociobot.in`; the
  checkout link returned 303 to the hosted Dodo checkout.
- HTML sends CSP, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, and restrictive
  `Permissions-Policy`. `frame-ancestors 'none'` is correctly in the header.
- HTML and APIs use `no-cache`; hashed JS/CSS use one-year immutable caching;
  unversioned art and fonts use one-hour revalidation.
- Normal internal links returned 200, the checkout returned 303, external
  Sociobot resolved to 200, mail links were valid schemes, and an unknown route
  returned the designed page with HTTP 404.
- `/health` returned
  `9a357651212a07db848e3857217cfa1bc91240ca`; 100 concurrent health checks all
  returned that same SHA.
- Live `index.html`, JS, and CSS SHA-256 hashes exactly matched the local
  production build: `bab6b140…`, `13e452d6…`, and `f9ec521b…` respectively.

## Rate limiting

- Product API, one forwarded client: 180 simultaneous unauthenticated requests
  produced 145 HTTP 401 and 35 HTTP 429; all 35 limited responses had
  `Retry-After: 1`. A different forwarded client was not limited.
- Sociobot licence verification: 100 simultaneous invalid checks produced 30
  HTTP 200 and 70 HTTP 429; all 70 had `Retry-After: 4`.
- Source inspection confirms the governor wraps every `/api` route; `/health`
  is intentionally exempt.

The rate-limit behavior is present, but the product allowance is multiplied by
the same independent runtime topology implicated in the state failure.

## Performance and bundle budgets

Fresh mobile Lighthouse results:

- Performance 98, accessibility 100, best practices 100, SEO 100;
- FCP 1.05 s, LCP 1.88 s, speed index 1.05 s, TBT 132 ms, CLS 0;
- total transfer 180,619 bytes.

Budget checks pass: JS 30,079 bytes raw, CSS 16,617 bytes, fonts 102,036 bytes,
mobile hero 61,374 bytes, and desktop hero 173,422 bytes.

This is not a PWA and has no service worker, so offline/update tests do not
apply. It is not a library or CLI. It requires no sign-in, so the Entra tenant
check does not apply.

## Required remediation

1. Make every production request use one durable state boundary. Either enforce
   one running replica and one active revision, or move workspaces to a database
   shared safely by every replica.
2. Verify the deployed topology itself, not only the deployment script. From a
   newly created demo and private key, require 100/100 reads to return 200
   across new connections and after a revision restart.
3. Add a deployment smoke test that opens `/demo` in multiple fresh contexts
   and fails rollout on any workspace 404.
4. Re-run claim, persistence, paid-limit, deletion, rate-limit, and full live
   browser checks after the topology repair.
