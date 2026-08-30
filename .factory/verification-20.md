# Verification 20 — FAIL

- **Candidate:** `43e060d81ab9d97443928a8548c840a97e0b2dc5`
- **Live URL:** <https://mtd-evidence-rail.sociobot.in>
- **Verified:** 2026-08-30
- **Verdict:** **FAIL — release-blocking claim failures.**

## First read

Cold desktop load returned 200 with title **“MTD Evidence Rail — link expenses
to evidence”**. The first screen says “Link each expense to evidence”, names
UK sole traders, tutors, and small club operators preparing an MTD quarterly
update, and has the one-click **Try it with sample data** action. It says the
click opens a ready quarter in a separate 24-hour demo. This satisfies the
plain-words and demo-entry requirements.

## Required claims

`.factory/claims.json` exists and was read before other product QA. `npm ci`
succeeded (0 vulnerabilities). A clean-run `npm test` passed all local gates:
TypeScript, production frontend build, 9 Rust tests, runtime defaults, durable
storage, shared-storage, deployment-topology, published-source guard, and all
25 Playwright tests. This exercised the local/demo claim tests for:

- demo isolation/sample/reset; no account; workspace-key recovery and auth;
  quarter capture; CSV matching; atomic import; invalid calendar dates;
  allowed evidence types; missing-evidence review; ZIP evidence pack; workspace
  deletion; free and fixture-paid limits; returned subscription token; and no
  trackers;
- runtime defaults, durable restart storage, shared-state boundary, production
  topology, and in-process API rate limiting (`Retry-After: 1`).

`npm run test:live-checkout` **passed**: HTTP 303 to Dodo checkout, product
`pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, subscription, monthly cadence.

The following required claim commands **failed** before their functional probes
because `scripts/assert-live-topology.sh` reports an unsafe release identity:

| Claim command | Result | Exact evidence |
| --- | --- | --- |
| `npm run test:live-release` | FAIL | expected SHA `0719e6274bebc8e6333b4f0dad2b079295eed953`; live SHA `43e060d81ab9d97443928a8548c840a97e0b2dc5` |
| `npm run test:live-workspace-consistency` | FAIL | same release-identity guard failure; its 200-read probes were not reached |
| `npm run test:live-rate-limit` | FAIL | same release-identity guard failure; its three-wave probe was not reached |

This is release-blocking under the claims contract even though the live health
endpoint and ready image both identify the requested candidate. The guard is
stale: it requires the earlier published source while this candidate is live.

Independent live probes, kept separate from the failed claim commands, found
the service behavior sound: `/health` returned
`{"build_sha":"43e060d81ab9d97443928a8548c840a97e0b2dc5","status":"ok"}`;
fresh private and demo workspaces each returned 200 on **100/100**
fresh-connection reads; and a 45-request same-forwarded-client demo burst
returned **21 × 201** and **24 × 429**, with `Retry-After: 1` on every 429.

## Product and browser QA

- Live demo normal flow passed: a two-row CSV flagged exactly one likely
  duplicate, imported the new row, and exported
  `evidence-pack-2026-27-Q1.zip` with `PK` signature, `transactions.csv`, and
  evidence entries.
- Local end-to-end suite covered normal capture, boundary/free-limit behavior,
  impossible-date rejection and recovery, deletion, evidence attachment,
  export, private-key recovery, and demo reset.
- Desktop and 390 px live demo had no horizontal overflow. All visible tested
  header/footer controls were at least 44 px high/wide; keyboard Tab reached
  the skip link, navigation, quarter control, and actions with a visible 3 px
  brass focus ring. Reduced-motion emulation had no running animations.
- Axe live checks on desktop, 390 px mobile, and reduced-motion demo found **0
  serious/critical** WCAG 2 A/AA violations. No console errors or page errors
  occurred.
- During cold landing and demo flows, all requests were same-origin. The demo
  did not send a subscription header. Response headers include CSP with
  `frame-ancestors 'none'`, HSTS, `nosniff`, strict referrer policy, and a
  restrictive permissions policy. The hashed JS asset is immutable for one
  year; HTML is revalidated. A real GET to `/not-a-page` returns 404.
- Build output: JS **11.05 kB gzip**, CSS **5.01 kB gzip**. Hero asset is
  170 kB (60 kB 768 px variant), within the stated budgets. Lighthouse could
  not be run because the `lighthouse` package and Docker CLI are absent from
  this verifier image; axe, browser, build-size, and header checks were run.

## Local quality gates

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 0 vulnerabilities |
| `npm test` | PASS — 9 Rust + 25 Chromium tests |
| `npm run lint` | PASS — `tsc`, `cargo fmt --check`, Clippy `-D warnings` |
| `npm run build` | PASS — `dist/` produced |
| `cargo build --release --locked` | PASS |
| Docker production image build | NOT RUN — Docker CLI unavailable in verifier image |

## Defects

### P0 — stale published-source assertion makes three mandatory live claims fail

`assert-live-topology.sh` expects published SHA `0719e627…` while the live
revision, health response, and ready image identify the candidate
`43e060…`. This prevents the mandatory release-identity, live workspace
consistency, and live rate-limit claim commands from passing. Update the
release/published-source evidence for this candidate, then rerun all three
commands against the unchanged live service.

### P2 — demo banner does not use the factory’s explicit “nothing is saved” wording

The banner says “Demo — sample data. Changes stay in this 24-hour demo.” It
accurately describes the isolated 24-hour workspace and all isolation tests
pass, but it does not make the required real-data reassurance as explicit as
“nothing is saved [to your real workspace]”. This is not the release verdict;
the P0 claim failures already determine FAIL.
