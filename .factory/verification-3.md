# Independent product verification 3 — FAIL

Verified on 29 August 2026 for work order
`mtd-evidence-rail-verify-3`.

- Candidate: `d9774c5d70af912a520d2f349b4b10960ffd7e47`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — do not release**

The candidate passes its clean local build, declared claims, and local product
flow. The exact candidate is live. Production nevertheless has three replicas,
no durable volume, and separate local SQLite files. Once the app scaled out,
the mandatory one-click demo failed in 12 of 12 fresh browsers and 14 of 15
applicable live Playwright tests failed. This is fresh evidence, not the prior
verifier's result.

## Release blockers

### Critical — live state is split across three ephemeral replicas

The repair described in the previous handoff is not present in the deployed
container-app configuration.

Fresh Azure control-plane evidence:

- image: `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:d9774c5d70af`;
- revision: `sf-mtd-evidence-rail--0000015`, healthy and active;
- replicas: **3**, state `RunningAtMaxScale`;
- `minReplicas: 1`, `maxReplicas: 3`;
- container environment: only `PORT=8080`;
- volume mounts: `null`; volumes: `null`; `SQLITE_VFS` absent.

`scripts/verify-live-topology.sh` failed immediately with:

```text
Unsafe topology: mode=Single max=3 mount= vfs= active=1
```

The data-plane failure was then reproduced:

- An initial low-load probe happened to return 100/100 reads for each of a new
  private and demo key, and a 12-context demo smoke initially passed. This is
  not durable or shared-state evidence; requests were still reaching one
  process at that point.
- A 600-request concurrency probe caused the deployment to run at its configured
  three replicas.
- The applicable live Playwright suite then passed **1/15**. Every app-flow test
  failed because a successful workspace creation was followed by
  `GET /api/workspace` returning 404.
- A fresh follow-up using 12 separately launched Chromium browsers loaded the
  sample in **0/12**. Every run recorded `POST /api/demo` = 201 followed by
  `GET /api/workspace` = 404 and displayed “The quarter could not load. This
  workspace was not found. Start a new workspace.”
- Fresh `/app` contexts failed the same way. Buttons remain disabled, so users
  cannot add, import, review, export, or delete reliably.

The service's default `DATA_DIR` is `/data`, but `/data` is not mounted. Each
replica therefore writes to its own disposable filesystem. State is neither
shared across replicas nor durable across replacement/restart. A live restart
was not initiated because verification did not authorize a production
mutation; the missing mount already makes that persistence boundary fail.

This breaks the real job-to-be-done and falsifies the live demo-isolation,
durable-storage, shared-state, deletion, and “stays available until you delete
it” promises. Evidence:

- [fresh 12-browser demo results](evidence/verification-3/live-demo-repeat.json)
- [live failed demo screenshot](evidence/verification-3/live-demo-state.png)
- [live network, console, route, Axe, keyboard, and motion audit](evidence/verification-3/live-browser-audit.json)

### High — absolute visitor claims are not represented by exact claim tests

The claims manifest is much improved and every listed command passes locally,
but the live page and README still make claim-like statements that are not the
claim text of an exact sandbox test:

- “Paid access includes unlimited transactions across your quarters.” The
  `paid-limit` test proves only that 26 records can be accepted with a recorded
  valid verdict; it cannot prove an unlimited promise.
- The README and privacy page call the workspace key “unguessable.” The
  `no-account` test proves its format and browser location, not that security
  property.

The claims contract says unlisted claims fail review. Replace absolute wording
with a defined, tested limit/property or add an observable claim test.

## Other defects

### Medium — several mobile touch targets are below 44 px

At a 390 px viewport, the inline **terms** link on the landing page measured
37×17 px. The privacy and support email links measured 137×20 px and 143×20 px.
The attached accessibility contract requires every touch target to be at least
44×44 CSS px. Header, footer, primary actions, and app controls otherwise met
the target size requirement.

### Low — some headings use the railway metaphor instead of plain section names

“Three stops,” “Keep every quarter on the rail,” and the 404 eyebrow “The rail
ends here” conflict with the attached plain-words rule against metaphor and
brand-lore copy. The mandatory first screen itself is direct and passes.

## Mandatory first-read and demo gate

The cold landing screen answers all three questions in plain words:

- **What it does:** “Link each expense to evidence.”
- **For whom:** sole traders who need a reviewable record before each MTD
  quarterly update.
- **What to click first:** “Try it with sample data,” followed by “See a ready
  quarter. Nothing is saved.”

The action is above the fold at desktop and 390 px. The candidate nevertheless
**fails the mandatory gate** because the click led to the workspace-not-found
state in 12/12 final fresh-browser runs.

## Candidate and deployment identity

- Local `HEAD` was exactly `d9774c5d70af912a520d2f349b4b10960ffd7e47`.
- Live `/health` returned status 200 and that exact full SHA.
- 100 concurrent health requests all returned 200 and the same SHA.
- Local and live SHA-256 hashes matched exactly:
  - `index.html`: `bab6b140aa866034e4f29f1491a514f3527cc1fa04849108ff840d75067b52f8`
  - JS: `13e452d66c24410a9f67c58db7e6f802dc7931ff66b4908a48ff4e0fd80a1eca`
  - CSS: `f9ec521bcef0856eed144a41a4b8f3b13cd55fc74fa2a5ce462164e415b4ab78`

The live failure therefore belongs to this candidate's deployment, not stale
frontend or backend code.

## Claims gate

`.factory/claims.json` exists with 19 entries. The mandated pre-install
invocation was performed first: the two dependency-free checks passed, while
17 JavaScript-backed commands could not start because a clean clone does not
contain `node_modules` (`tsc`/`vite` not found). After the required locked
install (`npm ci`), every command was rerun exactly as listed and all 19 exited
0. A final independent repetition from a detached, clean worktree at the exact
candidate also finished `total=19 failures=0`:

| Claim | Local result | Observable evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | `demo:` session key, no private key, 24-hour expiry, reset |
| `no-account` | PASS | Private key created without credentials |
| `quarter-capture` | PASS | Income and expense in the dated quarter |
| `csv-matching` | PASS | One likely match skipped and one new row imported |
| `atomic-import` | PASS | Invalid batch returned 400 and saved no rows |
| `calendar-dates` | PASS | Impossible date returned 400 |
| `evidence-types` | PASS | PDF/JPG/PNG/WebP/text and exact 5 MiB boundary |
| `missing-review` | PASS | Exactly two missing records shown |
| `evidence-pack` | PASS | ZIP signature, transaction CSV, and evidence entries |
| `workspace-delete` | PASS | Deleted key returned 404 |
| `free-limit` | PASS | 26th unlicensed record returned 402 |
| `paid-limit` | PASS | Recorded valid verdict allowed 26 records |
| `hosted-checkout` | PASS | Live endpoint returned 303 to hosted Dodo checkout |
| `license-return` | PASS | Token stored, checked, and removed from URL |
| `no-trackers` | PASS | Local core flow used same-origin requests only |
| `runtime-defaults` | PASS | Service started with only `PORT` |
| `durable-storage` | PASS locally / **FAIL live** | Local restart passed; live mount is absent |
| `shared-state-boundary` | PASS locally / **FAIL live** | Three local processes shared one store; three live replicas do not |
| `api-rate-limit` | PASS | Unit test returned 429 with `Retry-After: 1` |

The pre-install failures were missing-tool failures rather than failed product
assertions, but they are recorded here because the work order required the
claims list to run before any other action. The post-install result is the
valid source-candidate claims result. Passing it does not override the direct
live contradiction.

## Install, tests, type/lint, and production build

| Command | Result |
| --- | --- |
| `npm ci` | PASS; 34 packages, 0 vulnerabilities |
| All 19 exact claim commands | PASS after locked install |
| `npm test` | PASS; typecheck, Vite build, 4 Rust tests, 3 runtime/persistence checks, 17 Chromium tests |
| `npm audit --audit-level=low` | PASS; 0 vulnerabilities |
| `cargo fmt --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| final `npm run build` | PASS; produced `dist/` |

Docker and Podman were unavailable, so a second local container image build was
not possible. The live ACR image is tagged with the candidate and its health
identity and static hashes match the local production outputs. Dockerfile
inspection passes: Node/Rust stages, `rust:1-slim`, `ARG BUILD_SHA=dev`,
non-root runtime user, `PORT=8080`, and no `.git` dependency.

## Independent functional and recovery checks

Against a fresh local release server:

- the demo opened with six realistic records and two missing-evidence items;
- the missing-evidence filter showed only the two expected rows;
- zero produced “Enter an amount greater than zero,” then £0.01 saved;
- a 120-character description and 40-character category saved;
- £1,000,000 and dates on 5/6 July quarter boundaries saved;
- zero, negative, over-limit amounts, 30 February, an unknown kind, 121-char
  description, 41-char category, and malformed JSON were rejected;
- an unsupported evidence file produced a useful error, then a text receipt
  linked successfully;
- malformed CSV headings produced a corrective error, then a corrected bank
  CSV imported and rendered;
- the evidence pack downloaded with the expected name, `PK` signature,
  `transactions.csv`, and evidence entries;
- Reset demo changed the `demo:` key, restored six sample rows, and never
  created a private local-storage key;
- deleting a private workspace cleared the browser key and the API then
  returned 404.

Evidence: [functional audit](evidence/verification-3/local-functional-audit.json)
and [CSV recovery follow-up](evidence/verification-3/local-csv-recovery.json).

## Accessibility, responsive behavior, and motion

- Factory `verify-url.sh` passed the landing page: title, `en-GB`, one `h1`,
  `main`, image alternatives, labelled buttons, and no cold-load console error.
- Fresh Axe runs found no serious or critical findings on `/`, `/demo`, `/app`,
  `/privacy`, `/terms`, or the real 404 page, including the live error state.
- Keyboard: the first Tab focuses “Skip to main content”; Enter moves to
  `#main`. Focus is a visible 3 px brass outline with a 5 px dark halo.
- Reduced motion: media query matched, train animation was `none`, transition
  duration `0s`, and scroll behavior `auto`.
- At 390 px there was no normal horizontal overflow; the headline and sample
  action were fully visible above the fold. The sample action was 366×54.8 px.
- At 200% root text size, all content and the primary action remained present;
  document width was 394 px in a 390 px viewport (4 px horizontal overflow).
- The undersized inline targets are reported above.

## Privacy, requests, headers, routes, and caching

- Cold landing requests were same-origin only: HTML, hashed JS/CSS, three local
  fonts, and the product hero. No tracker or third-party script ran.
- The demo attempt also made only same-origin requests; its API GET returned
  404 because of the deployment topology and produced the expected browser
  resource error.
- A returned invalid licence made the documented request only to
  `api.sociobot.in`; it returned 200 with `Cache-Control: no-store`, the token
  was stripped from the URL, free limits stayed active, and the quiet inactive
  notice appeared.
- HTML and API responses send CSP, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive
  `Permissions-Policy`. `frame-ancestors 'none'` is in the response header.
- HTML/API responses use `no-cache`; hashed JS/CSS use one-year immutable
  caching; unversioned fonts/art use one-hour revalidation.
- `/`, `/demo`, `/app`, `/privacy`, `/terms`, robots, sitemap, icons, external
  Sociobot, and checkout resolved as expected. An unknown route returned the
  designed page with HTTP 404. Mail links used valid `mailto:` schemes.

## Rate limits and concurrency

- Local source claim: the 41st burst request is rejected with 429 and
  `Retry-After: 1`.
- Live product API: a single forwarded client sent 600 concurrent requests in
  2.259 seconds. 191 were processed as normal unauthenticated 401 responses and
  409 returned 429; every 429 had `Retry-After: 1`. The effective allowance is
  inflated by three independent per-replica limiters.
- Sociobot licence verification: a 100-request probe returned 31 HTTP 200 and
  69 HTTP 429 responses with `Retry-After` values from 0 to 4 seconds. A later
  120-request burst returned 3 HTTP 200 and 117 HTTP 429 responses, all with a
  `Retry-After` header.
- 100 concurrent product health checks returned 100 HTTP 200 responses and the
  candidate SHA.

Rate limiting exists, but it does not repair the state boundary and is itself
multiplied across the three product replicas.

## Performance and budgets

Fresh mobile Lighthouse evidence:

- performance 99, accessibility 100, best practices 100, SEO 100;
- FCP 1.08 s, LCP 1.905 s, speed index 1.08 s, TBT 5 ms, CLS 0;
- total transfer 180,628 bytes.

Production assets are within budget:

- JS 30,079 bytes raw / 10,262 bytes gzip;
- CSS 16,617 bytes raw / 4,729 bytes gzip;
- fonts 102,036 bytes total;
- mobile hero 61,374 bytes; desktop hero 173,422 bytes.

Evidence: [Lighthouse JSON](evidence/verification-3/lighthouse.json).

This is not a PWA and makes no offline claim, so service-worker update/offline
checks do not apply. It is not a library or CLI. It requires no sign-in, so the
Sociobot Entra authority check does not apply.

## Required remediation

1. Deploy this candidate through `scripts/deploy.sh`, or otherwise restore
   Azure Files at `/data`, `SQLITE_VFS=unix-dotfile`, and `maxReplicas: 1`.
2. Make the generic/final factory rollout preserve that topology. A code-level
   post-deploy script is insufficient if a later deployment step overwrites it.
3. Before release, require control-plane checks plus 100/100 private/demo reads,
   12/12 fresh browsers, a real revision restart, and the full live suite after
   load has brought the app to its maximum configured replica count.
4. Replace or exactly test the absolute “unlimited” and “unguessable” claims.
5. Enlarge the three inline mobile links to 44×44 px and replace metaphor-only
   section labels with task names.

No product code was modified during verification.
