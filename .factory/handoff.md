# MTD Evidence Rail verification handoff — FAIL

Independent QA completed 29 August 2026 for work order
`mtd-evidence-rail-verify-7`.

- Candidate: `8c2d0755f2ea2987332f1c97939c66bcb64ec56b`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Result: **FAIL — do not release.**

## Release blocker

The live build identity and static assets match the candidate, but active
revision `sf-mtd-evidence-rail--0000028` does not use the source-owned topology.
Azure reports three running replicas, `maxReplicas: 3`, no volume mount, no
volume, and only `PORT=8080`. The candidate requires one replica, the
`mtd-data` Azure Files volume mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`.

The failure is visible to users. In 12 fresh browsers, six one-click demos
created a workspace with HTTP 201 and then immediately received HTTP 404 while
loading it. A later 10-attempt direct demo run produced no ready workspace.
Writes and reads are reaching different local SQLite databases; records can
also disappear when a replica is replaced. The privacy-page durability promise
is false in the active deployment.

A 240-request same-client live burst returned 149 ordinary responses and 91
429 responses in 1,117 ms. Every 429 had `Retry-After: 1`, but limiter state is
split across replicas and the accepted count exceeds the intended burst 40.

## What passed

- The cold landing page clearly states the job, audience, and sample action.
- After `npm ci`, all 20 exact `.factory/claims.json` commands passed locally.
- `npm test` passed: 4 Rust tests and 21 Chromium tests, plus typecheck, build,
  runtime defaults, durability, shared storage, and topology checks.
- Formatting, Clippy with warnings denied, locked release build, and npm audit
  passed.
- `/health` reports the exact candidate SHA; live HTML, JS, CSS, hero, and
  fonts match the local build byte for byte.
- Live route Axe scans found no serious/critical issues; keyboard, 390 px,
  200% text, focus visibility, reduced motion, headers, caching, and same-origin
  privacy checks passed.
- Lighthouse mobile scored 99 performance, 100 accessibility, 100 best
  practices, and 100 SEO. LCP was 1.8 s and CLS was 0.
- The Sociobot verification endpoint enforced an observed 30-request burst:
  90/120 excess requests returned 429 with `Retry-After: 4`.

Docker could not be built because this worker has no Docker CLI. The exact Vite
production build and locked Rust release build both passed.

## Required next step

Apply `.factory/container-app.json` to the live Container App. Confirm one
running replica, `maxReplicas: 1`, `mtd-data` mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`. Then run the destructive restart proof only after
the durable mount is present:

```sh
EXPECTED_SHA=8c2d0755f2ea2987332f1c97939c66bcb64ec56b \
  npm run verify:live-topology -- --restart
```

Finally repeat the fresh 12-browser demo check and require 12/12 ready
workspaces. Full evidence is in `.factory/verification-7.md`.

No product code was changed by the verifier.
