# Polish 1 — review finding closure

Source review: [review-1.md](review-1.md). Earlier `review-*` and `polish-*`
files were read; review 1 is the only review file and no earlier polish file
exists. All findings are closed.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Added `?demo=1`; demo skips all real licence capture, cache reads/writes, verification, and licence headers. The banner says changes stay in the 24-hour demo. | `@claim:demo-isolation` seeds real workspace, licence, and cache values; asserts they are unchanged after reset, no licence header exists, and every demo request is same-origin. Passed in fresh clone. Local screenshot: `.factory/evidence/polish-1/local-verify/screenshot-mobile.png`. Live check appended after deploy. |
| F-1-2 | Removed the untestable “does not file/calculate tax” promise from landing, README, terms, and export text. Replaced it with the demonstrated evidence-pack workflow. | `@claim:evidence-pack` passed in fresh clone; copy audit and source scan show no public HMRC/tax-filing promise. Live landing check appended after deploy. |
| F-1-3 | Replaced “Quarterly evidence, in order” with “Evidence for your MTD quarter”. | `release-blocking copy and 44px inline-link regressions stay fixed` passed. Local desktop screenshot: `.factory/evidence/polish-1/local-verify/screenshot-desktop.png`. |
| F-1-4 | Replaced “Bank lines” with the documented “Transactions” wording and retained one term throughout. | Copy regression test and `.factory/copy-audit.md` terminology table passed review. |
| F-1-5 | Replaced vague labels with “What this record tool does not do” and “Workspace privacy, export, and deletion”. | Copy regression test asserts both headings; axe route audit passed. |
| F-1-6 | Moved deployment-specific Azure/SQLite detail out of README. README now uses short product-facing sentences; handoff carries deployment detail. | `.factory/copy-audit.md` records no sentence over 22 words. Fresh-clone `npm test` passed. |
| F-1-7 | Removed the unproved README claim about the only external network destination. The remaining subscription behavior is covered by its own checkout and licence tests. | Fresh-clone `npm run test:live-checkout` passed (Dodo 303, GBP 1500 monthly); `@claim:license-return` and `@claim:no-trackers` passed. |

## Live evidence

Deployment and cold live re-check are recorded in the final handoff update.
