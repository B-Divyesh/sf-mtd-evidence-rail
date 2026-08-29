# Polish 2 — cumulative adversarial finding closure

Source reviews: `review-1.md` and `review-2.md`. Source polish record:
`polish-1.md`. All current and earlier findings were rechecked against build
`70822dc371f3a07bbf7cb0b91b6b60c889ad89f7` on 29 August 2026.

## Review 1 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Demo mode still bypasses every private workspace, subscription key, cache read/write, and licence header. Reset creates a new `demo:` key. | Clean clone `@claim:demo-isolation`; live seeded check in `evidence/polish-2/live-audit.json`; live screenshot `evidence/polish-2/live-demo/cold-mobile.png`; `/?demo=1` had same-origin requests only, no licence header, and unchanged sentinel private state. |
| F-1-2 | The untestable HMRC filing and tax promises remain absent. Copy describes the tested evidence-pack workflow. | Clean clone `@claim:evidence-pack`; live removed-copy audit in `evidence/polish-2/live-audit.json`; cold `/` check. |
| F-1-3 | The first-screen label remains the useful “Evidence for your MTD quarter”. | `release-blocking copy and 44px inline-link regressions stay fixed`; live `/` screenshot `evidence/polish-2/live-root/screenshot-mobile.png`. |
| F-1-4 | “Transaction” remains the single term for financial lines. | Copy regression test; terminology table in `copy-audit.md`; live `/` check. |
| F-1-5 | The sections now say “What this tool covers” and “Workspace privacy, export, and deletion”. | Copy regression test; zero-violation route axe test; live `/` check. |
| F-1-6 | README deployment text remains short and plain; operational detail is in this handoff. | `copy-audit.md`; full clean-clone claim log `evidence/polish-2/clean-claims.log`. |
| F-1-7 | The broad network-destination promise remains removed. Demo privacy and checkout behavior use separate, observable claims. | Clean clone `@claim:no-trackers` and `@claim:hosted-checkout`; live demo request audit in `live-audit.json`. |

## Review 2 findings

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-2-1 | Deployment enforces Single revision mode, one replica, and the Azure Files volume at `/data`. A public claim now requires 100/100 reads for both fresh private and demo keys. | `@claim:production-topology`, `@claim:shared-state-boundary`, and `@claim:live-workspace-consistency`; `evidence/polish-2/live-topology.log` records 100/100 private, 100/100 demo, 12/12 browser contexts, deletion, and shared limiter checks. The same demo key passed 100/100 after a real revision restart during deploy. Live `/health` reported `70822dc371f3a07bbf7cb0b91b6b60c889ad89f7`. |
| F-2-2 | Demo phones show a compact six-transaction summary and “Teaching card supplies” above the toolbar. The masthead is shortened only in demo mode. | `390px mobile and keyboard paths meet interaction requirements`; live sample bottom was 344.53 px in an 844 px viewport (`live-audit.json`); screenshot `live-demo/cold-mobile.png`. |
| F-2-3 | The landing, README, brief, and copy audit use “UK sole traders, tutors, and small club operators”. | Live audience assertion in `live-audit.json`; cold `/` screenshot; `brief.json` and README source check. |
| F-2-4 | Removed the unproved “every quarter” heading. It now says “Monthly subscription limits”. | Copy regression test; live removed-copy assertion in `live-audit.json`. |
| F-2-5 | Refund wording was removed. The page now says “Checkout opens on Dodo through Sociobot.” | Clean clone `@claim:hosted-checkout`; live `/` copy audit. |
| F-2-6 | Added strict 64-hex-character key parsing and valid, missing, and unknown-key checks for every private route. Unknown keys can no longer return success from workspace deletion. | Clean clone `@claim:workspace-key-auth`; Rust deletion regression; full `npm test`. |
| F-2-7 | Removed the vague CSP sentence instead of making an unproved security promise. Existing response-header behavior remains covered. | Route/title/metadata test, Rust header test, and cold live root with zero console errors in `live-audit.json` and `live-root/verify.json`. |
| F-2-8 | Removed the unlisted container UID and build-SHA statements. The remaining startup statement is narrowed to the service behavior its test observes. | Clean clone `@claim:runtime-defaults`; successful Azure ACR multi-stage build during deployment. |
| F-2-9 | Registered one sample-composition claim and asserted all three counts before and after reset. | Clean clone `@claim:demo-sample`: six transactions, four linked files, two missing items; live demo screenshot. |
| F-2-10 | Replaced the unproved SQLite layout statement with the tested restart outcome. | Clean clone `@claim:durable-storage`; deploy restart retained the demo for 100/100 reads (`live-topology.log`). |
| F-2-11 | Rewrote the mismatched section as “What this tool covers”, “Organise evidence before you file”, and direct evidence/export copy. | Copy regression test, `copy-audit.md`, and live `/` check. |
| F-2-12 | Replaced proxy jargon with two plain sentences about temporary request blocking and the first forwarded IP. | Clean clone `@claim:api-rate-limit`; live `79/240` requests returned 429 within one-limiter bounds in `live-topology.log`. |
| F-2-13 | Renamed the action to “Open £15/month checkout”. | Copy regression test and clean clone `@claim:hosted-checkout`; live `/` check. |
| F-2-14 | Added “Copy workspace access key” in settings and “Open an existing workspace” on the first screen, with warnings, invalid-key feedback, focus handling, and cross-device restoration. | Clean clone `@claim:workspace-key-recovery` and `@claim:workspace-key-auth`; live recovery record and input-focus assertions in `live-audit.json`. |

## Cumulative release evidence

- Full local `npm test`: four Rust tests, runtime/storage/topology scripts, and
  25/25 Chromium tests passed.
- Every exact command in `claims.json` passed independently from fresh clone
  commit `70822dc`; see `evidence/polish-2/clean-claims.log`.
- Playwright axe found zero violations on `/`, `/?demo=1`, `/app`, `/privacy`,
  `/terms`, and the designed 404.
- `verify-url.sh` passed cold live `/` and `/?demo=1`: one H1, `lang=en-GB`,
  main landmark, complete alt text, and zero console errors.
- Live Lighthouse report: performance 100, accessibility 100, best practices
  100, SEO 100, LCP 1.9 s, CLS 0, total transfer 177 KiB. Report:
  `evidence/polish-2/lighthouse-live.json`.
- Live route audit confirms route-specific titles/canonicals, 200 responses,
  legal links, forward/Back H1 focus, and a designed HTTP 404. See
  `evidence/polish-2/live-audit.json`.

No finding of either review remains open.
