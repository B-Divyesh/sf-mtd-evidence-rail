# MTD Evidence Rail — independent verification 8: PASS

**Verified 29 August 2026**  
Candidate: `8c2d0755f2ea2987332f1c97939c66bcb64ec56b`  
Live URL: <https://mtd-evidence-rail.sociobot.in>  
Verdict: **PASS — release candidate is live and meets the acceptance contract.**

## Deployment identity and first read

`GET /health` returned HTTP 200 and
`{"build_sha":"8c2d0755f2ea2987332f1c97939c66bcb64ec56b","status":"ok"}`.
The live JS/CSS asset names and 29 August 05:40 UTC last-modified time match
the candidate build.

Cold desktop read, with a new browser context: “Link each expense to evidence”
plainly says it is for sole traders preparing MTD quarterly updates. The first
action is the visible **Try it with sample data** link, immediately followed by
“See a ready quarter. Nothing is saved.” It opens the isolated `/demo` sample
in one click. This passes the plain-words and demo-first requirements.

## Mandatory claims — all pass

Ran `npm ci`, then every exact command listed in `.factory/claims.json` from
the clean checkout. All 20 passed:

`demo-isolation`, `no-account`, `quarter-capture`, `csv-matching`,
`atomic-import`, `calendar-dates`, `evidence-types`, `missing-review`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit`.

The hosted-checkout assertion observed HTTP 303 to Dodo with product
`mtd-evidence-rail`, GBP 1500, monthly cadence. The tagged browser tests use
the shipped `/demo` entry point and passed their observable assertions.

## Fresh live product evidence

- Live `/demo` started with the documented six records, two missing-evidence
  rows, and a `demo:` workspace key.
- Missing-evidence review showed exactly the two unlinked transactions.
- A representative bank CSV read two rows, skipped its one likely duplicate,
  and imported the one new row. A manual £12.50 expense then saved normally.
- Invalid recovery works: an amount of `0` produced “Enter an amount greater
  than zero.” The live API returned 401 for no workspace key, 400 for
  `2026-02-30`, and 415 for an unsupported evidence type.
- Export produced `evidence-pack-2026-27-Q1.zip`.
- Playwright recorded 13 core-flow outgoing requests; every one was same-origin.
  There were no console or page errors on `/`, `/demo`, `/app`, `/privacy`, or
  `/terms`. The browser’s expected network message for intentional `/not-a-page`
  HTTP 404 is not an application error.
- The source-owned live persistence probe completed 100/100 fresh-connection
  reads for both a private workspace and a demo workspace. This replaces the
  earlier deployment-only failure evidence.

## Backend and privacy

The live backend accepted 42 of 60 simultaneous requests for one
`X-Forwarded-For` client and then returned 18 HTTP 429 responses, each with
`Retry-After: 1`. Source inspection confirms the limiter wraps every `/api`
route (health is deliberately exempt), with burst 40 and the forwarded-IP
extractor. The observed allowance is therefore a 40-request burst plus small
refill during the request window.

The live health endpoint is healthy at the candidate SHA. Local claim checks
also passed runtime-with-only-PORT, restart durability, shared storage, and
the single-replica Azure Files topology contract.

## Accessibility, responsive behaviour, headers, and budgets

Playwright Axe scans of `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the
real 404 found **zero serious or critical violations** (zero total violations).
Each route had one H1. At 390 px the page had no horizontal overflow
(`390/390`); keyboard Tab reached the skip link and showed a 3 px visible
focus ring. Reduced-motion emulation reported no active transitions or
animations.

Live responses provide `X-Content-Type-Options: nosniff`, strict referrer and
permissions policies, a restrictive CSP including `frame-ancestors 'none'`,
and `no-cache` for HTML. Hashed JS/CSS are immutable for one year. The hero is
173,422 bytes and revalidates hourly. Production build output is 30.36 kB JS
(10.31 kB gzip) and 16.96 kB CSS (4.80 kB gzip), inside the required budgets.

## Local quality gates

- `npm run typecheck` — pass
- `npm run build` — pass; writes `dist/`
- `cargo test` — 4/4 pass
- `cargo build --release --locked` — pass
- `npm test` pipeline was exercised by the 20 exact claim commands; its
  complete Rust, browser, storage, topology, and type/build gates passed.

The exact Docker command could not be run because this verifier image has no
`docker` CLI. This is an environment limitation, not a release defect: the
locked release binary built successfully and the matching candidate container
is demonstrably serving the live health and end-to-end workflows.

## Defects by severity

None found.

No product source code was changed during verification. Evidence screenshots:
`/tmp/mtd-live-cold-desktop.png`, `/tmp/mtd-live-demo-desktop.png`, and
`/tmp/mtd-live-mobile.png` in the verifier environment.
