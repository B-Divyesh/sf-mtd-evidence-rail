# Independent product verification 17 — FAIL

**Candidate:** `031c677afd3a28b469228b63fcb6e2c99967cc9a`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Work order:** `mtd-evidence-rail-verify-17`

**Verified:** 29 August 2026 UTC

**Verdict:** **FAIL — do not release**

## Release blockers

### High — a mandatory live claim failed on its first exact run

`.factory/claims.json` exists and contains 26 claims. I ran every listed
command from a detached, clean worktree at the exact candidate after `npm ci`.
The first run produced **25 passes and 1 failure**.

`npm run test:live-rate-limit` sent the prescribed 200 concurrent fresh
HTTP/1.1 requests from one forwarded client. It observed:

```text
15 HTTP 000 (30-second timeout)
136 HTTP 201
49 HTTP 429
exit 1
```

Every received 429 included `Retry-After: 1`, but 15 requests received no API
response at all. The claim requires all excess requests to receive 429 with
`Retry-After`, and the acceptance contract makes any failing claim test release
blocking. Evidence: [`claims/live-api-rate-limit.log`](evidence/verification-17/claims/live-api-rate-limit.log).

The failure is intermittent. A later exact retry passed with 171 HTTP 201 and
29 HTTP 429 over 30.293 seconds. An independent, faster 100-request same-client
probe completed in 6.840 seconds with 42 HTTP 201 and 58 HTTP 429; all 58 had
`Retry-After: 1`. This confirms the limiter exists and its configured allowance
is a 40-request burst plus 20 requests/second, but it does not erase the
mandatory first-run failure or the dropped responses under the prescribed
load. Evidence: [`claims/live-api-rate-limit-retry.log`](evidence/verification-17/claims/live-api-rate-limit-retry.log)
and [`live/rate-probe-node.json`](evidence/verification-17/live/rate-probe-node.json).

### High — the deployed build identity is not the candidate commit

Fresh `/health` and Azure control-plane checks identify:

```text
candidate: 031c677afd3a28b469228b63fcb6e2c99967cc9a
live build: bced2406fb8e1abdeb374ef13a40c78131799b0a
image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:bced2406fb8e
revision: sf-mtd-evidence-rail--0000061
```

The candidate's committed `.factory/release.json` also points to `bced2406…`,
so `test:live-release` passes against that manifest instead of asserting the
work-order candidate. The delta from `bced2406…` to the candidate changes only
`.factory/handoff.md` and `.factory/release.json`, and the deployed HTML, JS,
and CSS match the clean candidate build byte for byte. Runtime product behavior
therefore matches, but the requested exact candidate identity does not.
Evidence: [`live/health.json`](evidence/verification-17/live/health.json).

## Mandatory first-read and demo gate — PASS

A cold 1440×900 browser saw, without scrolling:

- what it does: **“Link each expense to evidence”**;
- who it is for: **“UK sole traders, tutors, and small club operators preparing
  an MTD quarterly update”**;
- what to click first: **“Try it with sample data”**.

That single click opened `/?demo=1`, loaded six realistic transactions, and
showed the persistent “Demo — sample data” banner with **Reset demo** and
**Start a private workspace**. There were no console or page errors. Evidence:
[`live/first-read.json`](evidence/verification-17/live/first-read.json) and
[`live/cold-desktop.png`](evidence/verification-17/live/cold-desktop.png).

## Claims gate

Passed on the first exact run:

`demo-isolation`, `no-account`, `workspace-key-recovery`,
`workspace-key-auth`, `quarter-capture`, `csv-matching`, `atomic-import`,
`calendar-dates`, `evidence-types`, `missing-review`, `demo-sample`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`,
`live-workspace-consistency`, `live-release-identity`, and `api-rate-limit`.

Failed on the first exact run: `live-api-rate-limit`.

The hosted checkout returned HTTP 303 to a Dodo session for product
`mtd-evidence-rail`, GBP 1500, monthly. Live workspace consistency returned
100/100 private and 100/100 demo reads. The live topology was one active ready
replica with Azure Files mounted at `/data` and `SQLITE_VFS=unix-dotfile`.
The complete result table is in
[`claims/results.tsv`](evidence/verification-17/claims/results.tsv).

No unsupported claim-like sentence was found on the landing page or in the
README after mapping the copy to the 26 declared claims.

## Local quality gates — PASS

- Clean detached worktree at the exact candidate; `npm ci` passed with 34
  packages and no install audit findings.
- `npm test`: passed; 8 Rust tests and 25/25 Chromium tests, including runtime
  defaults, restart persistence, three-process shared storage, axe, mobile,
  keyboard, routing, offline-error, and cache checks.
- `npm run lint`: passed TypeScript, `cargo fmt --check`, and warning-denied
  Clippy.
- `npm run build`: passed and produced `dist/`.
- `cargo build --release --locked`: passed.
- `npm run test:verification-16-regression`: passed the topology repair
  integration, release guard, and Rust regression.
- `npm audit --audit-level=low`: zero vulnerabilities.
- Docker CLI was not available in the verifier container. Both Dockerfile
  build payloads were independently built with `npm run build` and
  `cargo build --release --locked`; the Dockerfile uses multi-stage builds,
  `rust:1-slim`, `ARG BUILD_SHA=dev`, a non-root runtime user, and port 8080.

## Independent end-to-end exercise — PASS

Fresh live demo, using the visible UI:

- loaded six transactions and filtered to the expected two missing items;
- rejected £0 with “Enter an amount greater than zero,” then saved £0.01;
- rejected a file over 5 MB, then linked a text receipt;
- explained missing CSV headings and zero-value rows, then reviewed a valid
  two-row CSV, skipped one amount/date match, and imported the new row;
- downloaded `evidence-pack-2026-27-Q1.zip`, with a `PK` signature,
  `transactions.csv`, and evidence entries;
- Reset demo restored six transactions and two missing items.

Independent API boundaries accepted £0.01 and £1,000,000; rejected £0,
£1,000,000.01, an impossible date, blank description, and invalid transaction
kind with actionable HTTP 400 responses. Deletion required confirmation,
returned 204 when confirmed, and subsequent reads returned 404.

A 30-write concurrency probe returned 25 HTTP 201 and five expected HTTP 402
responses. Exactly 25 unique records persisted, with no lost accepted writes
or 5xx responses. Evidence:
[`live/independent-flow.json`](evidence/verification-17/live/independent-flow.json),
[`live/boundary-recovery.json`](evidence/verification-17/live/boundary-recovery.json),
and [`live/concurrent-writes.json`](evidence/verification-17/live/concurrent-writes.json).

## Privacy, security, accessibility, and responsive behavior

- The whole demo flow made same-origin requests only. No analytics, trackers,
  CDN scripts, private workspace key, or subscription token left the demo.
- HTML and API responses send CSP with header-only `frame-ancestors 'none'`,
  `X-Content-Type-Options: nosniff`, strict-origin referrer policy, and a
  camera/microphone/geolocation permissions policy. HTTP redirects to HTTPS.
- HTML and API use `no-cache`; hashed JS/CSS use one-year immutable caching;
  unversioned images and fonts use one-hour revalidation.
- The worker `verify-url.sh` passed: HTTP 200, title, `lang=en-GB`, one H1, main
  landmark, complete image alt text, labelled buttons, and no console errors.
- Live Playwright ran 24/24 production-safe tests successfully. Live axe scans
  of `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the real 404 found zero
  violations.
- At 390 px there was no horizontal overflow; all 23 visible actionable
  controls measured at least 44×44 px. Keyboard focus exposed the skip link
  with a 3 px brass outline, Enter opened the demo, dialog focus moved to the
  first control, Escape returned focus, and no keyboard trap appeared.
- With `prefers-reduced-motion: reduce`, no element retained an active CSS
  animation or transition. The 200%-text check passed.
- No console errors or uncaught page errors occurred in the cold load, full
  route suite, desktop flow, or mobile flow.
- Low hardening gap: responses do not send `Strict-Transport-Security`, despite
  redirecting HTTP to HTTPS.

## Performance and asset budgets — PASS

Fresh mobile Lighthouse: performance 99, accessibility 100, best practices
100, SEO 100; FCP 0.9 s, LCP 1.7 s, TBT 120 ms, CLS 0, total transfer 177 KiB.

Production assets:

- JS: 33,904 bytes raw / 11.05 kB gzip;
- CSS: 18,132 bytes raw / 5.01 kB gzip;
- fonts: 102,036 bytes total;
- mobile hero: 61,374 bytes; desktop hero: 173,422 bytes.

All stated budgets pass. Candidate and live HTML/JS/CSS SHA-256 hashes are
identical.

## Applicability notes

This is not a library or CLI, so consumer package installation does not apply.
It is not a PWA and makes no offline-use claim, so service-worker update and
offline reload tests do not apply. It requires no sign-in, so the Sociobot
Entra tenant requirement does not apply. There is no runtime AI feature, and
the brief does not require one.

## Defects by severity

- **High / release blocking:** the mandatory `live-api-rate-limit` claim failed
  once under its exact prescribed load with 15 requests receiving no response;
  a retry passed, demonstrating nondeterministic behavior.
- **High / release blocking:** live build identity is `bced2406…`, not the
  requested candidate `031c677…`; the current claim checks the release manifest
  rather than the work-order candidate.
- **Low:** HTTPS responses omit `Strict-Transport-Security`.

## Required remediation

1. Make the 200-request live limiter claim reliable: excess calls must always
   receive 429 with `Retry-After`, with no dropped/timed-out responses.
2. Publish the candidate identity, or change the release process and claim so
   a metadata-only candidate is explicitly and verifiably tied to its deployed
   product-source commit.
3. Add HSTS at the application or ingress layer.
4. Rerun all 26 claim commands from a clean checkout; accept only if every
   first run passes.

All retained evidence is under
[`evidence/verification-17`](evidence/verification-17/).
