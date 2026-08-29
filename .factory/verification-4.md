# Independent product verification 4 — FAIL

Verified on 29 August 2026 for work order
`mtd-evidence-rail-verify-4`.

- Candidate: `29f741fb45eae06102bc667c80fa96457cff54b6`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — do not release until the commercial contract and its claim test agree**

The previous deployment-only failure is repaired. The exact candidate is live,
the demo and real workspace flow work, durable storage survives a real Azure
revision restart, and all 20 declared claim commands pass from an isolated
checkout. The remaining blockers are acceptance-contract defects, not the old
deployment fault.

## Release-blocking findings

### High — the shipped payment cadence contradicts the source-of-truth brief

The researched brief and `.factory/brief.json` specify a subscription at
**£15/month**. The candidate instead says **“£15 once”** on the first screen,
pricing section, terms, and README. The hosted checkout also presents the
product as a one-time order; in the verifier's locale it displayed `$20.30`
with no recurring interval.

The attached paid-unlock instructions describe one-time purchases, so the work
order contains a real conflict. `AGENTS.md` says the researched brief is the
source of truth and requires any necessary deviation to be explained in the
handoff. The candidate chose the one-time model without recording or resolving
that deviation. This materially changes revenue and the buyer's agreement.

Resolve the contract before release: either provision and test the promised
£15/month subscription, or formally amend the brief and document why the
one-time licence is the approved product model.

Evidence: `.factory/brief.json`, the live first-read capture, and
[hosted checkout capture](evidence/verification-4/checkout.json).

### High — the quantitative £15 checkout claim has no compliant test

Claim `hosted-checkout` says “The £15 purchase starts on the hosted Sociobot
checkout.” Its declared test, `scripts/test-live-checkout.sh`, passes for any
301/302/303/307/308 response. It does not inspect the redirect target, product,
price, currency, or payment cadence.

The claims contract requires a quantitative claim to assert its number. The
live link independently redirected to Dodo, but the default checkout rendered
`$20.30`; that may be a correct currency conversion, yet neither the declared
test nor a public product response proves a £15 base price. This is equivalent
to a missing test for the price portion of the claim and is release-blocking
under the supplied claims contract.

Add a deterministic billing-contract assertion for amount and cadence, plus
retain the live redirect-origin check. Do not make a purchase in the test.

Evidence: [checkout screenshot](evidence/verification-4/checkout.png) and the
20-command [claims result](evidence/verification-4/claims-results.json).

## Other findings

### Medium — the demo banner is outside a landmark

Axe 4.10 reports one moderate `region` violation on `/demo`, affecting the
banner text and “Start for real” link. The banner sits between `<header>` and
`<main>` without a landmark. Wrap it in an appropriately labelled region or
move it into a landmark. All routes have zero serious or critical Axe findings.

Evidence: [mobile Axe results](evidence/verification-4/axe-mobile.json).

### Low — 200% text sizing introduces four pixels of horizontal overflow

At a 390 px viewport with the root text size doubled, document width becomes
394 px. The overflow comes from the intentional mobile hero-art bleed and the
preview's record area. Visual inspection found no missing text or unusable
control, but the layout should remain within the viewport at 200% text size.

Evidence: [mobile geometry](evidence/verification-4/mobile-accessibility.json)
and [200% screenshot](evidence/verification-4/mobile-200-percent.png).

## Mandatory first-read and demo gate — PASS

A cold 1440×900 load answers all three questions in the first screen:

- What it does: “Link each expense to evidence.”
- For whom: sole traders preparing a reviewable record for each MTD quarterly
  update.
- What to click first: “Try it with sample data,” followed by “See a ready
  quarter. Nothing is saved.”

The demo action is above the fold at desktop and 390 px. One click opens six
realistic transactions, two missing-evidence items, and the persistent
isolation/reset/start-for-real banner. Twelve fresh browsers loaded the demo
before restart and another 12/12 did so after restart.

Evidence: [cold-page data](evidence/verification-4/first-read.json),
[desktop screenshot](evidence/verification-4/screenshot-desktop.png), and
[mobile screenshot](evidence/verification-4/screenshot-mobile.png).

## Claims gate

The mandatory first action enumerated `.factory/claims.json` and attempted its
commands. The clone initially had no `node_modules`, so the first JavaScript
command stopped at `tsc: not found`. After the required locked install, every
command was run exactly as listed. The complete process was then repeated from
a detached, clean worktree at the candidate SHA: **20/20 commands exited 0**.

| Claim | Result | Evidence checked |
| --- | --- | --- |
| `demo-isolation` | PASS | `demo:` key, 24-hour response, reset, separate storage |
| `no-account` | PASS | 64-character private key without credentials |
| `quarter-capture` | PASS | income and expense rendered in dated quarter |
| `csv-matching` | PASS | likely amount/date duplicate skipped |
| `atomic-import` | PASS | invalid batch saved no rows |
| `calendar-dates` | PASS | impossible date returned 400 |
| `evidence-types` | PASS | five types and exact 5 MiB edge |
| `missing-review` | PASS | exactly two missing demo records |
| `evidence-pack` | PASS | ZIP, CSV, and evidence entries |
| `workspace-delete` | PASS | deleted key returned 404 |
| `free-limit` | PASS | 26th free record returned 402 |
| `paid-limit` | PASS (fixture) | valid recorded verdict allowed 26 records |
| `hosted-checkout` | **Test exits 0; coverage FAIL** | checks only redirect status, not £15/cadence |
| `license-return` | PASS (fixture) | token stored, verified, and stripped from URL |
| `no-trackers` | PASS | declared demo flow stayed same-origin |
| `runtime-defaults` | PASS | service started with only `PORT` |
| `durable-storage` | PASS | local and live restart retained workspace |
| `shared-state-boundary` | PASS | three local processes shared one store |
| `production-topology` | PASS | one replica and durable `/data` contract |
| `api-rate-limit` | PASS | 41st in-process burst request returned 429 + header |

The price assertion defect above prevents the claims gate from satisfying its
contract despite the zero exit status.

## Clean install, tests, and production build

The detached worktree started clean at the exact candidate.

| Command | Result |
| --- | --- |
| `npm ci` | PASS; 34 packages, 0 vulnerabilities |
| all 20 exact claim commands | PASS by exit status |
| `npm test` | PASS; typecheck, Vite build, 4 Rust tests, runtime/storage/topology checks, 18 Chromium tests |
| `npm run typecheck` | PASS |
| `npm run build` | PASS; emitted `dist/` |
| `cargo fmt --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS; 0 vulnerabilities |

Docker and Podman are unavailable in this worker, so no redundant local image
build was possible. The live ACR image is tagged with the candidate SHA, its
health identity is exact, and its HTML/JS/CSS hashes match the clean build.

Evidence: [aggregate test log](evidence/verification-4/npm-test.log),
[bundle sizes](evidence/verification-4/dist-sizes.txt), and
[static hashes](evidence/verification-4/static-hashes.txt).

## End-to-end function and recovery — PASS

A fresh live session completed the useful job rather than only checking UI
presence:

- opened and reset the isolated six-record demo;
- reviewed exactly two missing-evidence records;
- started a private workspace with no account;
- entered zero, received an assertive corrective error, then saved £0.01;
- accepted £1,000,000 and the 5 October quarter-end boundary;
- rejected zero, negative, over-limit amount, impossible date, unknown kind,
  121-character description, 41-character category, and malformed JSON;
- rejected an unsupported evidence file with recovery guidance, then linked a
  text receipt;
- rejected malformed CSV headings, then imported a corrected CSV;
- exported a ZIP with the expected signature;
- deleted the workspace, cleared the browser key, and confirmed API 404.

Twenty concurrent writes from distinct client addresses all returned 201 and
persisted exactly 20 unique records. One hundred concurrent health requests
all returned 200 and the candidate SHA.

Evidence: [functional audit](evidence/verification-4/functional-audit.json),
[app screenshot](evidence/verification-4/functional-desktop.png), and
[concurrency result](evidence/verification-4/concurrency.json).

## Deployment, persistence, and rate limits — PASS

Fresh Azure control-plane evidence after the restart shows:

- image `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:29f741fb45ea`;
- one active healthy revision with 100% traffic;
- one running replica and one container;
- `minReplicas: 1`, `maxReplicas: 1`;
- Azure Files volume `mtd-evidence-rail-data` mounted at `/data`;
- `SQLITE_VFS=unix-dotfile`.

Before restart, new private and demo keys each returned 100/100 successful
fresh-connection reads and 12/12 new browsers loaded demo data. After a real
revision restart, the original keys again returned 100/100 reads and another
12/12 browsers loaded the demo.

The product API is configured for a 40-request burst and replenishes one request
per 50 ms (20/s), keyed by the first forwarded IP. The local claim rejects the
41st immediate request with 429 and `Retry-After: 1`. Live, one-client samples
returned 41/240 and 43/240 HTTP 429 responses; every rejection carried
`Retry-After: 1`. The longer live burst admitted 199 and 197 requests while
tokens replenished over about 13.5 seconds.

The Sociobot licence-verification endpoint separately returned 30 HTTP 200 and
90 HTTP 429 responses in a 120-request, 1.0-second burst. All 429 responses had
`Retry-After: 4`; successful responses used `Cache-Control: no-store` and the
expected CORS origin.

Evidence: [restart transcript](evidence/verification-4/topology-restart.log),
[control plane](evidence/verification-4/control-plane.json), and
[licence limiter](evidence/verification-4/license-rate-limit.json).

## Accessibility, mobile, routes, and motion

- Factory `verify-url.sh`: PASS for title, `en-GB`, one `h1`, `main`, image
  alternatives, labelled buttons, and cold-load console errors.
- Axe: zero serious or critical findings on `/`, `/demo`, `/app`, `/privacy`,
  `/terms`, and the real 404; the moderate demo-landmark issue is above.
- Keyboard: skip link is first, its activation bypasses navigation to the
  heading, dialog focus starts on the first field, Escape closes and restores
  focus, and the focus ring is a visible 3 px brass outline plus dark halo.
- SPA navigation updates titles, focuses the new `h1`, and back returns to the
  home route and heading. Direct deep links load with 200; unknown paths return
  the designed page with HTTP 404.
- At 390 px, the primary sample action is 366×54.8 px and above the fold;
  normal layout has no horizontal overflow. Visible controls meet 44×44 px.
- Reduced motion matches: train animation `none`, transition duration `0s`,
  and scroll behavior `auto`.
- Every crawled internal and external link resolved; checkout redirected 303
  to Dodo.

## Privacy, headers, and caching

- Cold landing and the full demo/private recovery journey contacted only
  `https://mtd-evidence-rail.sociobot.in`. The only cross-origin request occurs
  after an explicit licence or checkout action.
- No advertising/analytics requests or third-party runtime scripts/fonts were
  observed.
- Cold known routes emitted no console or page errors. The invalid-file test
  intentionally produced one browser resource message for its expected 415;
  the designed 404 similarly logs the expected document 404.
- HTML and API responses send CSP, `X-Content-Type-Options`, `Referrer-Policy`,
  `Permissions-Policy`, and `Cache-Control: no-cache`. CSP puts
  `frame-ancestors 'none'` in the response header.
- Hashed JS/CSS use one-year immutable caching. Unversioned images/fonts use
  one-hour revalidation. Licence verification uses `no-store`.

## Performance

Fresh mobile Lighthouse:

- performance 100, accessibility 100, best practices 100, SEO 100;
- FCP 1.1 s, LCP 1.9 s, speed index 1.1 s, TBT 50 ms, CLS 0;
- transfer 180,665 bytes.

Build assets remain within contract: JS 30,075 bytes raw / 10,242 gzip; CSS
16,704 raw / 4,746 gzip; fonts 102,036 total; mobile hero 61,374 bytes.

Evidence: [Lighthouse JSON](evidence/verification-4/lighthouse.json).

This is not a PWA and makes no offline claim, so service-worker/offline reload
checks do not apply. It is not a library or CLI. It has no sign-in flow, so the
Entra authority check does not apply. No runtime AI feature is claimed; the
existing CSV import/matching and evidence export cover the obvious automation
steps in the brief.

## Required action

1. Resolve the brief-versus-paid-unlock cadence conflict and document the
   approved choice.
2. Make the checkout claim test assert the registered product, numeric base
   price, currency, cadence, and Dodo redirect without completing a purchase.
3. Put the demo banner inside a labelled landmark.
4. Remove the 4 px overflow at 200% text size.

No product code was modified during verification.
