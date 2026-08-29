# Independent product verification 5 — FAIL

Verified 29 August 2026 for work order `mtd-evidence-rail-verify-5`.

- Candidate: `27670a3936562efa179e7a9bc6ad0b97546bc099`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — the live service loses access to workspaces across three unshared replicas**

The candidate source, clean claim tests, build, accessibility, checkout contract,
and static deployment identity are good. The live deployment is not. Azure is
running three replicas with no persistent volume, although the product contract
requires one replica and an Azure Files mount at `/data`. Real browser and API
requests rotate between three private SQLite databases. This breaks the demo,
transaction writes, reads, deletion, and the intended shared rate limit.

## Release-blocking findings

### Critical — production runs three isolated ephemeral databases

Fresh Azure control-plane evidence reports:

- image `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:27670a393656`;
- one active revision with 100% traffic;
- `minReplicas: 1`, **`maxReplicas: 3`**, and **three running replicas**;
- **no volume mount** and **no Azure Files volume**;
- only `PORT=8080`; no deployment `SQLITE_VFS=unix-dotfile` setting.

This directly contradicts the `production-topology` claim and README deployment
contract. The behaviour is deterministic:

- Twelve new demo workspaces returned only **48/120 successful reads**;
  **72/120 returned 404**.
- A browser's first demo load received `POST /api/demo` 201 followed by two
  `GET /api/workspace` 404 responses. The sample appeared only after two manual
  **Try again** actions reached the owning replica.
- The repository's 12-context live smoke failed because sample data did not
  appear within 15 seconds.
- Twenty concurrent writes to one private workspace produced **7×201 and
  13×404**. The workspace contained nine records instead of the expected 22.
- Every boundary and validation probe had to pass through two false 404
  responses before the owning replica returned the correct 201/400/415/200.

This prevents the smallest useful product from working reliably. A customer can
create a workspace and immediately be told it does not exist.

Evidence: [control plane](evidence/verification-5/control-plane.json),
[replicas](evidence/verification-5/replicas.json),
[12-workspace read probe](evidence/verification-5/live-persistence-probe.json),
[browser observation](evidence/verification-5/live-browser-observation.json),
[API audit](evidence/verification-5/live-api-audit.json), and
[failed 12-context smoke](evidence/verification-5/live-demo-12-contexts.log).

### Critical — deletion can report success while retaining workspace data

The live API returned 204 for a workspace deletion, but two of the next six
reads returned 200 with the records still present. The delete request reached a
replica that did not own the workspace; the handler is idempotent and returned
204 while the owning replica retained the data. This falsifies the privacy-page
and README promise that deleting a workspace removes its records and files.

Evidence: `delete.attempts` and `readAfterDelete` in the
[live API audit](evidence/verification-5/live-api-audit.json).

### High — the per-client allowance is multiplied by the replica count

The source limiter is a 40-request burst replenished at 20 requests/second. The
local claim correctly rejects the 41st immediate request with 429 and
`Retry-After: 1`. Live, one client sent 600 requests in 2.168 seconds: **183
were accepted** and 417 returned 429. Every 429 had `Retry-After: 1`, but three
process-local limiters materially increase the documented per-client allowance.

The separate Sociobot subscription verification endpoint behaved correctly:
30/120 requests returned 200 and 90 returned 429, every rejection had
`Retry-After: 4`, successful responses used `Cache-Control: no-store`, and CORS
allowed the product origin.

Evidence: [product limiter](evidence/verification-5/live-rate-limit.json) and
[billing limiter](evidence/verification-5/billing-rate-limit.json).

## Mandatory first-read and demo gate

**First-read copy: PASS. One-click demo operation: FAIL live.**

The cold 1440×900 first screen says:

- what it does: “Link each expense to evidence”;
- who it is for: sole traders preparing reviewable MTD quarterly records;
- what to click: “Try it with sample data,” with “See a ready quarter. Nothing
  is saved.” beside it.

The action is above the fold at desktop and 390 px. However, the first click
does not reliably load the sample because the following workspace read usually
lands on another replica. The candidate therefore fails the mandatory demo
gate despite correct first-screen copy.

Evidence: [cold text capture](evidence/verification-5/first-read-live.txt),
[cold screenshot](evidence/verification-5/first-read-live.png), and
[browser retry sequence](evidence/verification-5/live-browser-observation.json).

## Claims gate

A detached clean worktree at the exact candidate SHA was installed with
`npm ci`. It remained clean after the run. All 20 commands from
`.factory/claims.json` were executed exactly as declared and exited zero.

| Claim | Clean result | Observable check |
| --- | --- | --- |
| `demo-isolation` | PASS | separate `demo:` key, 24-hour expiry, reset |
| `no-account` | PASS | account-free 64-character local key |
| `quarter-capture` | PASS | income and expense in dated quarter |
| `csv-matching` | PASS | amount/date likely match skipped |
| `atomic-import` | PASS | rejected batch saved no rows |
| `calendar-dates` | PASS | impossible date returned 400 |
| `evidence-types` | PASS | five types, 5 MiB edge, over-limit rejection |
| `missing-review` | PASS | exactly two missing sample records |
| `evidence-pack` | PASS | ZIP contains CSV and evidence entries |
| `workspace-delete` | PASS locally | deleted local key returned 404; contradicted live |
| `free-limit` | PASS | 26th free transaction returned 402 |
| `paid-limit` | PASS with fixture | recorded valid verdict allowed 26 records |
| `hosted-checkout` | PASS live | Dodo, product ID, GBP 1500, monthly cadence |
| `license-return` | PASS with fixture | stored, verified, and stripped token |
| `no-trackers` | PASS | demo flow stayed same-origin |
| `runtime-defaults` | PASS | server started with only `PORT` |
| `durable-storage` | PASS locally | workspace survived local restart |
| `shared-state-boundary` | PASS locally | three processes shared configured store |
| `production-topology` | PASS source renderer | live control plane contradicts claim |
| `api-rate-limit` | PASS locally | 41st burst request returned 429 + header |

The claims registry covers the material product promises found in the landing
page and README. The failure is not a missing local claim test; it is the live
environment contradicting tested deployment and deletion claims.

Evidence: [clean summary](evidence/verification-5/clean-claims-summary.tsv) and
the individual `clean-claim-*.log` files in the same directory.

## Install, tests, type/lint, and production build

| Command | Result |
| --- | --- |
| `npm ci` in detached clean worktree | PASS; 34 packages, 0 vulnerabilities |
| all 20 exact claim commands | PASS |
| `npm test` | PASS; 4 Rust tests and 21/21 Chromium tests |
| `npm run typecheck` | PASS via `npm test` |
| `npm run build` | PASS; emitted `dist/` |
| `cargo fmt -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS; 0 vulnerabilities |

Docker and Podman are unavailable in the worker. The Dockerfile was inspected:
it is multi-stage, uses `rust:1-slim`, declares `ARG BUILD_SHA=dev`, runs as UID
10001, exposes 8080, and needs no secret at startup.

Evidence: [full suite](evidence/verification-5/npm-test.log) and
[static quality](evidence/verification-5/static-quality.log).

## Live identity and end-to-end behaviour

The deployed artifact is the candidate:

- `/health` returns the full candidate SHA and `status: ok`;
- live HTML, JS, and CSS SHA-256 hashes exactly equal the clean production
  build;
- `/`, `/demo`, `/app`, `/privacy`, and `/terms` return 200; the designed
  unknown route returns a real 404.

When a request reaches the owning replica, normal and edge behaviour is sound:
£0.01 and £1,000,000 are accepted at a quarter boundary; zero, negative,
over-limit amounts, impossible dates, unknown kinds, and overlong fields return
clear 400 messages; unsupported evidence returns 415; text evidence recovers;
and export returns an application/ZIP payload beginning `PK`. Across the actual
deployment, each case was preceded by two false workspace 404s.

The live Playwright suite passed 20/21 tests. Its only failure sent the literal
local fixture token `fixture-valid-license` to production and correctly received
402 instead of the fixture's expected 201. The declared paid-limit claim is a
recorded-fixture test and passed locally; no real subscription credential was
available or fabricated.

Evidence: [health and headers](evidence/verification-5/live-identity.log),
[static hashes](evidence/verification-5/static-identity-and-headers.txt),
[live Playwright](evidence/verification-5/live-playwright.log), and
[live API audit](evidence/verification-5/live-api-audit.json).

## Privacy, security headers, and network activity

- The cold landing and demo/retry flow contacted only
  `https://mtd-evidence-rail.sociobot.in`; no tracker, third-party script, or
  CDN font request appeared.
- The expected 404 workspace responses produced browser console resource
  errors. A normal cold landing had no console or page errors.
- HTML and API responses send CSP, `X-Content-Type-Options`, `Referrer-Policy`,
  `Permissions-Policy`, and `Cache-Control: no-cache`.
- CSP limits runtime connections to self and `https://api.sociobot.in`, and
  sends `frame-ancestors 'none'` as a response header.
- Hashed JS uses one-year immutable caching. Unversioned images and fonts use
  one-hour revalidation.
- No sign-in exists, so the Entra authority rule does not apply.
- No runtime AI feature is claimed or needed for the brief's core workflow.

The live deletion defect above prevents the product from satisfying its
privacy promise even though the request-origin policy is correct.

## Accessibility, keyboard, mobile, and motion

- Factory `verify-url.sh`: PASS; title, `en-GB`, one h1, main landmark, image
  alternatives, labelled buttons, and zero cold-load console errors.
- Local suite: zero Axe violations on `/`, `/demo`, `/app`, `/privacy`,
  `/terms`, and the 404 route. The live route run also passed these checks when
  it reached the owning demo replica.
- Keyboard: the skip link is first in tab order; primary demo activation works
  with Enter; dialogs focus the first field and Escape returns focus.
- Visible focus is a 3 px brass outline with a 3 px offset and dark halo.
- At 390 px the primary action is 366×54.8 px, above the fold, with no
  horizontal overflow. The 200% text-size regression test passes.
- Reduced motion reports animation `none`, transition `0s`, and scroll
  behaviour `auto`.

Evidence: [factory verifier](evidence/verification-5/verify-url/verify.json),
[browser observation](evidence/verification-5/live-browser-observation.json),
and [full suite](evidence/verification-5/npm-test.log).

## Performance and bundle budgets

Fresh mobile Lighthouse:

- Performance 99, Accessibility 100, Best Practices 100, SEO 100;
- FCP 1.1 s, LCP 1.8 s, TBT 0 ms, CLS 0;
- transferred 180,735 bytes.

Build assets remain within contract: JS 30,362 bytes raw / 10.31 kB gzip; CSS
16,961 raw / 4.80 kB gzip; fonts 102,036 bytes total; mobile hero 61,374 bytes.

Evidence: [Lighthouse summary](evidence/verification-5/lighthouse-summary.json)
and [asset sizes](evidence/verification-5/static-identity-and-headers.txt).

This is not a PWA and makes no offline-use claim, so service-worker update and
offline reload do not apply. It is not a library or CLI.

## Required release action

Deploy the source-owned topology before re-verification: one replica, one
container, Azure Files mounted at `/data`, and `SQLITE_VFS=unix-dotfile`. Then
prove that fresh private and demo workspaces return 100/100 reads before and
after a real revision restart, deletion makes all subsequent reads return 404,
and the product limiter enforces one shared client allowance.

No product code was modified during verification.
