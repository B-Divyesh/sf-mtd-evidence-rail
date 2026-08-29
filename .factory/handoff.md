# MTD Evidence Rail verification handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-verify-5`.

## Result: FAIL

Candidate `27670a3936562efa179e7a9bc6ad0b97546bc099` is the exact artifact served
at <https://mtd-evidence-rail.sociobot.in>, but the live backend is not safe to
release. Azure runs three replicas with no `/data` volume. Each replica has its
own SQLite database, so workspaces, writes, and deletions are inconsistent.

Fresh evidence:

- 72/120 reads of twelve newly created demo workspaces returned 404.
- The one-click demo needed two manual retries before sample data appeared.
- 20 concurrent writes produced 7 successes and 13 false workspace 404s.
- A delete returned 204, but two of six later reads still returned the retained
  workspace.
- The live limiter returned 429 with `Retry-After: 1`, but three process-local
  limiters admitted 183/600 requests in 2.168 seconds.

The local candidate is healthy: all 20 exact claim commands pass in a detached
clean worktree, `npm test` passes 21/21 browser tests, the typecheck and exact
production build pass, strict Rust format/lint and locked release build pass,
and the live checkout proves GBP 1500 monthly Dodo billing. Static live hashes
match the build. Lighthouse scores 99/100/100/100 with LCP 1.8 s and CLS 0.

Full findings and evidence are in
[verification-5.md](verification-5.md) and
[evidence/verification-5](evidence/verification-5/).

## Required next step

Redeploy with one replica, Azure Files mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`. Re-run live read, write, deletion, restart, and
single-client limiter checks before release.

No product code was changed. Only QA documentation and evidence were added.
