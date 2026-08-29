# Independent product verification 7 — FAIL

Verified 29 August 2026 for work order `mtd-evidence-rail-verify-7`.

- Candidate: `8c2d0755f2ea2987332f1c97939c66bcb64ec56b`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — the live deployment has three isolated, ephemeral SQLite
  stores. The one-click demo and ordinary workspace reads fail across replicas,
  and the live topology contradicts the candidate's durability contract.**

This is fresh evidence against the candidate currently reported by `/health`.
It is not the obsolete volume-name mismatch from verification 6. The source now
has the correct contract, but that contract was not applied to the active
revision.

## Release-blocking finding

### Critical — live records are split across three ephemeral replicas

The source-owned `.factory/container-app.json` requires one replica, an Azure
Files volume named `mtd-data` mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`. Azure reported this active state instead:

```text
revision: sf-mtd-evidence-rail--0000028
active revisions mode: Single
min/max replicas: 1/3
running replicas observed after load: 3
containers: 1
environment: PORT=8080 only
volumeMounts: null
volumes: null
```

The three live replica names were
`sf-mtd-evidence-rail--0000028-66f5c5654-7fz46`,
`sf-mtd-evidence-rail--0000028-66f5c5654-rvhpr`, and
`sf-mtd-evidence-rail--0000028-66f5c5654-xm87j`.

This is user-visible. In 12 simultaneous fresh 390 px browser contexts, every
landing-page demo click received `201` from `POST /api/demo`, but 6 of the 12
immediate `GET /api/workspace` requests returned `404`. The page showed “The
quarter could not load. This workspace was not found.” A later ten-attempt
direct `/demo` probe produced 0 ready workspaces. A single captured failure was:

```text
POST /api/demo      201  demo:8d6a...ee4
GET  /api/workspace 404  This workspace was not found. Start a new workspace.
```

The write landed on one replica and the read landed on another. The same defect
applies to private records and evidence. Because `/data` is not mounted, a
revision restart can also discard data. The live privacy statement “The service
keeps your private workspace in durable storage” is therefore false.

The rate limiter is split too. A 240-request concurrent probe from one
`X-Forwarded-For` address completed in 1,117 ms with 149 ordinary `401`
responses and 91 `429` responses. Every 429 had `Retry-After: 1`, but 149
accepted requests substantially exceeds the intended burst 40 plus 20/second
refill. The local single-process claim test correctly accepts 40 and rejects
request 41.

The repository's `verify:live-topology` gate was started with the exact expected
SHA. It remained in its topology polling phase for more than seven minutes
because the live state never matched, so it was stopped and each control-plane
predicate was checked directly with bounded Azure CLI reads. No production
restart was performed after discovering that storage is ephemeral.

Required release action: apply `.factory/container-app.json` to the active
Container App, confirm one running replica, `maxReplicas: 1`, the `mtd-data`
Azure Files volume at `/data`, and `SQLITE_VFS=unix-dotfile`, then run:

```sh
EXPECTED_SHA=8c2d0755f2ea2987332f1c97939c66bcb64ec56b \
  npm run verify:live-topology -- --restart
```

The release gate must also repeat the 12-browser one-click demo probe with
12/12 successes.

## Mandatory first-read and demo gate

The cold first screen itself **passes** the plain-word test:

- What: “Link each expense to evidence.”
- Who: “For sole traders who need a reviewable record before each MTD quarterly
  update.”
- First action: “Try it with sample data,” with “See a ready quarter. Nothing is
  saved.”

The visible action reaches `/demo` with one keyboard or pointer activation.
However, the demo as a job flow **fails** because 6/12 fresh clicks immediately
lost their newly created workspace, as documented above. The mandatory
one-click demo gate therefore fails.

## Claims gate

`.factory/claims.json` exists and lists 20 claims. The supplied clone initially
had no installed Node development binaries, so literal pre-install invocations
of browser/build claims exited 127. After the required `npm ci` from the
lockfile (34 packages, zero audit vulnerabilities), every exact command from
the manifest passed:

| Claim | Clean installed candidate |
| --- | --- |
| `demo-isolation` | PASS |
| `no-account` | PASS |
| `quarter-capture` | PASS |
| `csv-matching` | PASS |
| `atomic-import` | PASS |
| `calendar-dates` | PASS |
| `evidence-types` | PASS |
| `missing-review` | PASS |
| `evidence-pack` | PASS |
| `workspace-delete` | PASS |
| `free-limit` | PASS |
| `paid-limit` | PASS |
| `hosted-checkout` | PASS |
| `license-return` | PASS |
| `no-trackers` | PASS |
| `runtime-defaults` | PASS |
| `durable-storage` | PASS |
| `shared-state-boundary` | PASS |
| `production-topology` | PASS |
| `api-rate-limit` | PASS |

The local claims prove the candidate source. They do not rescue the release:
the live deployment independently fails the demo, durable-storage,
shared-state, production-topology, and effective shared-rate-limit behavior.

The live checkout claim observed the Dodo-hosted session for product
`mtd-evidence-rail`, GBP 1500, monthly cadence, without completing payment.
The Sociobot product verification endpoint was also probed with 120 invalid
read-only requests: 30 returned the normal invalid verdict and 90 returned 429;
every 429 included `Retry-After: 4`.

## Build and automated checks

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 34 packages, 0 vulnerabilities |
| `npm test` | PASS — typecheck, production build, 4 Rust tests, runtime/durability/shared-storage/topology scripts, 21 Chromium tests |
| `npm run build` | PASS — emitted `dist/` |
| `cargo fmt -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |
| Docker image build | Not run — Docker CLI is unavailable in this verifier container |

## Candidate identity and live delivery

- `/health` returned
  `{"build_sha":"8c2d0755f2ea2987332f1c97939c66bcb64ec56b","status":"ok"}`.
- Live `index.html`, JS, CSS, hero, and all three font files matched the local
  production build byte for byte by SHA-256.
- Normal cold landing load produced no console or page errors. The broken demo
  emits the expected network console error for its API 404.
- `/`, `/demo`, `/app`, `/privacy`, and `/terms` return 200. An unknown route
  returns the designed page with HTTP 404.
- HTML/API responses use `no-cache`; hashed JS/CSS use one-year immutable
  caching; the unversioned hero and fonts use one-hour revalidation.
- Responses include the restrictive CSP with header-only `frame-ancestors
  'none'`, `nosniff`, strict referrer policy, and camera/microphone/geolocation
  denial.

## Accessibility, mobile, privacy, and performance

- Live Axe scans of `/`, `/demo`, `/privacy`, `/terms`, and the designed 404
  found zero serious or critical violations. The local full suite found zero
  Axe violations.
- Every checked route has `lang="en-GB"`, one `<h1>`, one `<main>`, and a
  route-specific title.
- At 390 px there was no horizontal overflow. The first focus target is “Skip
  to main content”; after activation, the next Tab is the first main action.
  The sample action is keyboard reachable and has a designed 3 px brass focus
  ring with a dark 5 px surround. Visible controls measured at least 44 px.
- Simulated 200% text produced no horizontal overflow. Reduced-motion
  emulation found zero active animations or transitions.
- Cold landing and demo attempts requested only
  `https://mtd-evidence-rail.sociobot.in`; no advertising tracker, CDN font, or
  third-party script ran. Subscription verification occurs only on the user's
  explicit restore/return flow.
- Lighthouse mobile: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 1.1 s, LCP 1.8 s, TBT 0 ms, CLS 0, speed index 1.1 s.
- Production JS is 30,362 bytes raw / 10,296 gzip; CSS is 16,961 bytes raw /
  4,790 gzip; fonts total 102,036 bytes; the mobile hero is 61,374 bytes.
  These are within the stated budgets.

There is no sign-in, so the Entra tenant requirement does not apply. This is
not a PWA, library, or CLI, so service-worker and clean-consumer checks do not
apply. No AI feature is necessary for the brief.

No product code was modified during verification.
