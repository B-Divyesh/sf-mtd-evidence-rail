# Independent product verification 21 — PASS

**Candidate:** `693a7609d2efb23c6567da5de0b425db92029e5c`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Work order:** `mtd-evidence-rail-verify-21`

**Verified:** 2 September 2026 UTC

**Verdict:** **PASS — release accepted.**

No critical, high, medium, or low product defect was found. The prior
deployment-only failure does not reproduce: the live health response, ready
image, revision, storage topology, persistence probes, and rate-limit probes
all pass for this exact candidate.

## Mandatory first read and demo gate — PASS

A cold 1440×900 load answers the required questions without scrolling:

- what it does: **“Link each expense to evidence”**;
- who it is for: **UK sole traders, tutors, and small club operators preparing
  an MTD quarterly update**; and
- what to click first: **“Try it with sample data.”**

The adjacent text says the click opens a ready quarter in a 24-hour demo. One
click opens six realistic transactions with two missing items. The persistent
banner says that nothing is saved to the private workspace and offers **Reset
demo** and **Start a private workspace**. At 390×844 the headline, audience,
demo action, real-workspace actions, and three plain facts remain in the first
viewport.

Evidence: [cold desktop](evidence/verification-21/root/screenshot-desktop.png),
[cold mobile](evidence/verification-21/root/screenshot-mobile.png), and
[live demo mobile](evidence/verification-21/live-mobile-demo.png).

## Claims gate — 26/26 PASS

`.factory/claims.json` exists with 26 unique claim ids, each with exactly one
matching `@claim:<id>` test. I cloned the repository to a separate directory,
checked out the candidate detached, confirmed an empty porcelain status, ran
`npm ci`, and executed every listed `test` command literally and serially.

| # | Claim | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | `demo-isolation` | PASS | [log](evidence/verification-21/claims/01.log) |
| 2 | `no-account` | PASS | [log](evidence/verification-21/claims/02.log) |
| 3 | `workspace-key-recovery` | PASS | [log](evidence/verification-21/claims/03.log) |
| 4 | `workspace-key-auth` | PASS | [log](evidence/verification-21/claims/04.log) |
| 5 | `quarter-capture` | PASS | [log](evidence/verification-21/claims/05.log) |
| 6 | `csv-matching` | PASS | [log](evidence/verification-21/claims/06.log) |
| 7 | `atomic-import` | PASS | [log](evidence/verification-21/claims/07.log) |
| 8 | `calendar-dates` | PASS | [log](evidence/verification-21/claims/08.log) |
| 9 | `evidence-types` | PASS | [log](evidence/verification-21/claims/09.log) |
| 10 | `missing-review` | PASS | [log](evidence/verification-21/claims/10.log) |
| 11 | `demo-sample` | PASS | [log](evidence/verification-21/claims/11.log) |
| 12 | `evidence-pack` | PASS | [log](evidence/verification-21/claims/12.log) |
| 13 | `workspace-delete` | PASS | [log](evidence/verification-21/claims/13.log) |
| 14 | `free-limit` | PASS | [log](evidence/verification-21/claims/14.log) |
| 15 | `paid-limit` | PASS | [log](evidence/verification-21/claims/15.log) |
| 16 | `hosted-checkout` | PASS | [log](evidence/verification-21/claims/16.log) |
| 17 | `license-return` | PASS | [log](evidence/verification-21/claims/17.log) |
| 18 | `no-trackers` | PASS | [log](evidence/verification-21/claims/18.log) |
| 19 | `runtime-defaults` | PASS | [log](evidence/verification-21/claims/19.log) |
| 20 | `durable-storage` | PASS | [log](evidence/verification-21/claims/20.log) |
| 21 | `shared-state-boundary` | PASS | [log](evidence/verification-21/claims/21.log) |
| 22 | `production-topology` | PASS | [log](evidence/verification-21/claims/22.log) |
| 23 | `live-workspace-consistency` | PASS | [log](evidence/verification-21/claims/23.log) |
| 24 | `live-release-identity` | PASS | [log](evidence/verification-21/claims/24.log) |
| 25 | `api-rate-limit` | PASS | [log](evidence/verification-21/claims/25.log) |
| 26 | `live-api-rate-limit` | PASS | [log](evidence/verification-21/claims/26.log) |

The checkout claim observed HTTP 303 to Dodo product
`pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly subscription cadence. No payment
was completed. Landing and README statements map to the claims list; no
unlisted reliance claim was found.

## Clean-checkout quality gates — PASS

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — 9 Rust tests and 25 Chromium tests |
| `npm run lint` | PASS — TypeScript, rustfmt, Clippy `-D warnings` |
| `npm run build` | PASS — `dist/` produced |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=high` | PASS — 0 vulnerabilities |

Evidence: [full test](evidence/verification-21/local/npm-test.log),
[lint](evidence/verification-21/local/lint.log),
[frontend build](evidence/verification-21/local/build.log),
[release build](evidence/verification-21/local/release-build.log), and
[audit](evidence/verification-21/local/npm-audit.log).

Docker and Podman are unavailable in this verifier container, so local image
assembly was not possible. The exact Docker build payloads passed, the
Dockerfile is multi-stage and non-root with `ARG BUILD_SHA=dev`, and the live
ACR image passed source identity and runtime checks.

## Independent end-to-end exercise — PASS

On a fresh live demo I:

- saw six transactions and two missing-evidence items;
- rejected £0 with “Enter an amount greater than zero,” then saved £0.01;
- received the specific missing-heading error for an invalid CSV;
- reviewed a valid two-row CSV, skipped one amount-and-date match, and imported
  one new row;
- rejected a 5 MB + 1 byte file, then linked a valid text evidence file; and
- downloaded `evidence-pack-2026-27-Q1.zip`, whose `PK` signature and entries
  include `transactions.csv` and linked evidence.

The flow produced no console or page errors. A separate invalid API request
rejected `2026-99-99` with HTTP 400 and “Enter a real calendar date”; a valid
request immediately afterward returned 201.

Thirty simultaneous writes into a fresh free workspace produced exactly 25
HTTP 201 responses and five HTTP 402 limit responses. The store contained 25
unique records. Workspace deletion returned 204, and the deleted key then
returned 404.

Evidence: [desktop flow](evidence/verification-21/live-desktop-flow.png) and
[audit summary](evidence/verification-21/independent-live-audit.json).

## Deployment, persistence, and rate limits — PASS

All live identity signals agree:

```text
/health build: 693a7609d2efb23c6567da5de0b425db92029e5c
ready image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:693a7609d2ef
revision: sf-mtd-evidence-rail--0000072
mode: Single
replicas: 1/1; running: 1
storage: mtd-data mounted at /data
SQLite VFS: unix-dotfile
```

The locally built JS and CSS hashes equal the live asset hashes. Fresh live
private and demo workspaces each returned 200 on 100/100 fresh-connection
reads. Local restart persistence and three-process shared-storage tests passed;
the latter returned 400/400 reads before and after restart.

The product API has a 40-request general burst with 50 ms refill and a stricter
demo allowance of 20 requests with one token per second. Three live waves of
200 demo requests accepted 29, 30, and 29; the remaining 512 requests returned
429, all with `Retry-After: 1`. The Sociobot subscription verification endpoint
accepted 30 of 120 simultaneous checks and returned 429 for 90, all with
`Retry-After: 4`.

## Privacy, security, accessibility, and routing — PASS

- A direct demo load with seeded private workspace and subscription state made
  only same-origin requests. It sent neither private credential, preserved
  both values, and received a separate 24-hour demo key.
- Root and demo URL checks found correct titles, `lang=en-GB`, one H1, a main
  landmark, image alternatives, labelled buttons, and no console errors.
- Live axe checks across `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the
  real 404 found zero violations, including zero serious/critical findings.
- Keyboard checks reached the skip link first. The visible focus treatment was
  a 3 px brass outline plus dark offset ring. Dialog initial focus, Escape, and
  focus restoration passed.
- At 390 px and at 200% text size there was no horizontal overflow. With
  reduced motion, no animation was running and scroll behavior was `auto`.
- Documents send CSP with header-only `frame-ancestors 'none'`, one-year HSTS,
  `nosniff`, strict-origin referrer policy, and camera/microphone/geolocation
  restrictions. HTML and APIs use `no-cache`; hashed JS/CSS are immutable for
  one year; unversioned images and fonts revalidate after one hour.
- All internal routes returned 200; the deliberate missing route returned 404;
  the external factory link returned 200; checkout returned the expected 303.

The factory `verify-url.sh` passed both root and demo. Evidence:
[root result](evidence/verification-21/root/verify.json),
[demo result](evidence/verification-21/demo/verify.json), and
[23 production-compatible live browser tests](evidence/verification-21/live-playwright.log).

For transparency, an exploratory run of all 25 local-oriented browser tests
against production had two expected harness mismatches: the fixture-only paid
token was correctly rejected by production, and an asynchronous response-body
listener completed after its test ended. The required paid-limit fixture test
passes locally, and independent production probes cover demo isolation. No
product behavior failed.

## Performance and asset budgets — PASS

Mobile Lighthouse scored **99 performance, 100 accessibility, 100 best
practices, and 100 SEO**. FCP was 1.1 s, LCP 1.9 s, TBT 10 ms, and CLS 0.
Transferred first-load resources totalled 181,706 bytes with no third-party
bytes.

- JavaScript: 33,913 bytes raw / 11,164 bytes transferred.
- CSS: 18,132 bytes raw / 5,113 bytes transferred.
- Fonts: 102,396 bytes transferred.
- Mobile hero: 61,374 bytes; desktop hero: 173,422 bytes.

Evidence: [Lighthouse summary](evidence/verification-21/lighthouse-summary.json).

## Applicability and defects

This is not a library, CLI, or PWA; there is no service worker or offline-use
claim. It requires no sign-in, so Entra authority checks do not apply. The
brief's deterministic capture, matching, review, and export work does not need
an AI feature.

- Critical defects: none.
- High defects: none.
- Medium defects: none.
- Low defects: none.

## Final decision

**PASS.** Candidate `693a7609d2efb23c6567da5de0b425db92029e5c`
satisfies the researched brief and factory product contract, and the live
deployment matches that exact candidate.
