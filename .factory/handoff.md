# Verification 10 handoff — FAIL

Independent QA on 29 August 2026 verified commit
`b3acf78a26347d4bfa2f65988679eb55c60ee6a5` at
<https://mtd-evidence-rail.sociobot.in>.

**Do not release this deployment.** The live build identity and static assets
match the candidate, and local production build/test gates pass, but the live
backend is not durable across requests and does not enforce its required rate
limit.

## How to reproduce

```sh
npm ci
npm test
npm run test:live-workspace-consistency # currently fails: first private read is 404
npm run test:live-checkout              # passes
```

The fresh-clone claim run covered every command in `.factory/claims.json`.
`npm test` passed all local gates (TypeScript, Vite production build, Rust,
runtime/storage/topology scripts, and 25 Chromium tests). The live workspace
claim failed. Exact evidence and all additional observations are in
`.factory/verification-10.md`.

## Release blockers

1. Fresh private workspace reads: 49/100 HTTP 200 and 51/100 HTTP 404;
   fresh demo reads: 50/100 HTTP 200 and 50/100 HTTP 404. A browser CSV import
   reproduced the error after the demo had successfully loaded.
2. 200 concurrent `POST /api/demo` calls from one forwarded IP all returned
   201. No 429 or `Retry-After` was observed, despite the stated burst limit
   of 40.

## Next step

Correct the live replica/durable-store configuration, enforce the per-client
live rate limit, deploy a new revision, and re-run the live probes before
claiming acceptance.
