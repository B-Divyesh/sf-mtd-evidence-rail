# Independent product verification 12 — FAIL

Verified 29 August 2026 for work order
`mtd-evidence-rail-verify-12`.

- Requested candidate: `d596c1f0daac52b65205c2dbf3527d7e834d5bb3`
- Only published source commit tested: `b5debe5ffa3e7c02831716cbf39f97897fa04879`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Live `/health` build: `ad6d58e426159625d16419f45d861dbf2167c5ed`
- Azure image tag: `sociobotregistry.azurecr.io/sf-mtd-evidence-rail:b5debe5ffa3e`
- Artifact: web with backend
- Result: **FAIL — do not release**

## Release decision

The requested candidate cannot be verified. It is absent from the clone and
from every advertised remote ref. A direct GitHub commit lookup returns HTTP
422, “No commit found for SHA.” The live health identity is a third SHA, while
the Azure resource names the base SHA. Neither identifies the requested
candidate.

Two mandatory commands from `.factory/claims.json` also fail. Production is
configured for up to three replicas with no volume or `/data` mount. Two
revisions are active, and the revision receiving all traffic is reported
unhealthy. The service stores financial records in SQLite, so the declared
topology cannot guarantee persistence after replacement or scaling. A passing
UI sample at one moment does not repair this storage boundary.

Any missing or failing claim is release-blocking under the acceptance
contract. These failures are fresh and replace the earlier deployment PASS.

## Mandatory first-read and demo gate

The cold first screen passes:

- What: “Link each expense to evidence.”
- Who: “For UK sole traders, tutors, and small club operators preparing an MTD
  quarterly update.”
- First action: “Try it with sample data,” followed by “See a ready quarter.
  Changes stay in this 24-hour demo.”

The action is visible without scrolling at 1440×900 and 390×844. It opens a
seeded demo in one click. Twelve simultaneous fresh Chromium contexts loaded
the six sample transactions successfully. The demo banner says that sample
changes remain in the 24-hour demo and provides Reset demo and Start for real.

## Critical findings

### 1. The requested candidate is unavailable and is not the live build

Fresh identity evidence:

```text
git cat-file -t d596c1f0...       fatal: object is unavailable
git fetch origin d596c1f0...      remote: not our ref
GitHub commits/d596c1f0...        HTTP 422, No commit found for SHA
git ls-remote origin              main = b5debe5ffa3e...
live /health                      ad6d58e426159...
Azure image tag                   b5debe5ffa3e
```

The live HTML, JavaScript, and CSS do byte-match a production build of the only
published source commit, `b5debe5...`, but that does not establish equivalence
to the missing candidate. Their SHA-256 hashes are:

```text
index.html  c081753c7178e2ada3c32abd386e6dfdc3cf6987806b8a0b47ce894a951421d2
JavaScript  0341ff815d5f6132b26b4a5a3243aaf47d178a01306c5d5282a82468b67d344b
CSS         ec6e1655c444db5663d63fd2ee6d86e66c881e1d3d9efdc7f066832210a3f991
```

The candidate therefore fails the required source/deployment identity check.

### 2. Mandatory live claims fail on unsafe production topology

Both exact manifest commands failed:

```text
npm run test:live-workspace-consistency  FAIL
npm run test:live-rate-limit             FAIL

Unsafe live topology: mode=Single min=1 max=3 containers=1
mount= volume=: vfs= active=2 running=1
```

A separate Azure control-plane read confirmed:

```text
active revisions mode: Single
minimum / maximum replicas: 1 / 3
configured environment: PORT=8080 only
volume mounts: null
volumes: null

sf-mtd-evidence-rail--0000044  active, Healthy,   traffic 0,   replicas 1
sf-mtd-evidence-rail--0000045  active, Unhealthy, traffic 100, replicas 1
```

This contradicts the listed production-topology claim, README, privacy text,
and prior handoff promise of one replica with durable Azure Files at `/data`
and `SQLITE_VFS=unix-dotfile`. It also shows that the claimed startup guard is
not protecting the current mountless deployment: the service is answering
requests despite the unsafe shape.

Current requests happened to stay on one serving instance: a newly created
private workspace and demo each returned 100/100 successful fresh-connection
reads, and 12/12 fresh browser demos loaded. This does not prove restart
survival. No production restart was performed because verification is
read-only and the absent mount is already conclusive.

## Claims gate

`.factory/claims.json` exists with 25 entries. Each id has exactly one claim
marker or dedicated claim command. Every listed command was run from a clean
detached worktree after a locked dependency install at the only available
source commit.

**23 passed:** `demo-isolation`, `no-account`, `workspace-key-recovery`,
`workspace-key-auth`, `quarter-capture`, `csv-matching`, `atomic-import`,
`calendar-dates`, `evidence-types`, `missing-review`, `demo-sample`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit`.

**2 failed:** `live-workspace-consistency` and `live-api-rate-limit`. Both
stopped at their mandatory topology precondition with the evidence above.

The hosted-checkout claim returned HTTP 303 to a Dodo session for product
`mtd-evidence-rail`, product id `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly.
No purchase was completed.

The landing page and README claims map to manifest entries. No additional
unlisted visitor-facing capability claim was found.

## Install, tests, lint, and production build

These results apply to published commit `b5debe5...`, not the missing candidate:

| Command | Result |
| --- | --- |
| `npm ci --include=dev` | PASS — 34 packages, 0 vulnerabilities |
| All 25 exact claim commands | **23 PASS / 2 FAIL live gates** |
| `npm test` | PASS — TypeScript, Vite, 6 Rust tests, runtime/storage/topology scripts, 25 Chromium tests |
| `npm run lint` | PASS — TypeScript, rustfmt, Clippy with warnings denied |
| `npm run build` | PASS — `dist/` produced |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |

Docker and Podman are absent, so a local container build could not be run. The
Dockerfile was inspected: it uses separate Node and `rust:1-slim` builders,
accepts `BUILD_SHA`, runs as non-root UID 10001, exposes 8080, and contains no
`.git` dependency.

## Functional and boundary evidence

The local suite passed the complete product flow. A separate live run passed
24 of its 25 scenarios. The only failure used the local recorded token
`fixture-valid-license` against the real billing service and correctly got
HTTP 402; that fixture-only case is not evidence of a live paid subscription.

A fresh live UI flow proved:

- the demo loaded six transactions and filtered exactly two missing items;
- amount zero showed “Enter an amount greater than zero,” then £0.01 saved;
- an unsupported evidence MIME returned 415 with a corrective message, then a
  text file linked successfully;
- malformed CSV headings showed the required Date/Description/Amount guidance;
- a corrected two-row CSV skipped one likely match and imported one new row;
- export downloaded `evidence-pack-2026-27-Q1.zip` with a `PK` signature;
- every core-flow request was same-origin and sent no subscription header.

Fresh API boundary checks accepted £0.01, £1,000,000, 120 description
characters, 40 category characters, and the 5 MiB evidence boundary. They
rejected £1,000,000.01, 121 description characters, `2026-02-29`, and 5 MiB +
1 byte with clear 400/413 responses. An atomic mixed-validity import retained
the original count. Twenty simultaneous writes all returned 201 and the next
read contained all 20. Deletion returned 204 and the same key then returned
404.

Local runtime tests started the service with only `PORT`, preserved a
workspace across restart, and returned 400/400 successful reads across three
processes sharing one data directory.

## Rate limiting and concurrency

- In-process API test: PASS; the configured client burst is 40, with a
  20-request/second refill, and limited responses include `Retry-After: 1`.
- Fresh fast live burst: 200 requests from one forwarded client produced 47
  HTTP 201 and 153 HTTP 429 responses in 7.9 seconds. Every 429 had
  `Retry-After: 1`. The observed allowance was 47 accepted requests before and
  during the measured burst.
- Sociobot product verification: 100 concurrent invalid-token calls produced
  30 HTTP 200 and 70 HTTP 429 responses. Every 429 had `Retry-After: 4`; the
  observed allowance was 30.
- Health load smoke: 100/100 returned HTTP 200 and the same `ad6d58e...` build.

The application limiter works on the currently serving process. The mandatory
live limiter claim remains failed because a process-local limiter cannot meet
its declared one-limiter bound while production permits three replicas and the
test correctly rejects that topology before sending traffic.

## Accessibility, mobile, keyboard, and motion

- `/opt/fleet/lib/verify-url.sh` passed both `/` and `/?demo=1`: HTTP 200,
  descriptive title, `en-GB`, one H1, one main landmark, complete image alt
  text, labelled buttons, and zero cold-load console errors.
- Playwright Axe reported zero violations on `/`, demo, `/app`, `/privacy`,
  `/terms`, and the real 404. The matrix was repeated at desktop and 390 px.
- Every route had one H1, one main landmark, its own title, and zero horizontal
  overflow. The 404 returned HTTP 404 with a designed recovery link.
- At 390 px, tested navigation/footer targets were at least 44×44 CSS px. At
  200% text size, document width remained 390 px with no overflow.
- The first Tab focused the skip link. Its 3 px brass outline was visible;
  Enter moved focus to the H1. Keyboard focus on the sample action had the same
  designed ring, and Enter opened the demo. Dialog Escape returned focus to
  its trigger.
- With `prefers-reduced-motion: reduce`, no non-zero animation, transition, or
  smooth scrolling remained.
- Normal route loads had no console or page errors. The deliberate 404 and 415
  negative tests produced only their expected browser resource messages.

## Privacy, headers, caching, and links

The observed landing and complete demo workflow loaded only product-origin
resources. Fonts and imagery are self-hosted. The only documented external
runtime paths are explicit checkout and subscription verification through
`api.sociobot.in`; the demo sent neither a licence header nor a cross-origin
request.

HTML, health, and API responses send the restrictive CSP (including header-only
`frame-ancestors 'none'`), `X-Content-Type-Options: nosniff`,
`Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive
Permissions Policy. HTML/API use `Cache-Control: no-cache`; hashed JS/CSS use
one-year immutable caching; unversioned images/fonts use one-hour
`must-revalidate`. All crawled links resolved, with the checkout producing its
expected 303 redirect to Dodo. `robots.txt` and the five-route sitemap return
200.

No service worker or Cache Storage entry exists. The product does not claim to
be a PWA, so offline reload and service-worker update checks do not apply. It is
not a library or CLI. Sign-in is not required, so the Entra authority check is
not applicable. The brief's useful import, matching, export, and recovery steps
are present; an AI feature is not necessary for the stated job.

## Performance and bundle budgets

Fresh mobile Lighthouse produced a complete report before its known
post-collection tab-crash exit:

- performance 100, accessibility 100, best practices 100, SEO 100;
- FCP 0.989 s, LCP 1.905 s, TBT 44 ms, CLS 0;
- total transferred bytes 181,650 (177.4 KiB).

Production assets remain inside the contract budgets:

- JavaScript: 33,893 bytes raw / 11,046 bytes gzip;
- CSS: 18,132 bytes raw / 5,010 bytes gzip;
- fonts: 102,036 bytes total;
- mobile hero: 61,374 bytes; desktop hero: 173,422 bytes.

## Product and documentation review

The smallest useful product matches the brief: receipt/evidence capture,
dated income/expense timeline, bank CSV matching, missing-evidence queue, and
quarter ZIP export. It does not claim to file with HMRC or provide tax advice.
The design file records a product-specific paper-moon evidence railway system,
palette, local type, spacing, motion, and generated-art provenance. README,
MIT licence, privacy, terms, demo documentation, copy audit, empty/error states,
and keyboard/mobile behavior are present.

## Required remediation

1. Publish the exact candidate commit and deploy an immutable image that
   reports that full SHA from `/health`.
2. Restore and retain one production replica, one Azure Files volume mounted
   at `/data`, and `SQLITE_VFS=unix-dotfile`; remove stale active revisions and
   require the traffic revision to be healthy.
3. Prove private/demo data through a production revision restart, then rerun
   both mandatory live claim commands until they pass.
4. Rerun all 25 claim commands and the cold one-click demo gate from a clean
   checkout of the exact published candidate.
