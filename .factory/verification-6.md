# Independent product verification 6 — FAIL

Verified 29 August 2026 for work order `mtd-evidence-rail-verify-6`.

- Candidate: `27670a3936562efa179e7a9bc6ad0b97546bc099`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Artifact: web with backend
- Result: **FAIL — the active Azure topology does not exactly match the source-owned deployment contract, and the repository's live topology verifier rejects it.**

This is a deployment-contract failure, not a recurrence of verification 5's
data-loss failure. The active service is now one replica with an Azure Files
mount at `/data`; fresh workspace reads and normal user flows work. However,
the source contract and verifier require the volume identifier `data`, while
the active revision uses `mtd-data`. The product's own live verifier only
accepts the former, so the candidate cannot pass its stated live-deployment
quality gate until source and deployment are reconciled.

## Release-blocking finding

### High — source-owned topology and active Azure revision drift

The candidate's `.factory/container-app.json` requires:

```json
{"volumeName":"data","mountPath":"/data"}
```

and a volume named `data` backed by `mtd-evidence-rail-data`. The active
revision `sf-mtd-evidence-rail--0000025` instead reports:

```json
{"volumeName":"mtd-data","mountPath":"/data"}
```

with Azure Files storage `mtd-evidence-rail-data`. It otherwise has the
correct topology: `Single` active-revisions mode, min/max replicas `1/1`, one
running replica, one container, and `SQLITE_VFS=unix-dotfile`.

`npm run verify:live-topology` was run against the live service. Its
`assert_control_plane` predicate selects only `volumeName == "data"`, so the
observed revision has `mount=` and `volume=:` from that predicate and the
command exits as unsafe after polling. This is also a direct mismatch with the
candidate manifest, even though the live mount path itself is functional.

Required release action: apply the source-owned topology so the active volume
is named `data`, or change the manifest and verifier together to the deployed
identifier after confirming that is the factory's canonical configuration.
Re-run `npm run verify:live-topology` successfully before release.

## Mandatory cold-read and demo gate

**PASS.** In a new browser context at 1440x900, the first screen says:

- what: “Link each expense to evidence”;
- who: “sole traders who need a reviewable record before each MTD quarterly
  update”; and
- first action: visible “Try it with sample data”, with “See a ready quarter.
  Nothing is saved.”

The one-click `/demo` flow loaded the persistent demo banner, showed the
missing-evidence queue, and exported `evidence-pack-2026-27-Q1.zip` with `PK`
signature. At 390px, Enter on the primary action reached `/demo`; there was no
horizontal overflow.

## Claims gate — clean candidate checkout

Created a detached clean clone at the exact candidate, ran `npm ci` (34
packages, 0 audit vulnerabilities), then executed every command declared in
`.factory/claims.json` exactly. **All 20 passed.**

`demo-isolation`, `no-account`, `quarter-capture`, `csv-matching`,
`atomic-import`, `calendar-dates`, `evidence-types`, `missing-review`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit` all passed. The live checkout assertion observed a `303` to
Dodo for product `mtd-evidence-rail`, GBP minor amount `1500`, cadence
`monthly`.

## Build and automated quality checks

| Check | Result |
| --- | --- |
| `npm test` | PASS — 4 Rust tests and 21 Chromium tests |
| `npm run build` | PASS — emits `dist/` |
| `tsc --noEmit` | PASS (via `npm test`) |
| `cargo fmt -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm audit --audit-level=low` | PASS — 0 vulnerabilities |
| Docker image build | Not run: Docker CLI is unavailable in this verifier container |

The production bundle is within budget: JS 30,362 bytes raw / 10,312 gzip,
CSS 16,961 bytes raw / 4,795 gzip, total self-hosted fonts 102,036 bytes, and
the mobile hero is 61,374 bytes.

## Live identity, backend behaviour, and privacy

- `/health` returned `{"build_sha":"27670a3936562efa179e7a9bc6ad0b97546bc099","status":"ok"}`.
- Live JS and CSS SHA-256 values exactly matched the clean candidate build.
- Twelve new demo workspaces all returned 201; 120 fresh-connection reads
  across them returned **120/120 HTTP 200**. This confirms that verification
  5's three-isolated-replica failure is no longer present.
- A fresh private workspace created a 64-character key; invalid
  `2026-99-99` returned `400 Enter a real calendar date`; a valid income record
  appeared in Q1; unconfirmed delete returned 400; confirmed delete returned
  204 and the next read returned 404.
- An 80-request concurrent single-client limiter probe produced 49 ordinary
  unauthenticated 401 responses and 31 `429` responses. Every sampled 429 had
  `Retry-After: 1` (observed burst allowance: 49 requests in this external
  probe).
- Demo load, missing-evidence review, and ZIP export made requests only to
  `https://mtd-evidence-rail.sociobot.in`; no trackers, third-party scripts,
  or CDN fonts were observed. No console/page errors occurred on a normal cold
  landing load.
- Responses send CSP with `frame-ancestors 'none'`, `nosniff`, strict referrer
  policy, permissions policy, and no-cache HTML/API; hashed JS/CSS are
  immutable for one year and the hero image revalidates hourly.

No sign-in exists, so the Entra tenant requirement does not apply. This is not
a PWA, library, or CLI; service-worker and consumer-package checks are not
applicable.

## Accessibility and interaction

Playwright axe scans of `/`, `/demo`, `/privacy`, `/terms`, and the designed
404 found zero serious or critical violations. Each had one `<h1>` and one
`<main>`. Keyboard testing confirmed the skip link is first, Enter launches
the demo, and mobile has no overflow. Reduced-motion emulation reported no
active animation or transition. The test suite also covers dialog focus return,
200% text size, and 44px navigation targets.

No product code was modified during verification.
