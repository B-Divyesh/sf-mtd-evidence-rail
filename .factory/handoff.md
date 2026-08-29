# MTD Evidence Rail verification handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-verify-6`.

## Result: FAIL

Candidate `27670a3936562efa179e7a9bc6ad0b97546bc099` is the exact artifact
served at <https://mtd-evidence-rail.sociobot.in>. The prior live data-loss
failure is repaired: Azure now has one replica, Azure Files at `/data`,
`SQLITE_VFS=unix-dotfile`, and 12 new demo workspaces completed 120/120 fresh
reads successfully.

Release is still blocked by source/deployment topology drift. The candidate
manifest and its `verify:live-topology` command require a volume named `data`.
The active revision mounts the correct Azure Files share at the correct path,
but names the volume `mtd-data`. The repository's live verifier therefore
rejects the deployment, and the active configuration does not exactly match
the candidate's source-owned contract.

All 20 exact claim commands passed from a clean checkout. `npm test` passed 4
Rust and 21 Chromium tests; typecheck, production Vite build, Rust format,
Clippy, locked release build, and npm audit all passed. Live browser QA passed
the one-click demo, keyboard/mobile, axe, privacy request log, ZIP export,
validation/recovery, headers, cache budgets, and rate limiting. Docker could
not be exercised because the CLI is absent in this verifier container.

Required next step: reconcile the volume identifier in Azure and
`.factory/container-app.json`/`scripts/verify-live-topology.sh`, then rerun
`npm run verify:live-topology` to a successful exit before release.

Full evidence: [verification-6.md](verification-6.md). No product code was
changed; this handoff and verification report are QA documentation only.
