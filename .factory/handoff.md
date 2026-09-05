# Verification 22 handoff

**Work order:** `mtd-evidence-rail-verify-22`

**Date:** 5 September 2026 UTC

**Milestone:** M1 — evidence pack core; independent acceptance failed on live
release identity

**Implementation reviewed:** `f87a563751c31cd5ca612f396d86c59c6c5d76b9`

**Clean documentation checkout tested:** `aafbf2ca327191b19f670303b1c0fd7450bd8410`

**Supplied tested documentation baseline:** `bc7c440f961bec611820c35b4faae5e7382e354d`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

## Outcome

**FAIL — 1 high finding, 0 untested claims.**

The public service now reports build/image `aafbf2ca…` on revision `0000075`,
not recorded implementation `f87a563…` on revision `0000074`. Consequently
the exact `live-workspace-consistency`, `live-release`, and `live-rate-limit`
claim commands fail their identity guard. This is a release-control finding,
not a product-code defect.

The `f87a563…` to `aafbf2c…` diff is limited to reports, release/plan text, and
Graphify output. Live JS and CSS hashes match the candidate build. Diagnostics
using the observed wrapper SHA passed topology, workspace consistency,
rate-limit, browser, and restart checks.

Full report: [verification-22.md](verification-22.md).

## Verification completed

- Fresh desktop and phone first screens showed the job, audience, sample
  action, and three facts before scrolling.
- One-click demo loaded 6 transactions, 4 linked files, and 2 missing items.
- Persistent demo wording, reset, fresh-key behavior, same-origin traffic, and
  private/subscription storage isolation passed.
- Normal £0.01 capture, invalid £0 recovery, invalid CSV recovery, likely-match
  skip, export, evidence boundaries, deletion, key recovery, and two-workspace
  separation passed.
- A product-only restart retained 100/100 demo reads and retained deletion for
  20/20 reads. Twelve fresh browsers loaded before and after restart.
- The current runtime is one replica with Azure Files at `/data` and
  `SQLITE_VFS=unix-dotfile`.
- Three 200-request diagnostic waves returned 176, 176, and 175 HTTP 429s,
  every one with `Retry-After: 1`.
- Live production-compatible Playwright passed 26/26. Axe found zero
  violations across root, demo, app, legal, and designed 404 routes.
- URL checks passed root and demo with no console errors.
- Lighthouse scored 100 performance, accessibility, best practices, and SEO;
  LCP was 1.9 s and transfer was 181,690 bytes.
- Clean `npm test`, lint, build, locked Rust release build, and high-severity
  npm audit passed.
- Every earlier review and verification finding, including minor accessibility,
  copy, cache, HSTS, and 404 findings, is dispositioned in the report.

Evidence is under `/work/.evidence/verification-22`.

## Claims

All 26 declared commands were run literally from the clean checkout after
`npm ci`:

- 23 passed;
- 3 failed on the same live identity mismatch; and
- 0 public claims remain untested or unlisted.

The current-wrapper diagnostics prove the three underlying runtime behaviors,
but do not waive their failed declared commands.

## Required next step

Restore the recorded `f87a563…` image as the ready product image, or accept and
record a different implementation through the normal release process. Then
rerun:

```sh
npm run test:live-workspace-consistency
npm run test:live-release
npm run test:live-rate-limit
```

No product-code repair is indicated by this verification.

## External dependencies

- M2 accounts and tenant ownership still require Sociobot Entra registration
  and test identities.
- M2 paid-service acceptance still requires controlled purchase, renewal,
  cancellation, expiry, and revocation proof.
- M2 backup acceptance still requires a fleet backup and isolated restore
  drill; restart persistence is not a backup.
- M3 validation still requires pilot users and a consented redacted CSV corpus.
- HMRC filing, certification, tax advice, payroll, and full accounting remain
  out of scope.

Pre-existing `graphify-out` working-tree changes remain untouched and
uncommitted.
