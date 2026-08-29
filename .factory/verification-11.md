# Independent product verification 11 — FAIL

Verified 29 August 2026 for work order
`mtd-evidence-rail-verify-11`.

- Candidate: `18eed3f094ec7fe6be543898646a2ab8acf61c90`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — do not release**

The source candidate is buildable and its local product tests pass. The exact
candidate image is also live. Production is nevertheless running up to three
replicas with no durable volume, while the application uses process-local
SQLite and a process-local rate limiter. The one-click demo failed in every
fresh browser tested, new workspaces were usually missing on the next request,
and the documented API limit accepted all 200 requests. Both corresponding
live claims fail.

## Mandatory first read and demo gate

The cold first screen itself passes the plain-word test:

- What: “Link each expense to evidence.”
- Who: “For UK sole traders, tutors, and small club operators preparing an MTD
  quarterly update.”
- First action: “Try it with sample data,” with the adjacent explanation “See a
  ready quarter. Changes stay in this 24-hour demo.”

The candidate still fails the mandatory demo gate. **Eight of eight** fresh
Playwright contexts clicked that action and reached:

```text
The quarter could not load.
This workspace was not found. Start a new workspace. Try again
```

Each attempt recorded `POST /api/demo` = 201 followed by
`GET /api/workspace` = 404. The shipped 12-context live browser smoke also
failed waiting for the sample. On a separate attempt, **Try again** loaded the
six sample records, but saving a valid £12.34 expense then returned 404. The
recovery therefore only changes which replica answers; it does not make the
workspace reliable.

## Release-blocking defects

### Critical — live workspaces are split across ephemeral replicas

Fresh Azure control-plane evidence for revision
`sf-mtd-evidence-rail--0000042` showed:

```text
image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:18eed3f094ec
active revisions mode: Single
min/max replicas: 1/3
current replicas after load: 3
containers: 1
volume mounts: null
volumes: null
environment: PORT=8080 only
```

This contradicts the committed contract of exactly one replica, an Azure Files
mount at `/data`, and `SQLITE_VFS=unix-dotfile`. It also contradicts the live
privacy statement that the service keeps a private workspace in durable
storage and the README statement that production uses one app instance.

The exact clean-checkout claim command failed:

```text
$ npm run test:live-workspace-consistency
private read 2 returned 404, expected 200
```

An independent fresh-connection sample quantified the split:

| New workspace | HTTP 200 | HTTP 404 |
| --- | ---: | ---: |
| Private, 100 reads | 36 | 64 |
| Demo, 100 reads | 35 | 65 |

This breaks the real job: record capture, evidence linking, CSV import, export,
workspace recovery, deletion, and persistence cannot be trusted. No production
restart was initiated because verification is read-only; the absent mount is
already conclusive evidence that state will not survive replica replacement.

### Critical — deployed API does not enforce its documented allowance

The exact live claim failed twice, including from the detached clean checkout:

```text
$ npm run test:live-rate-limit
Live limiter accepted all 200 requests from one forwarded client.
```

All 200 fresh HTTP/1.1 `POST /api/demo` requests with the same first
`X-Forwarded-For` hop returned 201. No response returned 429 or
`Retry-After`. The observed live allowance is therefore at least 200 requests
in the measured burst, not the documented 40-request process burst.

The in-process Rust test passes and returns 429 with `Retry-After: 1`, showing
that the source limiter exists. The three live replicas multiply and fragment
that process-local state. The separate Sociobot subscription-verification
endpoint behaved correctly: 100 concurrent invalid checks returned 30 HTTP 200
and 70 HTTP 429 responses, with `Retry-After: 4` on every 429.

## Claims gate

`.factory/claims.json` exists with 25 entries. A detached worktree at the exact
candidate was clean before installation. After `npm ci`, every listed command
was run exactly; logs are retained under
`/tmp/mtd-clean-verify-11.kq7YDe/clean-claim-*.log` in this verifier container.

**23 passed:** `demo-isolation`, `no-account`, `workspace-key-recovery`,
`workspace-key-auth`, `quarter-capture`, `csv-matching`, `atomic-import`,
`calendar-dates`, `evidence-types`, `missing-review`, `demo-sample`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit`.

**2 failed:** `live-workspace-consistency` and `live-api-rate-limit`, with the
exact evidence above. A literal pre-install invocation in the supplied clone
could not find `tsc` or `vite`; the locked install completed normally, and the
prepared clean-checkout results above are the product results.

Every claim id has exactly one `@claim:<id>` test marker or dedicated command.
The landing page and README claims map to manifest entries. The durable-storage,
production-topology, and rate-limit statements are listed claims but are false
for the active deployment.

## Clean install, tests, lint, and production build

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — typecheck, Vite build, 4 Rust tests, runtime/storage/topology checks, 25 Chromium tests |
| `npm run lint` | PASS — TypeScript, rustfmt, Clippy with warnings denied |
| `npm run build` | PASS — produced `dist/` |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |

Docker/Podman is not installed in the verifier image, so a container build was
not available. The Dockerfile uses the required `rust:1-slim` builder, accepts
`BUILD_SHA`, and runs as a non-root user.

## Functional and boundary coverage

The clean local suite exercised the smallest useful product end to end:

- created a private workspace without sign-in, copied its 64-character key,
  rejected a wrong key, and restored the same record with the right key;
- recorded income and an expense in their dated MTD quarter;
- reviewed a two-row bank CSV, skipped one amount/date match, and imported the
  new row;
- rejected an atomic import containing one impossible date and retained the
  original six rows;
- rejected `2026-99-99`, accepted PDF/JPG/PNG/WebP/text evidence at exactly
  5 MiB, and rejected 5 MiB + 1 byte with 413;
- filtered exactly two missing-evidence records and exported a ZIP containing
  `transactions.csv` and linked files;
- enforced the free 25-record boundary locally and required a recorded valid
  subscription verdict for record 26;
- deleted a workspace and confirmed its key returned 404;
- preserved state across restart and across three local processes sharing one
  durable store.

In the live browser, zero amount produced “Enter an amount greater than zero,”
malformed CSV headings produced a clear corrective error, and a valid CSV
showed the expected match review. The subsequent valid save failed with the
split-workspace 404, so a live end-to-end success was not possible.

## Candidate and deployment identity

- Local `HEAD` was exactly `18eed3f094ec7fe6be543898646a2ab8acf61c90`.
- Live `/health` returned HTTP 200 with that exact full SHA.
- The active image tag is the candidate's 12-character SHA.
- Local and live SHA-256 hashes matched byte for byte:
  - `index.html`: `c081753c7178e2ada3c32abd386e6dfdc3cf6987806b8a0b47ce894a951421d2`
  - JavaScript: `0341ff815d5f6132b26b4a5a3243aaf47d178a01306c5d5282a82468b67d344b`
  - CSS: `ec6e1655c444db5663d63fd2ee6d86e66c881e1d3d9efdc7f066832210a3f991`

The failures belong to this candidate's active deployment, not stale frontend
or backend code.

## Privacy, headers, caching, and links

The cold page and attempted demo/retry flow made only same-origin requests; no
advertising request, third-party script, or CDN font was observed. The only
documented cross-origin runtime path is the explicit Sociobot checkout/license
flow. Cold landing had no console or page errors. Failed demo API calls emitted
the expected browser 404 resource errors.

HTML, `/health`, and API responses send a restrictive CSP including
`frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`,
`Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive
`Permissions-Policy`. HTML and API responses use `Cache-Control: no-cache`;
hashed JS/CSS use `public, max-age=31536000, immutable`. All landing links
resolved successfully; the checkout returned the expected 303 to Dodo.

## Accessibility, responsive behavior, and performance

- `/opt/fleet/lib/verify-url.sh`: PASS — title, `en-GB`, one H1, main landmark,
  image alt text, labelled buttons, and zero cold-load console errors.
- Playwright Axe: zero violations on live `/`, `/privacy`, `/terms`, the real
  404, and a demo after retry; therefore zero serious/critical findings.
- At 390 px there was no horizontal overflow and no visible interactive target
  below 44×44 px. The skip link was first in the tab order and had a visible
  3 px brass outline with a dark halo.
- Reduced-motion emulation left no non-zero animation or transition. The local
  suite also passed dialog focus return and 200% text resizing.
- Root, legal routes, and the designed 404 each have one H1 and one main
  landmark. The 404 document naturally logs its HTTP 404 resource message but
  has no page exception.

Lighthouse wrote a complete mobile report (the CLI emitted a post-collection
tab-crash notice): performance 100, accessibility 100, best practices 100, SEO
100; FCP 1.1 s, LCP 1.7 s, TBT 60 ms, CLS 0, total transfer 177 KiB. Production
assets are within budget: JavaScript 33,893 bytes raw / 11,046 gzip, CSS 18,132
raw / 5,010 gzip, fonts 102,036 total, mobile hero 61,374 bytes, and desktop
hero 173,422 bytes.

This product is not a PWA and registers no service worker, so offline reload
and service-worker update checks do not apply. It is not a library or CLI. It
does not require sign-in, so the Entra authority requirement does not apply.
The brief does not need an AI feature; the useful implied import, match, export,
and recovery steps are present rather than replaced with an AI stub.

## Required remediation

1. Apply and retain the committed one-replica Azure Files topology: max replica
   1, `/data` mounted from `mtd-data`, and `SQLITE_VFS=unix-dotfile`. Alternatively
   move state and rate limiting to genuinely shared services.
2. Prove new private and demo workspaces with 100/100 fresh-connection reads,
   normal browser writes, and reads after a revision restart.
3. Prove a single forwarded client receives 429 with `Retry-After` after the
   documented allowance in production.
4. Rerun all 25 claims and the fresh one-click demo gate before release.
