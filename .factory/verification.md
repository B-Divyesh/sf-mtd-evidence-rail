# Independent product verification — FAIL

Verified on 28 August 2026 for work order `mtd-evidence-rail-verify-1`.

- Candidate: `6dce6ebc5694c51e173cdf95086297f722ef20bc`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Repository state tested: candidate commit, followed by `npm ci`
- Artifact class: web with backend
- Result: **FAIL — do not release**

The deployed `/health` response identifies the exact candidate SHA. SHA-256
hashes of live `index.html`, JS, and CSS also match the local production build.
This is therefore a result for the named candidate, not a stale deployment.

## Release blockers

### Critical — live workspaces are split between backend replicas

The backend stores all state in a local SQLite file under `/data`, while the
live ingress sends requests to multiple instances without shared storage or
reliable affinity. A key created successfully on one request is unknown on
another instance.

Fresh live evidence:

- Repeating `GET /api/workspace` 40 times with one newly created key returned
  20 HTTP 200 responses and 20 HTTP 404 responses.
- A second sequence could import 26 records only on its third attempt; four
  reads of the same key returned 404, 404, 200 with 26 records, then 404.
- 12 of 12 fresh Chromium contexts opening `/demo` ended at “The quarter could
  not load. This workspace was not found.” One later retry happened to reach
  the correct replica and loaded the sample.
- The failing live state is captured in
  `evidence/verification-1/demo-failure.png`.

This breaks the mandatory one-click demo and the core private-workspace job.
It also makes persistence and deletion unreliable. Local tests pass because
they run one server process against one SQLite file.

### High — checkout is unavailable and paid limits are not enforced by the server

- The visible **Buy paid access** link returns HTTP 404 from
  `https://api.sociobot.in/api/v1/products/mtd-evidence-rail/checkout` with
  `{"error":"enabled factory product","status":404}`.
- A public `POST /api/records/import` accepted 26 records with HTTP 201, and a
  successful read reported 26 records. No licence is sent to or checked by the
  backend.
- Paid state is decided only from writable browser `localStorage`. The API
  cannot distinguish a free workspace from a paid one.

This falsifies the listed claim that a free workspace accepts 25 transactions
per quarter and means payment neither works nor protects the paid feature.

### High — required claim coverage is incomplete

All seven listed claim tests pass locally, but `.factory/claims.json` does not
list every claim made by the live product and README. Unlisted examples include:

- workspace and file deletion;
- support for PDF, JPG, PNG, WebP, and text evidence;
- operation with no required environment variables;
- API per-IP rate limiting and first-hop forwarded-IP behavior;
- UK hosting, retention until deletion, and audit-entry retention on `/privacy`;
- “Workspace keys are stored on this device.”

The claims contract explicitly makes any unlisted claim a failing review.

### High — the available TypeScript check fails

`npx tsc --noEmit` exits 2. It reports missing Node types for `node:fs` and
`Buffer`, plus incompatible Playwright `Page` types in the axe calls. The lock
contains Playwright core 1.58.2 through `@playwright/test` and 1.62.1 through
`@axe-core/playwright`. There is no `typecheck` script to expose this in
`npm test`.

## Other defects

### Medium

1. **CSV import is not atomic.** A two-row import with a valid first row and an
   invalid second row returned HTTP 400, but a later read showed one saved row.
   Retrying can duplicate data after an apparent failure.
2. **Calendar dates are not validated at the API edge.** A record dated
   `2026-99-99` was accepted with HTTP 201. The server checks only string shape.
3. **Legal-page text fails WCAG AA contrast.** Axe reports one serious
   `color-contrast` violation on both `/privacy` and `/terms`: `.eyebrow` uses
   `#e8bf62` on `#f4efe2`, ratio 1.51:1 at 12.64 px; 4.5:1 is required.
4. **Mobile link targets are too small.** At 390 px, header links measure about
   39–47 by 25 px and footer links about 37–155 by 17–24 px. The product
   contract requires at least 44 by 44 CSS px.
5. **The Dockerfile violates the mandatory toolchain contract.** It uses
   `FROM rust:1.88-bookworm`; the contract requires an unpinned stable tag such
   as `rust:1-slim`. Docker and Podman were unavailable in this verifier image,
   so the container itself could not be built here.

### Low

- Unknown SPA routes render the designed not-found view but return HTTP 200,
  creating a soft 404.
- The server gives one-year `immutable` caching to unversioned hero and font
  paths as well as hashed bundles. Replacing those files at the same paths can
  leave returning clients stale.

## Mandatory first-read and demo gate

The cold landing screen itself passes the plain-words test:

- **What it does:** “Link each expense to evidence.”
- **For whom:** sole traders preparing a reviewable MTD quarterly record.
- **What to click first:** “Try it with sample data,” followed by “See a ready
  quarter. Nothing is saved.”

The action is visible on the first desktop and 390 px screens. However, the
one-click demo gate fails in production because all 12 fresh-context samples in
the final run showed the workspace-not-found error described above.

## Claims gate

After the locked dependency install, every exact command in
`.factory/claims.json` passed against the local demo entry point:

| Claim | Result | Observable assertion |
| --- | --- | --- |
| `demo-isolation` | PASS | Separate `demo:` session key, 24-hour response, reset changes key |
| `no-account` | PASS | `/app` creates a private key without credentials |
| `csv-matching` | PASS | One amount/date match skipped; one new row imported |
| `evidence-pack` | PASS | ZIP signature plus CSV and evidence entries |
| `free-limit` | PASS test / **false live behavior** | UI stops save 26; public API accepts 26 |
| `no-trackers` | PASS | Local demo core flow uses only same-origin requests |
| `license-return` | PASS fixture only | Stubbed valid verification is cached and URL token removed |

The claim tests are too narrow to catch the distributed deployment and
server-side paid-limit failures.

## Local install, test, type, and build results

| Command | Result |
| --- | --- |
| `npm ci` | PASS; 34 packages audited, 0 vulnerabilities |
| Seven exact claim commands | PASS after install |
| `npm test` | PASS; 2 Rust tests and 9 Chromium tests |
| `cargo fmt --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npx tsc --noEmit` | **FAIL**, diagnostics described above |
| `npm audit --audit-level=low` | PASS; 0 vulnerabilities |
| `npm run build` | PASS; creates `dist/` |
| Release binary with only `PORT=8091` in a scrubbed environment | PASS; `/health` returned `{"build_sha":"dev","status":"ok"}` |
| Docker build | Not run; neither Docker nor Podman is installed |

## Functional checks

When a demo request reached the same replica, the smallest useful flow worked:

- six realistic records and two missing-evidence items loaded;
- `£0.01`, a 120-character description, a 40-character category, and a quarter
  boundary date saved successfully;
- zero amount showed “Enter an amount greater than zero,” then recovered;
- unsupported evidence showed a clear error, and a text receipt then linked;
- malformed CSV showed a heading error, then a valid CSV skipped one likely
  match and imported one new row;
- export downloaded a correctly named ZIP with `PK`, `transactions.csv`, and
  linked evidence entries;
- Reset demo changed the `demo:` key and never created a private local key;
- an invalid live licence was rejected and removed from browser storage.

The partial-import and invalid-calendar-date failures are documented above.

## Accessibility and responsive behavior

- `verify-url.sh`: PASS on `/`; title, `en-GB`, one `h1`, `main`, alt text, and
  labelled buttons present; no cold-load console errors.
- Axe serious/critical: none on `/`, `/demo`, `/app`, or the not-found view;
  one serious contrast violation on each legal route.
- Keyboard: skip link is first, with a 3 px brass focus outline and dark halo;
  Enter opens the demo and transaction dialog; Escape closes the native dialog
  and restores focus to “Add a transaction.”
- Reduced motion: animation `none`, transition `0s`, scroll behavior `auto`.
- 390 px: no horizontal overflow; headline and sample action visible. Several
  navigation/footer targets fail the 44 px minimum.

## Privacy, network, and headers

- The successful core demo flow made no cross-origin requests.
- Restoring an invalid licence made the documented request only to
  `api.sociobot.in`.
- Cold page load had no console or page errors. The intentional unsupported-file
  test generated the expected browser resource error for HTTP 415.
- Browser and curl responses include CSP, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive
  `Permissions-Policy`.
- HTML and API responses use `Cache-Control: no-cache`; static assets use
  `public, max-age=31536000, immutable`.
- The live invalid-licence verify response was 200 with
  `{valid:false, reason:"invalid"}` and `Cache-Control: no-store`.

## Rate limits, concurrency, persistence, and identity

- Product API: a fixed forwarded-IP batch of 160 requests returned 144 normal
  401 responses and 16 HTTP 429 responses, all with `Retry-After: 1`. The code
  configures burst 40 per process, but multiple replicas multiply the observed
  allowance and do not share limiter state.
- Sociobot licence verification: 100 simultaneous invalid checks returned 30
  HTTP 200 and 70 HTTP 429 responses with `Retry-After: 4`.
- Health: 100 simultaneous requests all returned 200.
- Persistence: failed in production as described in the critical blocker.
- Identity: `/health` returned the exact candidate SHA. Local/live hashes match:
  `index.html` `cad4101f…`, JS `c8adeadc…`, CSS `eaf33328…`.

## Performance and bundle budgets

Fresh mobile Lighthouse evidence is in
`evidence/verification-1/lighthouse.json`:

- Performance 99, accessibility 100, best practices 100, SEO 100 on `/`;
- FCP 1.1 s, LCP 1.9 s, speed index 1.1 s, TBT 10 ms, CLS 0;
- total transferred size 176 KiB.

Production assets stay inside their budgets:

- JS 30,026 bytes raw / 10,276 bytes gzip;
- CSS 16,325 bytes raw / 4,687 bytes gzip;
- fonts 102,036 bytes total;
- mobile hero 61,374 bytes; desktop hero 173,422 bytes.

This is not presented as a PWA and ships no service worker, so offline/update
testing is not applicable. It is not a library or CLI. Sign-in is not required,
so the Entra authority check is not applicable.

## Required remediation before another candidate

1. Use one shared durable database, or constrain the deployment to one durable
   instance with proven storage and recovery; then rerun demo and persistence
   checks across restarts/replicas.
2. Register and verify the live Sociobot billing product. Enforce paid limits
   server-side using verified licence/entitlement state.
3. Make imports transactional and validate actual calendar dates at the API
   boundary.
4. Fix TypeScript dependencies/types and add the check to the normal test gate.
5. Complete claims coverage, fix the legal-page contrast and touch targets, and
   use the required stable Rust Docker base.
