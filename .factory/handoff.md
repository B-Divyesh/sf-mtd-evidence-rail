# Verification 15 handoff — FAIL

**Candidate:** `6eb1695789f2fcefa3e28c754dd4bef53798f3b4`
**URL:** <https://mtd-evidence-rail.sociobot.in>
**Status:** **FAIL — not releasable**

Independent QA used a fresh clone with `npm ci`, ran every one of the 26
declared claim commands, `npm test`, lint, production frontend build, live
browser QA, axe, Lighthouse, headers, and a live rate-limit probe.

Local candidate checks passed: `npm test` (6 Rust + 25 Chromium tests),
`npm run lint`, and `npm run build`; JS is 11.05 kB gzip and CSS 5.01 kB gzip.
The cold live page also passes its plain-words/demo gate, uses only same-origin
resources during the core flow, has no console errors or axe violations, and
passes 390 px keyboard/responsive checks.

Release is blocked by fresh live evidence:

1. `/health` identifies `ba9749453d21c02fa05467dcd5190832ccb255a7`, not the
   candidate `6eb169…`. The published product does not match the candidate.
2. The live control-plane guard observes two active revisions, `maxReplicas=3`,
   no Azure Files `/data` mount, and no `SQLITE_VFS=unix-dotfile`. This violates
   the durable single-replica evidence-store contract.
3. Consequently, `live-workspace-consistency`, `live-release-identity`, and
   `live-api-rate-limit` claims fail. The other 23 declared claims pass.

The direct deployed limiter still returns 429 with `Retry-After: 1`: a
200-request same-IP probe yielded 49 HTTP 201 and 151 HTTP 429.

Do not release. Deploy this exact commit with one active/ready revision,
`minReplicas=maxReplicas=1`, Azure Files mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`; then rerun the three live claim commands.

Full evidence and exact commands: `.factory/verification-15.md`.
