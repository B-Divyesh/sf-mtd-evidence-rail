# MTD Evidence Rail — independent verification 9: PASS

**Verified 29 August 2026**  
Candidate: `c088767e95c03bf45f72f36f8bef5b1ecf7a71cc`  
Live URL: <https://mtd-evidence-rail.sociobot.in>  
Verdict: **PASS**

## Identity and first read

`GET /health` returned HTTP 200 with
`{"build_sha":"c088767e95c03bf45f72f36f8bef5b1ecf7a71cc","status":"ok"}`. The live
hashed JavaScript and CSS byte-for-byte matched the clean candidate build:
`index-BA5OVeWj.js` SHA-256 `cc75b02b…d54bd1` and
`index-BCwV1doZ.css` SHA-256 `cecf9fbe…926c7bd`.

Cold desktop first read: “Link each expense to evidence” says what it does;
“For sole traders who need a reviewable record before each MTD quarterly
update” says who it is for; and the visible **Try it with sample data** action
says what to do first. Its adjacent copy explains that it opens a ready quarter
in a separate 24-hour demo. This meets the plain-words and one-click demo
requirements.

## Required clean-clone checks

Used a detached clean clone at the candidate, ran `npm ci`, and then ran every
exact command in `.factory/claims.json`. All 20 declared claims passed:

`demo-isolation`, `no-account`, `quarter-capture`, `csv-matching`,
`atomic-import`, `calendar-dates`, `evidence-types`, `missing-review`,
`evidence-pack`, `workspace-delete`, `free-limit`, `paid-limit`,
`hosted-checkout`, `license-return`, `no-trackers`, `runtime-defaults`,
`durable-storage`, `shared-state-boundary`, `production-topology`, and
`api-rate-limit`.

The hosted-checkout proof observed HTTP 303 to Dodo for
`mtd-evidence-rail`, GBP 1500, monthly cadence. `npm test` also passed in full:
TypeScript, Vite build, 4 Rust tests, runtime/storage/topology checks, and all
21 Chromium tests. The production build passed `npm run build` and
`cargo build --release --locked`; the release binary served `/health` on a
test port. Docker is not installed in this verifier image, so the Docker image
could not be built here; this is an environment limitation, not a product
failure.

## Live product and backend evidence

- `/demo` created its documented six-record, two-missing-evidence sample in a
  separate 24-hour workspace.
- A fresh live API flow created a demo (201), saved a representative £12.50
  expense (201), rejected `2026-99-99` (400, “Enter a real calendar date.”),
  returned seven records, and exported a ZIP (`PK` signature).
- A 100-request same-client burst to `/api/workspace` produced 50 HTTP 401
  responses followed by 50 HTTP 429 responses. The 429 response included
  `Retry-After: 1`. This confirms the deployed forwarded-IP limiter; observed
  allowance was a 50-request burst during this window (source configuration is
  burst 40 plus refill).
- Playwright’s cold landing request log contained only same-origin fonts,
  assets, and page requests. The shipped no-trackers claim test also passed
  through the demo flow. No console or page errors were recorded on the cold
  landing page.

## Accessibility, responsive behaviour, headers, and performance

The untagged Playwright regressions passed: axe found zero violations across
`/`, `/demo`, `/app`, `/privacy`, `/terms`, and the real 404; all have one H1.
At 390px, Tab reaches the skip link, keyboard Enter opens the demo, dialogs
return focus, and 200% text has no horizontal overflow. The reduced-motion CSS
disables animation and transitions.

Live HTML provides a restrictive CSP with `frame-ancestors 'none'`,
`X-Content-Type-Options: nosniff`, strict referrer policy, and permissions
policy. HTML uses `no-cache`; hashed JS/CSS use
`public, max-age=31536000, immutable`. Production output is 30.51 kB JS
(10.32 kB gzip) and 16.96 kB CSS (4.80 kB gzip), well within budget.

## Defects by severity

None.

No product source code was changed during verification. Clean-clone logs and
screenshots are retained in the disposable verifier workspace under
`/tmp/mtd-evidence-rail-verify-9.lpWKm6/qa-logs/`.
