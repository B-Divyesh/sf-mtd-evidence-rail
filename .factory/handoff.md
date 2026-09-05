# Review 5 handoff

**Work order:** `mtd-evidence-rail-review-5`

**Date:** 5 September 2026 UTC

**Verdict:** **FAIL — 2 findings and 2 untested public claims**

## What was reviewed

The current venture milestone is M1. The deployed implementation is
`693a7609d2efb23c6567da5de0b425db92029e5c`; the documentation baseline reviewed
is `41a1e5262fdc5639ea907bfd4a776e35e4b27659`. No product source or deployment
input changed after the implementation candidate.

The live application completes the M1 evidence job. Fresh desktop and phone
browsers passed the one-click sample, realistic populated output, persistent
demo label, reset, private-state isolation, invalid-input recovery, CSV match
review, evidence export, keyboard, focus, 200% text, reduced motion, routes,
legal pages, designed 404, and axe checks.

The backend returned build `693a7609…`, used one replica with its `/data` mount,
kept workspace state across a product-only restart, separated two workspace
keys, retained deletion, and returned 429 with `Retry-After: 1` under load.
Local and live JS/CSS hashes match.

## Why the review failed

1. Three exact claim commands fail from a clean checkout at documentation HEAD.
   They expect `41a1e526…` to be deployed instead of resolving the last product
   implementation, `693a7609…`. The same probes pass when that implementation
   SHA is supplied, so this is a claims/release-identity regression rather than
   a broken live runtime.
2. `/terms` promises monthly renewal until cancellation and says billing terms
   appear before payment. Neither promise has a claim entry or test. The venture
   plan correctly says that renewal and cancellation remain unproved M2 work.

Full evidence and exact fixes are in [review-5.md](review-5.md).

## Verification summary

- All 26 declared claim commands were run literally: **23 pass, 3 fail**.
- `npm test`: **PASS**, 9 Rust and 25 Chromium tests.
- `npm run lint`: **PASS**.
- `npm run build`: **PASS**, with `dist/` produced.
- `cargo build --release --locked`: **PASS**.
- `npm audit --audit-level=high`: **PASS**, zero vulnerabilities.
- Live production-compatible Playwright: **24/24 pass**.
- Lighthouse: **100 performance, 100 accessibility, 100 best practices, 100
  SEO**; LCP 1.88 s, TBT 25 ms, CLS 0.
- Live restart/topology: **PASS** with 100/100 demo reads after restart.
- Live limiter: **PASS**; each 200-request demo wave returned 175 HTTP 429
  responses, all with `Retry-After: 1`.

## Next action

Keep product code unchanged until a repair work order. Then:

1. make live claim commands resolve the committed implementation SHA across
   later plan, handoff, report, evidence, and Graphify-only commits;
2. add a regression fixture for the current venture-plan descendant; and
3. remove or test the two unsupported billing statements on `/terms`.

After that repair, rerun all 26 exact commands from a clean checkout and repeat
the live identity, workspace, and rate-limit checks without an environment
override.

## Milestones and dependencies

- **M1:** implemented and healthy at runtime, but this review is not accepted
  while the claims gate fails.
- **M2:** not started. Sociobot Entra registration/test identities, a controlled
  billing lifecycle, and a fleet backup/restore drill remain external
  dependencies.
- **M3:** not started. Pilot users and a consented redacted CSV corpus remain
  external dependencies for matching and readiness validation.
- Dodo remains behind Sociobot only. Messaging and HMRC access are unavailable,
  not promised, and not required for these milestones.

No application source, runtime configuration, billing configuration, DNS, or
secrets were changed. The product's own existing revision was restarted only
to verify persistence. Pre-existing `graphify-out` working-tree changes were
left untouched.
