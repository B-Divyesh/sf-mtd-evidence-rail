# Independent product verification 16 — FAIL

**Candidate:** `560392b27a89568a3e88ca461b060f42fec7e61f`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Verified:** 29 August 2026 UTC

**Verdict:** **FAIL — do not release**

## Release blocker

### Critical — live financial records are on an unsafe deployment topology

All three declared live release claims fail against fresh Azure control-plane
state:

```text
expected_sha=5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9
live_sha=5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9
expected_image=sociobotregistry.azurecr.io/sf-mtd-evidence-rail:5779508e0a5c
ready_image=sociobotregistry.azurecr.io/sf-mtd-evidence-rail:5779508e0a5c
latest=sf-mtd-evidence-rail--0000054
ready=sf-mtd-evidence-rail--0000053
ready_active=true
mode=Single min=1 max=3 containers=1
mount= volume=: vfs=
active=2 running=1
```

The live service can scale local SQLite state to three replicas, has two active
revisions, and has neither the required Azure Files `/data` mount nor
`SQLITE_VFS=unix-dotfile`. The current single running replica explains why
point-in-time flows pass; it does not make records durable or consistent after
a scale event, replacement, or restart. This is unacceptable for financial
evidence and directly contradicts the privacy page and README.

Failed required commands:

- `npm run test:live-workspace-consistency`
- `npm run test:live-release`
- `npm run test:live-rate-limit`

Each stops on the unsafe topology before its workload. Any claim-test failure
is release blocking under the acceptance contract.

## Candidate and deployment identity

The public `/health` response is HTTP 200 and identifies published source
`5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9`, not candidate wrapper commit
`560392b27a89568a3e88ca461b060f42fec7e61f`. This is product-equivalent rather
than frontend skew:

- there are no product-source changes from `5779508…` through the candidate;
  only `.factory` metadata and generated graph files changed;
- live and candidate `index.html`, `index-CbYEboLH.js`, and
  `index-B2Qaf5JO.css` match byte for byte;
- live JS SHA-256 is `acc28b29…c2c16c`; CSS is `ec6e1655…0a3f991`.

The product bytes therefore match the candidate tree. The release identity
claim still fails because the latest revision is not ready and the live
topology is unsafe.

## Mandatory first-read and demo gate — PASS

A new desktop browser context sees:

- what it does: **“Link each expense to evidence”**;
- who it is for: **“UK sole traders, tutors, and small club operators preparing
  an MTD quarterly update”**;
- what to click: exactly one visible **“Try it with sample data”** action.

One click opens `/?demo=1`, shows “Demo — sample data. Changes stay in this
24-hour demo,” provides **Reset demo** and **Start a private workspace**, and
loads six realistic transactions with four linked files and two missing items.

## Claims gate

`.factory/claims.json` exists with 26 claims. I ran every listed command from a
detached checkout at the exact candidate after `npm ci`. Result: **23 passed,
3 failed**.

Passed: `demo-isolation`, `no-account`, `workspace-key-recovery`,
`workspace-key-auth`, `quarter-capture`, `csv-matching`, `atomic-import`,
`calendar-dates`, `evidence-types`, `missing-review`, `demo-sample`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit`.

Failed: `live-workspace-consistency`, `live-release-identity`, and
`live-api-rate-limit`, all due to the topology above. The hosted checkout test
observed an HTTP 303 to Dodo for `mtd-evidence-rail`, GBP 1500, monthly.

The literal pre-install run was also performed first as requested. Commands
needing Node tooling initially stopped because a clean clone has no
`node_modules`; after the required lockfile install, the results above were
reproduced twice, including in the detached candidate worktree.

## Local quality gates — PASS

- `npm ci`: pass; 0 vulnerabilities.
- `npm test`: pass; 7 Rust tests and 25/25 Chromium tests.
- `npm run lint`: pass; TypeScript, Rust formatting, and warning-denied Clippy.
- `npm run build`: pass; `dist/` produced.
- `cargo build --release --locked`: pass.
- Runtime with only `PORT`, restart persistence, and three-process shared-store
  tests: pass.
- Independent concurrent-write probe: 25/30 writes returned 201, the remaining
  five returned the intended free-limit 402, and the final stored count was
  exactly 25; no 5xx or lost accepted writes.

No Docker-compatible CLI is installed in the verifier container, so an image
build could not be repeated. Both exact Dockerfile build stages were built
directly and passed.

## Independent end-to-end product exercise — PASS

On the live demo, using only the visible UI:

- the six-record sample loaded and the missing queue showed the expected two;
- £0 was rejected with “Enter an amount greater than zero,” then £12.34 saved;
- a text receipt linked and changed the record to **Linked**;
- an invalid CSV explained the required headings, then a valid two-row CSV
  skipped one amount-and-date match and imported the new row;
- the missing queue updated to three after that new unlinked import;
- export downloaded `evidence-pack-2026-27-Q1.zip` with a `PK` signature,
  `transactions.csv`, and evidence entries;
- Reset demo restored six transactions and two missing items.

Independent live API boundary checks accepted £0.01 and £1,000,000, rejected
£0 and £1,000,000.01, impossible dates, blank descriptions, and invalid kinds
with actionable 400 responses. Missing and unknown workspace keys returned 401
and 404. A fresh private workspace and demo each returned 100/100 successful
fresh-connection reads; deleting the private workspace produced 404 on 20/20
follow-ups. These observations do not remove the scale/restart risk above.

## Privacy, security, and request limits — PASS except topology

- The entire core demo flow made same-origin requests only. There were no
  advertising, analytics, CDN, or other third-party runtime requests.
- No ordinary-route console errors or page errors occurred.
- HTML and API responses include a restrictive CSP with
  `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, strict-origin
  referrer policy, and a camera/microphone/geolocation permissions policy.
- HTML and API responses use `no-cache`; hashed JS/CSS use one-year immutable
  caching; unversioned images and fonts revalidate after one hour.
- An independent 200-request `POST /api/demo` burst from one forwarded client
  produced 47 HTTP 201 and 153 HTTP 429 responses in 8.4 seconds. Every 429 had
  `Retry-After: 1`. The configured allowance is a 40-request burst with one
  token every 50 ms (20/second); the observed run accepted 47 total.
- Source inspection confirms the limiter wraps every `/api` endpoint. `/health`
  is intentionally exempt.
- The product needs no sign-in, so the Entra tenant requirement is not
  applicable. It is not a PWA and makes no offline-use claim, so service-worker
  update/offline reload checks are not applicable.

## Accessibility, mobile, links, and performance — PASS

- The factory `verify-url.sh` passed: HTTP 200, title, `lang`, one H1, main
  landmark, zero missing image alt attributes, zero unlabeled buttons, and no
  console errors.
- Live axe scans of `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the real
  404 found zero violations at desktop and 390 px.
- Every route has `lang="en-GB"`, one H1, one main landmark, and a route-specific
  title. The unknown route returns HTTP 404.
- Keyboard Tab exposes the skip link with a 3 px visible brass focus ring;
  Enter opens the demo; route focus moves to the H1; transaction-dialog focus
  enters the first field and returns to the trigger on Escape.
- At 390 px there is no horizontal overflow, no undersized visible target, and
  the app controls and records stack intentionally. At 200% text there is no
  horizontal overflow.
- `prefers-reduced-motion: reduce` matches and leaves no active animation or
  transition.
- All discovered links resolve as expected. Internal pages are 200, the
  designed unknown route is 404, Sociobot is 200, and checkout is the expected
  303 to Dodo.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; LCP 1.80 s, total blocking time 80 ms, CLS 0, transfer 181,704 bytes.
- Production output: JS 33.90 kB raw / 11.05 kB gzip; CSS 18.13 kB raw /
  5.01 kB gzip; fonts 102,036 bytes total; hero 173,422 bytes. All budgets pass.

## Defects by severity

- **Critical:** live topology has two active revisions, allows three replicas,
  and lacks durable `/data` storage and `SQLITE_VFS=unix-dotfile`; three
  mandatory live claims fail.
- **High:** none beyond the critical deployment failure.
- **Medium:** none.
- **Low:** none.

## Required remediation

Restore one active and ready revision with `minReplicas=maxReplicas=1`, Azure
Files mounted at `/data`, and `SQLITE_VFS=unix-dotfile`. Then rerun all three
failed claim commands and verify the configuration survives a real revision
restart before release.

Evidence is in [`.factory/evidence/verification-16`](evidence/verification-16/).
