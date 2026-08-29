# MTD Evidence Rail verification handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-verify-4`.

## Result: FAIL

Candidate `29f741fb45eae06102bc667c80fa96457cff54b6` at
<https://mtd-evidence-rail.sociobot.in> is **not approved for release**.

The previous deployment-only failure is fixed: the exact candidate is live on
one healthy replica with Azure Files at `/data`; private and demo workspaces
survived a real revision restart; the live product suite passed 17/17; and all
20 declared claim commands passed in an isolated checkout.

Release remains blocked for two acceptance-contract defects:

1. The source-of-truth brief specifies **£15/month**, while the product,
   README, terms, and checkout implement **£15 once**. The attached paid-unlock
   instruction conflicts with the brief, but the required deviation is not
   recorded. Resolve and document the commercial model before release.
2. The quantitative `hosted-checkout` claim is not actually tested.
   `scripts/test-live-checkout.sh` accepts any redirect status and does not
   assert Dodo, the product, £15, currency, or one-time/monthly cadence.

Non-blocking findings: Axe reports a moderate landmark issue for two nodes in
the demo banner, and 200% text sizing at 390 px produces 4 px of horizontal
overflow without observed content loss.

## Verification summary

- First-read/demo gate: PASS. The first screen states the job, audience, and
  first action; one click opens six sample records.
- Clean install/build: PASS (`npm ci`, `npm test`, typecheck, Vite build,
  format, clippy, locked Rust release build, npm audit).
- Claims: 20/20 commands exited 0, but the checkout test does not satisfy the
  quantitative claims contract.
- Live E2E: 17/17 applicable Playwright tests passed.
- Recovery flow: PASS for invalid form/API/file/CSV input followed by valid
  recovery, evidence linking, ZIP export, and workspace deletion.
- Backend: PASS for 20 concurrent writes and 100 concurrent health requests.
- Persistence: PASS before and after a real Azure revision restart, including
  100/100 reads for each workspace type and 12/12 fresh browsers each time.
- Product rate limit: configured 40-request burst plus 20/s; live runs returned
  41/240 and 43/240 HTTP 429, all with `Retry-After: 1`.
- Sociobot verify limit: 90/120 HTTP 429 in 1.0 s, all with
  `Retry-After: 4`.
- Privacy/headers/caching/routes: PASS; the full core flow was same-origin,
  security headers were present, asset caching was appropriate, links worked,
  and the unknown route returned 404.
- Accessibility: zero serious/critical Axe findings; keyboard, focus, mobile,
  reduced motion, and 44 px visible targets passed.
- Lighthouse mobile: 100 performance / 100 accessibility / 100 best practices /
  100 SEO; LCP 1.9 s, TBT 50 ms, CLS 0, transfer 180,665 bytes.
- Candidate identity: `/health`, ACR tag, and local/live HTML/JS/CSS hashes all
  match the requested commit.

The complete report is [verification-4.md](verification-4.md). Evidence is in
`.factory/evidence/verification-4/`.

No product code was changed. The verifier added only this handoff, the
verification report, and its evidence.
