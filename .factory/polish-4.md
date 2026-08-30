# Polish 4 — cumulative adversarial finding closure

Source reviews: `review-1.md` through `review-4.md`. Earlier closure records:
`polish-1.md` through `polish-3.md`. Published product source:
`0719e6274bebc8e6333b4f0dad2b079295eed953`.

## Review 1 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Demo mode still uses only its `demo:` session key. It skips private workspace and subscription storage, licence headers, and cross-origin verification. Reset provisions a fresh 24-hour sample. | `@claim:demo-isolation`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); cold `/?demo=1` retained seeded private values, sent same-origin requests only, and showed Reset plus Start a private workspace. |
| F-1-2 | HMRC filing and tax-calculation promises remain absent. Copy describes only the tested evidence-pack job. | `release-blocking copy and 44px inline-link regressions stay fixed` and `@claim:evidence-pack`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` contained neither removed promise. |
| F-1-3 | The first-screen label remains “Evidence for your MTD quarter”. | `release-blocking copy and 44px inline-link regressions stay fixed`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` showed the label above the H1. |
| F-1-4 | “Transaction” remains the single term for a financial line. | Copy regression test and `copy-audit.md`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` used “Transactions, invoices, and receipts”. |
| F-1-5 | Section headings remain “What this tool covers” and “Workspace privacy, export, and deletion”. | Copy regression test plus route axe sweep; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` headings matched. |
| F-1-6 | Removed the returned Azure revision, container filesystem, topology, managed-identity, and management-API prose. README now says only that deployment stops when shared storage is unavailable; internals are in `handoff.md`. | Copy regression test and `copy-audit.md`; [root desktop](evidence/polish-4/live-root/screenshot-desktop.png); live `/` remained unchanged because this is documentation-only. |
| F-1-7 | The broad network-destination promise remains absent. Demo privacy and hosted checkout remain separate tested claims. | `@claim:no-trackers` and `npm run test:live-checkout`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); cold `/?demo=1` used same-origin requests only. |

## Review 2 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-2-1 | Production remains one active revision and one running replica with Azure Files mounted at `/data`. | `@claim:production-topology`, `@claim:shared-state-boundary`, and `npm run test:live-workspace-consistency`; [demo desktop](evidence/polish-4/live-demo/screenshot-desktop.png); live build `0719e62` returned 100/100 private and 100/100 demo reads before and after restart. |
| F-2-2 | Demo phones retain the compact 6-transaction quick look and named “Teaching card supplies” result before the toolbar. | `390px mobile and keyboard paths meet interaction requirements`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); cold `/?demo=1` placed the named result inside 844 px. |
| F-2-3 | Landing, README, and brief still use “UK sole traders, tutors, and small club operators”. | Copy regression test and `copy-audit.md`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` showed the full audience. |
| F-2-4 | The unproved “every quarter” wording remains absent; the heading is “Monthly subscription limits”. | Copy regression test; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` showed the replacement. |
| F-2-5 | Refund wording remains absent. Checkout copy names Dodo through Sociobot. | `npm run test:live-checkout`; [root desktop](evidence/polish-4/live-root/screenshot-desktop.png); live checkout returned Dodo HTTP 303, GBP 1500, monthly. |
| F-2-6 | Every private route still requires a valid 64-character workspace key. | `@claim:workspace-key-auth`; [demo desktop](evidence/polish-4/live-demo/screenshot-desktop.png); live `/app` recovery flow and protected API checks passed. |
| F-2-7 | The vague CSP sentence remains absent. Security headers are response headers and routes load without console errors. | `routes set titles, canonical URLs, focus, legal links, and a real 404` plus Rust header regression; [root verify](evidence/polish-4/live-root/verify.json); cold `/` had zero console errors. |
| F-2-8 | Unlisted container UID and prose build-SHA promises remain absent. Runtime copy states only the behavior its fixture proves. | `@claim:runtime-defaults`; [root desktop](evidence/polish-4/live-root/screenshot-desktop.png); live `/health` returned published SHA `0719e62`. |
| F-2-9 | The one-click sample still asserts all three counts before and after Reset. | `@claim:demo-sample`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); live `/?demo=1` showed 6 transactions, 4 linked files, and 2 missing items. |
| F-2-10 | README continues to state the tested restart outcome rather than a storage-layout claim. | `@claim:durable-storage`; [demo desktop](evidence/polish-4/live-demo/screenshot-desktop.png); deployment restart retained the demo for 100/100 reads. |
| F-2-11 | The scope section still says “What this tool covers” and uses evidence, transaction, and export wording. | Copy regression test; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` matched the audited copy. |
| F-2-12 | README keeps the plain two-sentence request-limit explanation. | `@claim:api-rate-limit` and `npm run test:live-rate-limit`; [root desktop](evidence/polish-4/live-root/screenshot-desktop.png); live `/api/demo` returned 175/200 HTTP 429s in each wave, all with `Retry-After: 1`. |
| F-2-13 | The action remains “Open £15/month checkout”. | Copy regression test and `npm run test:live-checkout`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); cold `/` showed the action and live checkout reached Dodo. |
| F-2-14 | Users can still copy a private workspace key and reopen the same records on another device, with warnings and invalid-key feedback. | `@claim:workspace-key-recovery` and `@claim:workspace-key-auth`; [root mobile](evidence/polish-4/live-root/screenshot-mobile.png); live `/` recovery flow passed. |

## Review 3 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-3-1 | Live workspace checks continue to read the committed published source instead of assuming later evidence-only HEAD is deployed. | `npm run test:live-workspace-consistency`; [demo desktop](evidence/polish-4/live-demo/screenshot-desktop.png); live build `0719e62` passed 100/100 private and demo reads. |
| F-3-2 | The release-neutral allowlist now accepts numbered review, verification, and polish reports plus their nested evidence. A fixture reproduces `.factory/verification-19.md` and `.factory/evidence/verification-19/claims/01.log`; product and deployment changes still fail. | `npm run test:published-source-guard` and `npm run test:live-release`; [root verify](evidence/polish-4/live-root/verify.json); live `/health`, ready image, and revision all identify `0719e62`. |
| F-3-3 | The live limiter command still uses the manifest guard and completes all three 200-request waves. | `npm run test:live-rate-limit`; [demo desktop](evidence/polish-4/live-demo/screenshot-desktop.png); live `/api/demo` produced 175 limited responses per wave with `Retry-After: 1`. |
| F-3-4 | The demo action remains “Start a private workspace”. | `@claim:demo-isolation`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); cold `/?demo=1` showed the result-naming action. |

## Review 4 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-4-1 | Deleted the vague comparison claiming demo creation had a “stricter” limit. | Copy regression test asserts the phrase is absent; [root desktop](evidence/polish-4/live-root/screenshot-desktop.png); live `/` has no unlisted comparison. |
| F-4-2 | Replaced “browser and database namespace” with “Demo keys and data are kept separate from private workspaces.” | Copy regression test and `@claim:demo-isolation`; [demo mobile](evidence/polish-4/live-demo/screenshot-mobile.png); cold `/?demo=1` proved the separation with seeded private state. |

## Release evidence

- `/opt/fleet/lib/verify-url.sh` passed `/` and `/?demo=1`; both reports show
  one H1, `lang=en-GB`, a main landmark, complete alt text, labelled buttons,
  and zero console errors.
- Live Playwright passed all 24 production-applicable tests, including axe on
  `/`, `/demo`, `/app`, `/privacy`, `/terms`, and the designed HTTP 404. The
  local-only paid-limit test uses its declared recorded server fixture.
- [Lighthouse](evidence/polish-4/lighthouse-live.json): performance 100,
  accessibility 100, best practices 100, SEO 100, LCP 1.8 s, CLS 0, total
  blocking time 0 ms, and 177 KiB transferred.
- The deployment verifier passed 12/12 fresh demo contexts before and after a
  real revision restart, persistent deletion, and one shared limiter.

No finding from reviews 1–4 remains open.
