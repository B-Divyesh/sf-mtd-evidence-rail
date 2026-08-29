# Review 1 handoff — FAIL

Completed 29 August 2026 for work order `mtd-evidence-rail-review-1`.

- Reviewed live URL: <https://mtd-evidence-rail.sociobot.in>
- Reviewed source commit: `d1470eb88c9c4964b357758b481381ca66feacbd`
- Live `/health` build: `8c2d0755f2ea2987332f1c97939c66bcb64ec56b`
- Result: **FAIL.** Full findings: [review-1.md](review-1.md).

No product code was modified. A fresh clean clone received `npm ci`; all 20
declared claim commands and the complete `npm test` suite passed (21
Playwright tests, Rust tests, typecheck, build, runtime and storage checks).
Live cold desktop/mobile, demo, reset, private-workspace separation, routing,
links, and request-log checks were also run.

The blocker is independently reproduced with an existing real subscription key:
opening `/demo` reads that real local-storage key, sends it to the
subscription API, and writes the real licence cache while demo is active. The
current demo-isolation test does not cover that state. The review also records
unlisted claims and plain-language copy fixes.

To verify a repair, open `/demo` in a browser seeded with real workspace,
licence, and licence-cache keys. Confirm none change, none reach demo request
headers, and no cross-origin request occurs. Then run `npm test` and every
command in `.factory/claims.json` from a clean clone.
