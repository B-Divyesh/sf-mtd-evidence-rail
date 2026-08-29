# Polish 3 — cumulative adversarial finding closure

Source reviews: `review-1.md`, `review-2.md`, and `review-3.md`. Earlier
closure records `polish-1.md` and `polish-2.md` were rechecked. The product
release is `ba9749453d21c02fa05467dcd5190832ccb255a7`; the committed release
manifest is in repository commit `5cd292faf18e0894c06e3fdbb7823296b074a544`.

## Review 1 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Demo mode uses only the `demo:` session key. It never reads, writes, or sends private workspace or subscription state. The persistent banner states the 24-hour boundary and offers Reset. | Clean clone `@claim:demo-isolation`; live `@claim:demo-isolation` and `@claim:no-trackers`; [live demo screenshot](evidence/polish-3/live-demo/screenshot-mobile.png); cold URL `https://mtd-evidence-rail.sociobot.in/?demo=1`. |
| F-1-2 | Untestable HMRC filing and tax-calculation promises remain removed. Copy describes organising evidence and exporting the tested pack. | Clean clone `@claim:evidence-pack`; `release-blocking copy and 44px inline-link regressions stay fixed`; cold [landing screenshot](evidence/polish-3/live-root/screenshot-mobile.png). |
| F-1-3 | The first-screen label remains “Evidence for your MTD quarter”. | Copy regression test; cold live landing screenshot. |
| F-1-4 | “Transaction” remains the single term for financial records. | Copy regression test and the terminology table in `copy-audit.md`. |
| F-1-5 | The headings name their content: “What this tool covers” and “Workspace privacy, export, and deletion”. | Live route axe sweep and copy regression test. |
| F-1-6 | Removed the returned deployment jargon from README. Internal mount, locking, revision, and limiter detail is kept in `handoff.md`. | README source audit; clean-clone `npm run lint`; `copy-audit.md` has no sentence over 22 words or banned term. |
| F-1-7 | The broad network-only promise remains absent. Demo traffic and hosted checkout are separate observable claims. | Clean clone `@claim:no-trackers` and `npm run test:live-checkout`; checkout returned Dodo HTTP 303, GBP 1500, monthly. |

## Review 2 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-2-1 | Production remains Single revision, one running replica, with Azure Files mounted at `/data`; startup rejects container-local Azure storage. | Deployment revision `sf-mtd-evidence-rail--0000051`; clean clone `production-topology`, `shared-state-boundary`, and `live-workspace-consistency`; deploy passed 100/100 private and 100/100 demo reads before restart, then 100/100 demo reads after restart. |
| F-2-2 | Demo phones show a compact 6-transaction summary and “Teaching card supplies” before the toolbar. | `390px mobile and keyboard paths meet interaction requirements`; [live demo mobile screenshot](evidence/polish-3/live-demo/screenshot-mobile.png). |
| F-2-3 | Landing, README, and brief use “UK sole traders, tutors, and small club operators”. | Copy regression test and cold live landing screenshot. |
| F-2-4 | The unproved “every quarter” heading remains replaced by “Monthly subscription limits”. | Copy regression test and cold live landing check. |
| F-2-5 | Refund wording remains removed; the page says checkout opens on Dodo through Sociobot. | `@claim:hosted-checkout`; live HTTP 303 to Dodo with monthly GBP 1500 product. |
| F-2-6 | Every private route requires a strict 64-character hexadecimal workspace key and rejects missing or unknown keys. | Clean clone `@claim:workspace-key-auth`; 6/6 Rust tests. |
| F-2-7 | The vague CSP sentence remains removed. Routes load without console errors and server headers are tested. | Live `verify-url.sh` reports zero errors for `/` and `/?demo=1`; `routes set titles, canonical URLs, focus, legal links, and a real 404`; Rust 404/header regression. |
| F-2-8 | Unlisted container UID and build-SHA README statements remain removed. The startup statement is limited to its tested behavior. | Clean clone `@claim:runtime-defaults`; successful multi-stage ACR build. |
| F-2-9 | The sample claim records all three counts and Reset restores them. | Clean clone and live `@claim:demo-sample`: 6 transactions, 4 linked files, 2 missing items. |
| F-2-10 | README describes the tested restart outcome instead of an unproved storage layout. | Clean clone `@claim:durable-storage`; deploy restart retained the same demo for 100/100 reads. |
| F-2-11 | The section remains “What this tool covers” with direct evidence and export wording. | Copy regression test and live landing screenshot. |
| F-2-12 | README explains temporary request blocking and the first forwarded IP in plain words. | Clean clone `@claim:api-rate-limit`; deployment probes returned 101/240 and 97/240 HTTP 429 responses, all with `Retry-After: 1`. |
| F-2-13 | The subscription action remains “Open £15/month checkout”. | Copy regression test and `@claim:hosted-checkout`. |
| F-2-14 | Users can copy a private workspace key and open the same records on another device, with key warnings and invalid-key feedback. | Clean clone `@claim:workspace-key-recovery` and `@claim:workspace-key-auth`. |

## Review 3 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-3-1 | Added `.factory/release.json`. Live workspace checks read its published product revision instead of assuming later review-only HEAD is deployed. | Exact clean-clone `npm run test:live-workspace-consistency` passed without overrides and returned 200 on 100/100 private plus 100/100 demo reads. |
| F-3-2 | The same manifest is the committed source of truth for health and ready-image identity. A regression fixture proves the default manifest path and still rejects stale releases. | Exact clean-clone `npm run test:live-release` matched manifest, `/health`, image `ba9749453d21`, ready revision `0000051`, and safe topology. |
| F-3-3 | The live limiter command uses the manifest guard, then performs its declared 200-request probe. | Exact clean-clone `npm run test:live-rate-limit` passed without overrides: 92 HTTP 429 responses, each with `Retry-After: 1`. |
| F-3-4 | Renamed the demo banner action from “Start for real” to “Start a private workspace” everywhere. | `@claim:demo-isolation` asserts the link text and target; [live demo screenshot](evidence/polish-3/live-demo/screenshot-mobile.png). |

## Final acceptance evidence

- Every one of the 26 exact commands in `claims.json` passed from clean clone
  `5cd292faf18e0894c06e3fdbb7823296b074a544` without an identity override.
- Clean-clone `npm test` passed 6 Rust tests and 25/25 Chromium tests.
- Clean-clone `npm run lint` and `npm run build` passed. The build is 11.05 kB
  JavaScript gzip and 5.01 kB CSS gzip.
- Live Playwright axe found zero violations on `/`, `/?demo=1`, `/app`,
  `/privacy`, `/terms`, and the designed HTTP 404. Route titles, canonical URLs,
  H1 focus, Back navigation, legal links, keyboard use, and 390 px layout passed.
- Live `verify-url.sh` found one H1, `lang=en-GB`, a main landmark, complete alt
  text, labelled buttons, and zero console errors on `/` and `/?demo=1`.
- Live Lighthouse: performance 99, accessibility 100, best practices 100, SEO
  100, LCP 1.9 s, CLS 0, and 177 KiB total transfer. Report:
  `evidence/polish-3/lighthouse-live.json`.

No finding from any review remains open.
