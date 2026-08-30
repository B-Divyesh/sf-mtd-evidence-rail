# Independent product verification 18 — FAIL

**Requested candidate:** `bb51321015e6489d85dd8b1102b18328cb87810d`

**Closest available branch tip tested locally:** `bb5132445c72488a0840631f7d060fc112254af3`

**Live source identity:** `dbb7dff54f1d40e460b54479a82b33c4a9e832bd`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Work order:** `mtd-evidence-rail-verify-18`

**Verified:** 30 August 2026 UTC

**Verdict:** **FAIL — do not release**

## Release blockers

### Critical — the requested candidate does not exist in the supplied repository

The exact candidate could not be checked out from the supplied clone. A direct
fetch from `origin` returned:

```text
fatal: remote error: upload-pack: not our ref bb51321015e6489d85dd8b1102b18328cb87810d
```

`git ls-remote origin` exposes only `main` at
`bb5132445c72488a0840631f7d060fc112254af3`. It is therefore impossible to
reproduce, build, or establish the contents of the requested candidate. To
avoid substituting silently, all local results below are explicitly for the
closest available work-order base, `bb513244…`.

Evidence: [candidate-repro.txt](evidence/verification-18/local/candidate-repro.txt).

### High — one mandatory claim failed and live does not identify the candidate

`.factory/claims.json` exists with 26 claims. Every listed command was run
independently from a clean detached clone at `bb513244…` after `npm ci`.
The result was **25 passes and 1 failure**.

`npm run test:live-release` failed immediately:

```text
Candidate bb5132445c72488a0840631f7d060fc112254af3 is not the published source
dbb7dff54f1d40e460b54479a82b33c4a9e832bd or its direct metadata child.
```

Fresh `/health` returned build `dbb7dff…`. The control-plane-backed live tests
reported ready revision `sf-mtd-evidence-rail--0000064`, image
`sociobotregistry.azurecr.io/sf-mtd-evidence-rail:dbb7dff54f1d`, one active
revision, one running replica, Azure Files at `/data`, and
`SQLITE_VFS=unix-dotfile`. The requested `bb513210…` cannot match this identity
because it is not present in the repository. Evidence:
[live-release-identity.log](evidence/verification-18/claims/live-release-identity.log),
[health.json](evidence/verification-18/live/health.json), and
[workspace-consistency.log](evidence/verification-18/live/workspace-consistency.log).

The live HTML, JS, and CSS hashes do match a clean build of the available
`bb513244…` tree. That confirms functional byte parity with the available base,
but it does not repair the candidate provenance failure. The available base is
also not a direct metadata-only child of `dbb7dff…`; its diff includes
`graphify-out` files.

Evidence: [identity-hashes.txt](evidence/verification-18/live/identity-hashes.txt).

## Mandatory first-read and demo gate — PASS

A cold 1440×900 browser answered all three questions without scrolling:

- what it does: **“Link each expense to evidence”**;
- who it serves: **“UK sole traders, tutors, and small club operators preparing
  an MTD quarterly update”**;
- what to click: **“Try it with sample data.”**

That single click opened `/?demo=1`. The ready product showed six realistic
transactions and a persistent **“Demo — sample data”** banner with **Reset
demo** and **Start a private workspace**. Evidence:
[cold-desktop.png](evidence/verification-18/live/cold-desktop.png) and
[desktop-flow.png](evidence/verification-18/live/desktop-flow.png).

## Claims gate

| Claim | Result | Exact-run evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | [log](evidence/verification-18/claims/demo-isolation.log) |
| `no-account` | PASS | [log](evidence/verification-18/claims/no-account.log) |
| `workspace-key-recovery` | PASS | [log](evidence/verification-18/claims/workspace-key-recovery.log) |
| `workspace-key-auth` | PASS | [log](evidence/verification-18/claims/workspace-key-auth.log) |
| `quarter-capture` | PASS | [log](evidence/verification-18/claims/quarter-capture.log) |
| `csv-matching` | PASS | [log](evidence/verification-18/claims/csv-matching.log) |
| `atomic-import` | PASS | [log](evidence/verification-18/claims/atomic-import.log) |
| `calendar-dates` | PASS | [log](evidence/verification-18/claims/calendar-dates.log) |
| `evidence-types` | PASS | [log](evidence/verification-18/claims/evidence-types.log) |
| `missing-review` | PASS | [log](evidence/verification-18/claims/missing-review.log) |
| `demo-sample` | PASS | [log](evidence/verification-18/claims/demo-sample.log) |
| `evidence-pack` | PASS | [log](evidence/verification-18/claims/evidence-pack.log) |
| `workspace-delete` | PASS | [log](evidence/verification-18/claims/workspace-delete.log) |
| `free-limit` | PASS | [log](evidence/verification-18/claims/free-limit.log) |
| `paid-limit` | PASS | [log](evidence/verification-18/claims/paid-limit.log) |
| `hosted-checkout` | PASS | [log](evidence/verification-18/claims/hosted-checkout.log) |
| `license-return` | PASS | [log](evidence/verification-18/claims/license-return.log) |
| `no-trackers` | PASS | [log](evidence/verification-18/claims/no-trackers.log) |
| `runtime-defaults` | PASS | [log](evidence/verification-18/claims/runtime-defaults.log) |
| `durable-storage` | PASS | [log](evidence/verification-18/claims/durable-storage.log) |
| `shared-state-boundary` | PASS | [log](evidence/verification-18/claims/shared-state-boundary.log) |
| `production-topology` | PASS | [log](evidence/verification-18/claims/production-topology.log) |
| `live-workspace-consistency` | PASS | [log](evidence/verification-18/claims/live-workspace-consistency.log) |
| `live-release-identity` | **FAIL** | [log](evidence/verification-18/claims/live-release-identity.log) |
| `api-rate-limit` | PASS | [log](evidence/verification-18/claims/api-rate-limit.log) |
| `live-api-rate-limit` | PASS | [log](evidence/verification-18/claims/live-api-rate-limit.log) |

The machine-readable first-run table is
[results.tsv](evidence/verification-18/claims/results.tsv). Landing and README
claims map to these declarations; no unlisted product claim was found.

The checkout claim observed HTTP 303 to a Dodo-hosted session for product
`mtd-evidence-rail`, GBP 1500, monthly. No purchase was completed.

## Clean-source quality gates — PASS on the available base

- `npm ci`: 34 packages installed; zero audit findings.
- `npm test`: 9/9 Rust tests and 25/25 Chromium tests passed, including runtime
  defaults, restart persistence, three-process shared storage, axe, keyboard,
  mobile, 200% text, routing, offline recovery, and cache behavior.
- `npm run lint`: TypeScript, Rust format, and warning-denied Clippy passed.
- `npm run build`: passed and produced `dist/`.
- `cargo build --release --locked`: passed.
- `npm audit --audit-level=low`: zero vulnerabilities.
- The Docker CLI is absent in the verifier container, so a local image build
  was not possible. The exact frontend and optimized backend build payloads
  passed. The inspected Dockerfile is multi-stage, uses `rust:1-slim`, declares
  `ARG BUILD_SHA=dev`, runs non-root, exposes 8080, and contains no `.git`
  dependency.

Evidence:
[npm test](evidence/verification-18/local/mtd-full-test.log),
[lint](evidence/verification-18/local/mtd-lint.log),
[build](evidence/verification-18/local/mtd-build.log), and
[release build](evidence/verification-18/local/mtd-release-build.log).

## Independent end-to-end exercise — PASS

Fresh live demo testing through the visible interface:

- loaded six transactions with four linked files and two missing items;
- filtered to exactly the two missing transactions;
- rejected £0 with the assertive message “Enter an amount greater than zero,”
  then saved £0.01 and displayed it in the missing-evidence list;
- explained missing CSV headings, then reviewed a valid two-row CSV, flagged
  one amount-and-date match, skipped it, and imported the new row;
- downloaded `evidence-pack-2026-27-Q1.zip`; it had the `PK` signature and
  contained `transactions.csv` plus evidence entries.

Independent API boundary checks accepted £0.01 and £1,000,000. They rejected
£0, £1,000,000.01, 30 February, a blank description, and an invalid kind with
actionable HTTP 400 messages.

A fresh 30-write concurrency check returned 25 HTTP 201 and five expected HTTP
402 free-limit responses. Exactly 25 unique accepted records persisted. The
workspace deletion returned 204, then the same key returned 404.

Evidence: [independent-flow.json](evidence/verification-18/live/independent-flow.json)
and [concurrency.json](evidence/verification-18/live/concurrency.json).

## Backend persistence, identity, and rate limiting

- Local runtime-default testing started the real service with only `PORT`.
- Restart persistence kept the same workspace across a service restart.
- Three local processes sharing one data directory returned 400/400 successful
  workspace reads before and after restart.
- Live consistency returned 100/100 fresh-connection reads for both a private
  and demo workspace.
- `/health` returned HTTP 200, status `ok`, and build `dbb7dff…`.
- The live limiter completed three independent 200-request demo waves. They
  produced 30/29/30 HTTP 201 and 170/171/170 HTTP 429 responses. Every 429 sent
  `Retry-After: 1`; there were no timeouts or other statuses.

The observed demo allowance is a **20-request burst plus one request per
second**; each roughly 10-second wave admitted 29–30 requests. A broader API
limiter allows a 40-request burst with one token every 50 ms. The in-process
claim proved the first `X-Forwarded-For` hop is the client key and request 41 is
429 with `Retry-After: 1`.

Evidence: [rate-limit.log](evidence/verification-18/live/rate-limit.log) and
[workspace-consistency.log](evidence/verification-18/live/workspace-consistency.log).

## Privacy, security, accessibility, and responsive behavior — PASS

- The complete demo flow sent same-origin requests only. No tracker, analytics,
  CDN script, private key, or subscription token left the demo origin.
- Root and API responses send CSP with header-only `frame-ancestors 'none'`,
  HSTS for one year including subdomains, `nosniff`, strict-origin referrer
  policy, and camera/microphone/geolocation restrictions.
- HTML and APIs use `no-cache`; hashed JS/CSS use one-year immutable caching;
  unversioned images/fonts use one-hour revalidation. HTTP redirects to HTTPS.
- Live Playwright passed 24/24 production-safe tests. Independent axe scans of
  `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the real 404 found zero
  serious or critical violations.
- Factory `verify-url.sh` passed both `/` and `/?demo=1`: correct title,
  `lang=en-GB`, one H1, main landmark, complete alt text, labelled buttons, and
  no console errors.
- At 390 px there was no horizontal overflow. All visible controls were at
  least 44 px; the two visually hidden file inputs use visible 100×48 labels.
- Keyboard focus exposed the skip link, Enter opened the demo, dialog focus
  moved to its first control, Escape restored focus, and no trap appeared.
  Focus uses a 3 px brass outline with a dark 5 px surround.
- Reduced-motion mode had zero running animation, no train animation, and
  automatic rather than smooth scrolling. The 200%-text test passed.
- Valid routes produced no console or page errors. The deliberate 404 probe
  produced only the expected browser resource warning.
- A crawl found all internal links at 200; checkout returned the expected 303
  hosted redirect and Sociobot returned 200.

Evidence:
[independent-flow.json](evidence/verification-18/live/independent-flow.json),
[mobile-390.png](evidence/verification-18/live/mobile-390.png),
[root verify](evidence/verification-18/verify-url/root/verify.json), and
[demo verify](evidence/verification-18/verify-url/demo/verify.json).

## Performance and bundle budgets — PASS

Fresh mobile Lighthouse: performance **98**, accessibility **100**, best
practices **100**, SEO **100**; FCP 1.1 s, LCP 1.8 s, TBT 140 ms, CLS 0, total
transfer 177 KiB.

- JS: 33,904 bytes raw / 11.05 kB gzip;
- CSS: 18,132 bytes raw / 5.01 kB gzip;
- fonts: 102,036 bytes total;
- mobile hero: 61,374 bytes;
- desktop hero: 173,422 bytes.

All contract budgets pass. Evidence:
[lighthouse.json](evidence/verification-18/live/lighthouse.json).

## Applicability and missed-leverage checks

This is not a library or CLI. It is not a PWA, registers no service worker, and
makes no offline-use claim; its tested offline path gives a recovery message.
It requires no sign-in, so the Entra authority requirement does not apply. It
has no runtime AI feature, and the brief's useful matching, import/export, and
review steps are already present; no obvious missing AI or sync step was found.

## Defects by severity

- **Critical / release blocking:** requested candidate `bb513210…` is absent
  from the supplied repository and remote, so its content cannot be verified.
- **High / release blocking:** mandatory `live-release-identity` claim fails;
  live identifies `dbb7dff…`, not the available base and not the requested
  candidate.
- **Medium:** none found.
- **Low:** none found.

## Required remediation

1. Publish the exact requested candidate SHA to the supplied repository, or
   issue a corrected work order naming an existing immutable commit.
2. Deploy that candidate/product-source relationship so `/health`, the ready
   image, revision, and release record agree under `npm run test:live-release`.
3. Rerun all 26 claim commands from a clean checkout and accept only if every
   first exact run passes.

All retained evidence is under
[evidence/verification-18](evidence/verification-18/).
