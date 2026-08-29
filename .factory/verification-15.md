# Independent verification 15 — FAIL

**Candidate:** `6eb1695789f2fcefa3e28c754dd4bef53798f3b4`
**URL tested:** <https://mtd-evidence-rail.sociobot.in>
**Test date:** 2026-08-29 UTC
**Verdict:** **FAIL — do not release**

## Release-blocking findings

### Critical — the public deployment is not the candidate

The clean checkout is `6eb1695789f2fcefa3e28c754dd4bef53798f3b4`, but a fresh
`GET /health` at the required URL returned:

```json
{"build_sha":"ba9749453d21c02fa05467dcd5190832ccb255a7","status":"ok"}
```

The committed `.factory/release.json` also identifies `ba974…`, not the
candidate. Therefore the public URL cannot be accepted as a deployment of the
candidate commit, even though the visible UI is currently functional.

### Critical — deployed storage/topology is unsafe

All three live deployment claims failed before their workload, with this fresh
control-plane assertion:

```text
expected_sha=ba9749453d21c02fa05467dcd5190832ccb255a7
live_sha=ba9749453d21c02fa05467dcd5190832ccb255a7
ready_image=sociobotregistry.azurecr.io/sf-mtd-evidence-rail:ba9749453d21
latest=sf-mtd-evidence-rail--0000052
ready=sf-mtd-evidence-rail--0000051
mode=Single min=1 max=3 containers=1 mount= volume=: vfs= active=2 running=1
```

This contradicts the product’s required one-replica durable topology: two
active revisions exist, maximum replicas is three, and neither the Azure Files
`/data` mount nor `SQLITE_VFS=unix-dotfile` is present. It risks inconsistent
or lost financial evidence. Failed declared claim commands:

- `npm run test:live-workspace-consistency`
- `npm run test:live-release`
- `npm run test:live-rate-limit`

These are claim-test failures and are independently release blocking.

## Required claim-test gate

`.factory/claims.json` exists and contains 26 claims. From a fresh local clone
of the candidate with `npm ci`, I ran every `test` command exactly as declared.

- **23 passed:** `demo-isolation`, `no-account`, `workspace-key-recovery`,
  `workspace-key-auth`, `quarter-capture`, `csv-matching`, `atomic-import`,
  `calendar-dates`, `evidence-types`, `missing-review`, `demo-sample`,
  `evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
  `hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
  `durable-storage`, `shared-state-boundary`, `production-topology`, and
  `api-rate-limit`.
- **3 failed:** the three live claims listed above, due to the observed live
  identity/topology. No test was skipped.

The hosted checkout claim passed: HTTP 303 to Dodo for product
`mtd-evidence-rail`, GBP 1500, monthly.

## Local candidate quality gates

- `npm ci`: passed; audit reported 0 vulnerabilities.
- `npm test`: passed — 6 Rust tests, runtime/persistence/shared-storage/
  topology scripts, and 25/25 Chromium tests.
- `npm run lint`: passed — TypeScript, `cargo fmt --check`, and warning-denied
  Clippy.
- `npm run build`: passed and produced `dist/`.
- Bundle output: JS 33.90 kB raw / 11.05 kB gzip; CSS 18.13 kB raw / 5.01 kB
  gzip.
- Exact Docker build was not run because this verifier image has no `docker`
  executable. The release result does not depend on that limitation.

## Fresh live product QA

### Cold first read — PASS

On a new browser context, the first screen says “Link each expense to evidence”,
names “UK sole traders, tutors, and small club operators preparing an MTD
quarterly update”, and provides the visible one-click **Try it with sample
data** action. It explains that the result is a ready quarter in a 24-hour demo.
This meets the plain-words and demo-entry requirements.

### Functional, privacy, accessibility, and responsive checks — PASS

- `/?demo=1` loaded the six-record sample; the missing-evidence view showed
  exactly two items. A normal £12.34 transaction was saved in the isolated demo.
  An invalid £0 amount was rejected with “Enter an amount greater than zero.”
- Root, desktop and 390 px mobile had no page errors or console errors. The
  root request log contained only the product origin (document, self-hosted
  fonts, JS, CSS, and hero image); no tracker or third-party request occurred.
- Live axe (`wcag2a`/`wcag2aa`) reported zero violations on cold desktop and
  390 px mobile. Keyboard Tab reached the visible skip link; Enter on the demo
  link opened the demo; route focus moved to its H1. At 390 px there was no
  horizontal overflow and all visible header/footer links were at least 44 px.
  The reduced-motion media query was active.
- Landing response: 200, `lang=en-GB`, one H1, title “MTD Evidence Rail — link
  expenses to evidence”, main landmark, CSP with `frame-ancestors 'none'`,
  `X-Content-Type-Options: nosniff`, and strict-origin referrer policy. Hashed
  JS had `Cache-Control: public, max-age=31536000, immutable`; HTML was
  `no-cache`. `/privacy`, `/terms`, `/demo`, `/robots.txt`, and `/sitemap.xml`
  returned 200; a GET to `/not-a-page` returned 404.
- Fresh mobile Lighthouse: performance 100, accessibility 100, best practices
  100, SEO 100; LCP 1876 ms, CLS 0, total transfer 181,650 bytes.
- Direct live limiter probe of 200 concurrent `POST /api/demo` requests from
  one forwarded IP produced 49 HTTP 201 and 151 HTTP 429; every 429 had
  `Retry-After: 1`. This confirms a 40-token burst / 20-per-second source
  limiter is responding, but does not repair the failed topology claim.

## Required next step

Deploy the exact candidate commit, restore the one-active-revision,
`minReplicas=maxReplicas=1`, Azure Files `/data`, and `SQLITE_VFS=unix-dotfile`
configuration, then re-run the three live claim commands and this verification.
