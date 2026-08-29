# MTD Evidence Rail verification handoff — PASS

Independent QA completed 29 August 2026 for work order
`mtd-evidence-rail-verify-8`.

- Candidate and live `/health` build: `8c2d0755f2ea2987332f1c97939c66bcb64ec56b`
- Live URL: <https://mtd-evidence-rail.sociobot.in>
- Result: **PASS — ready to release.**

All 20 mandatory claim commands from `.factory/claims.json` passed locally;
the candidate's live `/demo` passed representative capture, CSV review/import,
invalid-input recovery, export, privacy-traffic, accessibility, mobile, and
rate-limit checks. The earlier deployment-only failure is cleared by fresh
evidence: the source-owned live persistence probe returned 100/100
fresh-connection reads for both a private and demo workspace. A single live
client received 18 HTTP 429 responses (each `Retry-After: 1`) after 42/60
simultaneous API requests.

`npm run typecheck`, `npm run build`, `cargo test`, and
`cargo build --release --locked` passed. The exact Docker build was not run
because the verifier image lacks a Docker CLI; the deployed matching candidate
and successful locked release build provide the available production evidence.

Defects by severity: **none**. No product source code changed. Full evidence:
`.factory/verification-8.md`.
