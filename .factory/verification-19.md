# Independent product verification 19 — PASS

**Candidate:** `02cc1ea96227310fa61d5e3a4b90b08c1b6ccc92`

**Published product source:** `b8408a552f17a2094e8e87f989cdab94d175af2f`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Work order:** `mtd-evidence-rail-verify-19`

**Verified:** 30 August 2026 UTC

**Verdict:** **PASS — release accepted**

No critical, high, medium, or low product defect was found. The deployment-only
failure reported by verification 18 no longer reproduces.

## Mandatory first-read and demo gate — PASS

A cold 1440×900 browser answered all three required questions without scrolling:

- what it does: **“Link each expense to evidence”**;
- who it is for: **UK sole traders, tutors, and small club operators preparing
  an MTD quarterly update**; and
- what to click first: **“Try it with sample data.”**

The action explains that it opens a ready quarter in a separate 24-hour demo.
It opens the populated product in one click. At 390×844, the headline, audience,
demo action, and all three plain facts end at 714 px and remain in the first
viewport. The demo shows six realistic transactions, two missing items, and a
persistent banner with **Reset demo** and **Start a private workspace**.

Evidence: [cold desktop](evidence/verification-19/live/cold-desktop.png),
[mobile demo](evidence/verification-19/live/demo-mobile-390.png), and
[factory URL checks](evidence/verification-19/live/verify-root.json).

## Claims gate — 26/26 PASS

`.factory/claims.json` exists and contains 26 entries. Every claim id has exactly
one matching `@claim:<id>` test. I cloned the GitHub repository separately,
checked out the exact candidate in detached state, confirmed no tracked changes,
ran `npm ci`, and ran every listed `test` command independently. All passed.

| # | Claim | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | `demo-isolation` | PASS | [log](evidence/verification-19/claims/01.log) |
| 2 | `no-account` | PASS | [log](evidence/verification-19/claims/02.log) |
| 3 | `workspace-key-recovery` | PASS | [log](evidence/verification-19/claims/03.log) |
| 4 | `workspace-key-auth` | PASS | [log](evidence/verification-19/claims/04.log) |
| 5 | `quarter-capture` | PASS | [log](evidence/verification-19/claims/05.log) |
| 6 | `csv-matching` | PASS | [log](evidence/verification-19/claims/06.log) |
| 7 | `atomic-import` | PASS | [log](evidence/verification-19/claims/07.log) |
| 8 | `calendar-dates` | PASS | [log](evidence/verification-19/claims/08.log) |
| 9 | `evidence-types` | PASS | [log](evidence/verification-19/claims/09.log) |
| 10 | `missing-review` | PASS | [log](evidence/verification-19/claims/10.log) |
| 11 | `demo-sample` | PASS | [log](evidence/verification-19/claims/11.log) |
| 12 | `evidence-pack` | PASS | [log](evidence/verification-19/claims/12.log) |
| 13 | `workspace-delete` | PASS | [log](evidence/verification-19/claims/13.log) |
| 14 | `free-limit` | PASS | [log](evidence/verification-19/claims/14.log) |
| 15 | `paid-limit` | PASS | [log](evidence/verification-19/claims/15.log) |
| 16 | `hosted-checkout` | PASS | [log](evidence/verification-19/claims/16.log) |
| 17 | `license-return` | PASS | [log](evidence/verification-19/claims/17.log) |
| 18 | `no-trackers` | PASS | [log](evidence/verification-19/claims/18.log) |
| 19 | `runtime-defaults` | PASS | [log](evidence/verification-19/claims/19.log) |
| 20 | `durable-storage` | PASS | [log](evidence/verification-19/claims/20.log) |
| 21 | `shared-state-boundary` | PASS | [log](evidence/verification-19/claims/21.log) |
| 22 | `production-topology` | PASS | [log](evidence/verification-19/claims/22.log) |
| 23 | `live-workspace-consistency` | PASS | [log](evidence/verification-19/claims/23.log) |
| 24 | `live-release-identity` | PASS | [log](evidence/verification-19/claims/24.log) |
| 25 | `api-rate-limit` | PASS | [log](evidence/verification-19/claims/25.log) |
| 26 | `live-api-rate-limit` | PASS | [log](evidence/verification-19/claims/26.log) |

The hosted-checkout claim observed HTTP 303 to Dodo product
`pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly. No purchase was completed.
Landing and README claims map to the claim list; no unlisted reliance claim was
found.

## Clean-checkout quality gates — PASS

- `npm ci`: 34 packages installed; zero audit findings.
- `npm test`: 9/9 Rust tests and 25/25 Chromium tests passed.
- `npm run lint`: TypeScript, Rust formatting, and warning-denied Clippy passed.
- `npm run build`: passed and produced `dist/`.
- `cargo build --release --locked`: passed.
- `npm audit --audit-level=low`: zero vulnerabilities.
- Playwright is pinned and ran at 1.58.2.

The container does not provide Docker or Podman, so a local image assembly was
not possible. The exact Docker build payloads passed (`npm ci`/Vite and locked
release Rust build), the Dockerfile is multi-stage and non-root with
`ARG BUILD_SHA=dev`, and the deployed ACR image passed identity and runtime
checks.

Evidence: [full test](evidence/verification-19/local/npm-test.log),
[lint](evidence/verification-19/local/lint.log),
[frontend build](evidence/verification-19/local/build.log),
[release backend build](evidence/verification-19/local/release-build.log), and
[audit](evidence/verification-19/local/npm-audit.log).

## Independent end-to-end exercise — PASS

The live product was exercised independently, outside its claim suite:

- opened the six-record demo from the landing action;
- filtered to exactly two missing-evidence records;
- rejected £0 with “Enter an amount greater than zero,” then saved £0.01;
- explained missing CSV headings, then reviewed a valid two-row file, flagged
  one matching amount/date, skipped it, and imported only the new row;
- rejected a 5 MB + 1 byte evidence file, then linked a valid text file; and
- downloaded `evidence-pack-2026-27-Q1.zip`, with a `PK` signature,
  `transactions.csv`, and evidence entries.

Independent API boundaries accepted £0.01 and £1,000,000. They rejected £0,
£1,000,000.01, 30 February, a blank description, and an invalid transaction
kind with HTTP 400 and actionable messages. Thirty concurrent writes into a
fresh free workspace produced exactly 25 HTTP 201 responses and five HTTP 402
responses; 25 unique records persisted. Workspace deletion returned 204 and
the deleted key then returned 404.

Evidence: [independent flow](evidence/verification-19/live/independent-flow.json)
and [desktop demo](evidence/verification-19/live/demo-desktop.png).

## Deployment identity, persistence, and rate limits — PASS

Candidate `02cc1ea…` is a descendant of published source `b8408a5…`. The
cumulative difference contains only `.factory/handoff.md`,
`.factory/release.json`, and generated `graphify-out` maps. No product,
dependency, test, migration, or deployment input differs.

Fresh live evidence agrees on the published source:

```text
/health build: b8408a552f17a2094e8e87f989cdab94d175af2f
ready image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:b8408a552f17
revision: sf-mtd-evidence-rail--0000067
active/running replicas: 1/1
storage: mtd-data at /data
SQLite VFS: unix-dotfile
```

Local `dist/index.html`, hashed JS/CSS, and both responsive hero files are
byte-for-byte identical to live. Live consistency returned 100/100 reads for a
fresh private workspace and 100/100 for a demo workspace. The broader topology
probe also returned 20/20 404s after deletion and loaded 12/12 fresh browser
demos.

The product API configures a 40-request general burst with 50 ms refill and a
stricter demo allowance of 20 requests with one token per second. Three live
200-request demo waves accepted 30, 31, and 29 requests over about 12 seconds;
the other 510 responses were 429, all with `Retry-After: 1`. The externally
used Sociobot subscription-verification endpoint was also probed: 30/200 were
accepted and 170/200 returned 429 with `Retry-After: 3` or `4` seconds.

Evidence: [identity and hashes](evidence/verification-19/live/identity-hashes.txt),
[live topology](evidence/verification-19/live/live-topology.log),
[live rate claim](evidence/verification-19/claims/26.log), and
[billing rate probe](evidence/verification-19/live/billing-rate-limit.json).

## Privacy, security, accessibility, and routes — PASS

- The complete demo core flow made 16 requests, all to the product origin. No
  trackers, external scripts, request failures, console errors, or page errors
  appeared. Checkout and subscription verification are explicit Sociobot
  actions outside that core flow.
- Browser response headers on documents and APIs included a matching CSP with
  header-only `frame-ancestors 'none'`, one-year HSTS, `nosniff`, strict-origin
  referrer policy, and camera/microphone/geolocation restrictions.
- HTML, health, and APIs use `no-cache`; hashed JS/CSS use one-year immutable
  caching; unversioned images and fonts use one-hour revalidation. HTTP redirects
  to HTTPS.
- `/`, `/demo`, `/app`, `/privacy`, `/terms`, and a real 404 each had one H1,
  no horizontal overflow at 390 px, and zero axe violations of any severity.
- Keyboard-only checks passed the skip link, Enter activation, initial dialog
  focus, Escape close, and focus restoration. Focus is visibly styled.
- With reduced motion, no animation was running, the train animation was
  disabled, and scroll behavior was `auto`. The repository's 200% text test
  passed.
- All crawled internal links returned 200, the deliberate missing route returned
  404, Sociobot returned 200, and checkout returned the expected 303.
- Factory `verify-url.sh` passed `/` and `/?demo=1`: correct titles,
  `lang=en-GB`, one H1, main landmark, alt text, labelled buttons, and no console
  errors. Loads were 800 ms and 979 ms.
- A production-safe live Playwright rerun passed 24/24 tests.

Evidence: [headers](evidence/verification-19/live/headers.txt),
[live Playwright](evidence/verification-19/live/live-playwright.log),
[root URL check](evidence/verification-19/live/verify-root.json), and
[demo URL check](evidence/verification-19/live/verify-demo.json).

## Performance and asset budgets — PASS

Two uncontended mobile Lighthouse runs scored **99 performance, 100
accessibility, 100 best practices, and 100 SEO**. The retained run measured FCP
968 ms, LCP 1,664 ms, TBT 118 ms, CLS 0, and 181,694 transferred bytes. An
earlier run overlapping a full optimized Rust compilation scored 89; isolated
repeats restored 99 and are the representative measurements.

- JavaScript: 33,904 bytes raw / 11,042 bytes gzip.
- CSS: 18,132 bytes raw / 5,010 bytes gzip.
- Fonts: 102,036 bytes total.
- Mobile hero: 61,374 bytes; desktop hero: 173,422 bytes.

Evidence: [Lighthouse JSON](evidence/verification-19/live/lighthouse.json) and
[asset budgets](evidence/verification-19/local/budgets.txt).

## Applicability and gaps

This is not a library or CLI. It is not a PWA, registers no service worker, and
makes no offline-use claim; its offline recovery notice is tested. It requires
no sign-in, so the Entra authority requirement does not apply. The brief does
not need an AI feature: its useful import, matching, review, evidence, export,
and deletion steps are implemented.

## Defects by severity

- Critical: none.
- High: none.
- Medium: none.
- Low: none.

## Final decision

**PASS.** Candidate `02cc1ea96227310fa61d5e3a4b90b08c1b6ccc92` satisfies the
researched brief and factory contract, and the live deployment represents its
identical product source.
