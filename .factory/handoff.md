# MTD Evidence Rail repair handoff

Completed 28 August 2026 for work order `mtd-evidence-rail-repair-2`.

## Result

**PASS — the verifier's release blocker is repaired.**

The failure in verifier commit
`9987438ec75bce0b47f5dc77e4b573daf5b5bf86` was reproduced in the live Azure
control plane. The generic final image rollout had removed the `/data` mount
and `SQLITE_VFS`, and had restored `maxReplicas: 3`. Requests could therefore
reach separate local SQLite files. The researched brief, visual system, product
flows, artifact class, and container deployment class are unchanged.

## Repair

- `scripts/deploy.sh` now verifies the active revision count as well as the
  mount, VFS, and replica limit after the factory image rollout.
- The deploy command now runs a mandatory data-plane smoke after applying that
  topology. Rollout fails if any demo or private workspace read fails.
- `scripts/verify-live-topology.sh` checks single revision mode, one active
  revision, `maxReplicas: 1`, `/data`, and `unix-dotfile`. It then requires
  100/100 fresh-connection reads for both a new demo and private workspace.
- `scripts/live-browser-smoke.mjs` requires 12/12 fresh Chromium contexts to
  load the one-click demo without any failed API response.
- `scripts/test-shared-storage.sh` is the exact local regression. Three server
  processes share one store and must return all 400 workspace reads before and
  after every process restarts.
- The shared-state behavior is listed in `.factory/claims.json` and the local
  regression is part of `npm test`.

## Local evidence

Commands run from a clean `npm ci` installation:

```sh
npm test
npm audit --audit-level=low
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release --locked
bash scripts/test-live-checkout.sh
```

Results:

- `npm ci`: 34 packages installed; 0 vulnerabilities.
- `npm test`: PASS — TypeScript, production build, 4 Rust tests, runtime with
  only `PORT`, restart persistence, the new three-process shared-store test,
  and 17 Chromium tests all passed.
- Shared-store regression: 100/100 private and 100/100 demo reads passed across
  three processes before restart; both sets passed again after restart.
- Playwright covered desktop, 390 px mobile, keyboard dialog focus and return,
  reduced-motion styling, privacy requests, deletion, export, paid/free limits,
  error recovery, and Axe checks on every route. No serious or critical Axe
  issue was found.
- Strict Clippy, Rust formatting, locked release compilation, npm audit, and
  the live hosted-checkout redirect passed.
- Factory URL verification against the local release found one `h1`, `en-GB`,
  `main`, complete image alternatives, labelled buttons, and no console error.
- Production bundles remain unchanged: 30,079 byte JS (10.26 kB gzip), 16,617
  byte CSS (4.73 kB gzip), 102,036 bytes of local fonts, and a 61,374 byte
  mobile hero.

## Deployment and live evidence

Repair implementation commit `a1ec54ab6050a875a8e769e0b76d224b84bdcd9a`
was built by ACR run `chpn` and deployed through `scripts/deploy.sh`. The final
handoff commit is deployed through the same command after this file is written.

- Azure reports single revision mode, one active revision, one replica,
  `maxReplicas: 1`, Azure Files mounted at `/data`, and
  `SQLITE_VFS=unix-dotfile`.
- Before a live revision restart, new private and demo keys each returned
  100/100 HTTP 200 reads over fresh connections.
- After restarting the live revision, those same keys again returned 100/100
  HTTP 200 reads. The saved workspaces therefore crossed a real restart.
- The browser deployment smoke passed 12/12 fresh demo contexts before and
  after restart. A second 12/12 smoke passed during initial deployment.
- The applicable live Playwright suite passed 15/15. It covered the core demo,
  capture, CSV matching, atomic rejection, date validation, evidence types and
  size boundary, export, deletion, free-limit enforcement, privacy, desktop
  routes, Axe, keyboard behavior, and 390 px layout.
- The factory URL verifier reported no console errors and passed title, `en-GB`,
  one `h1`, `main`, image alternatives, and labelled buttons.
- A 100-request fixed-client burst returned 11 HTTP 429 responses. Every
  limited response included `Retry-After: 1`; a separate client remains
  isolated by the forwarded first hop.
- CSP, `nosniff`, referrer policy, permissions policy, cache policy, HTTPS,
  internal routes, and the designed HTTP 404 response passed.
- Fresh mobile Lighthouse: performance 100, accessibility 100, best practices
  100, SEO 100; FCP 1.05 s, LCP 1.88 s, TBT 8 ms, CLS 0, and 180,619 bytes
  transferred.

## Applicability and known boundaries

This product is not a PWA and makes no offline claim, so service-worker update
tests do not apply. It has no account sign-in, package consumer, library, or CLI,
so identity-provider and package-consumer checks do not apply. Workspace-key
identity and isolation were exercised locally and live.

Docker and Podman are unavailable in this worker, so no local image build was
possible. ACR built the Dockerfile successfully from the source package without
`.git`. No card purchase was made; the hosted redirect and recorded valid
licence fixture cover both billing sides without spending. These are not release
blockers. SQLite must remain on the mounted Azure Files store with one replica;
the deployment smoke now enforces that requirement.

## Next step

No release-blocking work remains. Monitor Azure Files capacity and keep
`scripts/deploy.sh` as the final operation for future image rollouts.
