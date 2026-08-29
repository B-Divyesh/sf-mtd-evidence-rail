# Independent verification 14 — PASS

**Candidate:** `bf15534cef6692e35f5ad62b610eb51648dcfe88`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Verified:** 29 August 2026, 18:44 UTC

**Decision:** **PASS — release this candidate.**

The previous deployment-only failure is resolved. The candidate works for the
brief's smallest useful job, every declared claim passes, and the deployed
source, frontend bytes, backend health identity, image tag, revision, replica
count, and durable-storage topology agree.

## Defects by severity

- Critical: none.
- High: none.
- Medium: none.
- Low: none.

No release-blocking or non-blocking product defect was found. The expected
browser network messages for a deliberately requested 404 and a deliberately
rejected 415 upload were excluded from the normal-flow console result; normal
routes and successful flows produced no console or page errors.

## Mandatory first-read gate

Cold opens at 1440 × 900 and 390 × 844 passed.

- What it does: **“Link each expense to evidence.”**
- Who it is for: **“For UK sole traders, tutors, and small club operators
  preparing an MTD quarterly update.”**
- What to click first: **“Try it with sample data.”** The adjacent text says it
  opens a ready quarter and that changes stay in the 24-hour demo.
- One click opened `/?demo=1`, six realistic transactions, four linked files,
  two missing items, and the persistent Reset demo / Start for real banner.

The first viewport also states the no-account model, £15/month threshold, and
ZIP export. Factory URL-verifier evidence is in
`.factory/evidence/verification-14/root/verify.json` and
`.factory/evidence/verification-14/demo/verify.json`; both report one H1,
`lang=en-GB`, a main landmark, complete image alt text, labelled buttons, and
zero console errors.

## Claims gate — 26/26 PASS

I created a separate clone with an empty git status at the candidate SHA, ran
`npm ci`, then ran every `test` value in `.factory/claims.json` individually.
The file contains 26 unique, complete claim entries. All exact commands passed.

| Claim | Exact command | Result and observable evidence |
| --- | --- | --- |
| `demo-isolation` | `npm test -- --grep @claim:demo-isolation` | PASS — separate 24-hour `demo:` key; private and subscription state unchanged |
| `no-account` | `npm test -- --grep @claim:no-account` | PASS — private workspace created with a 64-character local key |
| `workspace-key-recovery` | `npm test -- --grep @claim:workspace-key-recovery` | PASS — copied key reopened the same saved record after storage was cleared |
| `workspace-key-auth` | `npm test -- --grep @claim:workspace-key-auth` | PASS — all protected methods accepted the valid key and rejected missing/wrong keys |
| `quarter-capture` | `npm test -- --grep @claim:quarter-capture` | PASS — income and expense appeared in their dated quarter |
| `csv-matching` | `npm test -- --grep @claim:csv-matching` | PASS — one amount/date match skipped; one new row imported |
| `atomic-import` | `npm test -- --grep @claim:atomic-import` | PASS — mixed valid/invalid import returned 400 and retained six rows |
| `calendar-dates` | `npm test -- --grep @claim:calendar-dates` | PASS — impossible date returned the specific 400 response |
| `evidence-types` | `npm test -- --grep @claim:evidence-types` | PASS — five MIME types and exactly 5 MiB accepted; 5 MiB + 1 byte rejected |
| `missing-review` | `npm test -- --grep @claim:missing-review` | PASS — exactly two missing rows, no linked row |
| `demo-sample` | `npm test -- --grep @claim:demo-sample` | PASS — 6/4/2 counts before and after reset |
| `evidence-pack` | `npm test -- --grep @claim:evidence-pack` | PASS — ZIP signature, transaction CSV, and evidence directory present |
| `workspace-delete` | `npm test -- --grep @claim:workspace-delete` | PASS — workspace with evidence deleted and key returned 404 |
| `free-limit` | `npm test -- --grep @claim:free-limit` | PASS — row 26 returned 402 and did not change the count |
| `paid-limit` | `npm test -- --grep @claim:paid-limit` | PASS — recorded valid verification allowed 26 rows |
| `hosted-checkout` | `npm run test:live-checkout` | PASS — HTTP 303 to Dodo product `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500, monthly |
| `license-return` | `npm test -- --grep @claim:license-return` | PASS — token stored, URL stripped, recorded response cached |
| `no-trackers` | `npm test -- --grep @claim:no-trackers` | PASS — only same-origin requests in the demo core flow |
| `runtime-defaults` | `npm run build && cargo build && npm run test:runtime-defaults` | PASS — service started with only `PORT` |
| `durable-storage` | `npm run build && cargo build && npm run test:durable-storage` | PASS — workspace survived a server restart |
| `shared-state-boundary` | `npm run build && cargo build && npm run test:shared-storage` | PASS — three processes returned 400/400 reads across restart |
| `production-topology` | `npm run test:deployment-topology` | PASS — unsafe three-replica and mountless shapes rejected |
| `live-workspace-consistency` | `npm run test:live-workspace-consistency` | PASS — private and demo keys each returned 200 on 100/100 fresh connections |
| `live-release-identity` | `npm run test:live-release` | PASS — repository, health, ready image, and latest revision agreed |
| `api-rate-limit` | `cargo test api_rate_limit_returns_retry_after` | PASS — in-process forwarded client received 429 + `Retry-After: 1` |
| `live-api-rate-limit` | `npm run test:live-rate-limit` | PASS — 53 of 200 were 429; every limited response sent `Retry-After: 1` |

Landing and README claim-like statements were cross-checked against this list.
No unlisted claim was found.

## Clean build and repository gates

- `npm ci`: PASS — 34 packages, 0 vulnerabilities.
- `npm test`: PASS — 6 Rust tests, runtime/defaults, restart durability,
  three-process storage, topology guard, and 25 Chromium tests.
- `npm run lint`: PASS in both the working copy and literal clean clone —
  TypeScript, rustfmt, and Clippy with warnings denied.
- `npm run build`: PASS — `dist/` produced.
- `cargo build --release --locked`: PASS — optimized build completed.
- `npm audit --audit-level=low`: PASS — 0 vulnerabilities.
- A Docker/Podman daemon is unavailable in this verifier container. The same
  multi-stage inputs built in release mode, and the running candidate image was
  independently identified through Azure and `/health`.

Output sizes are 33,893 bytes JavaScript (11,046 gzip), 18,132 bytes CSS
(5,010 gzip), 102,036 bytes of self-hosted fonts, and 61,374 bytes for the
mobile hero. These are below all stated first-load budgets.

## Live end-to-end and recovery evidence

In a fresh live demo workspace I:

1. entered amount `0` and received “Enter an amount greater than zero”;
2. corrected it to £19.95 and saved the transaction;
3. supplied bad CSV headings, received the heading-specific recovery message,
   then imported a corrected bank row;
4. supplied `application/octet-stream`, received the supported-type message,
   then linked a text evidence file;
5. reviewed the resulting three missing-evidence rows;
6. downloaded `evidence-pack-2026-27-Q1.zip` and verified its `PK` signature;
7. completed 15 concurrent reads with 15 HTTP 200 responses; and
8. reset the demo to a new key and the original 6/4/2 sample counts.

The local claim suite additionally covers impossible dates, atomic rejection,
the exact 5 MiB file boundary, free row 25/26, private-key recovery, workspace
deletion, and offline recovery copy.

## Deployment, concurrency, persistence, and throttling

Fresh control-plane evidence:

```text
health build: bf15534cef6692e35f5ad62b610eb51648dcfe88
image: sociobotregistry.azurecr.io/sf-mtd-evidence-rail:bf15534cef66
revision: sf-mtd-evidence-rail--0000050 (latest and ready)
mode / replicas: Single / min 1 / max 1 / running 1
storage: mtd-data Azure Files mounted at /data
SQLite VFS: unix-dotfile
```

The live service returned 100/100 fresh-connection reads for both new private
and demo workspaces. Local restart and three-process tests passed. A separate
100-request concurrent burst from one forwarded IP observed 44 HTTP 201 and 56
HTTP 429 responses; every 429 sent `Retry-After: 1`. The configured allowance
is a 40-request burst with one token per 50 ms (20 requests/second); the four
extra acceptances are consistent with refill during the 4.6-second probe.
Health is intentionally exempt. Every `/api` route shares the limiter.

## Candidate-to-live match

`GET /health` returned the full candidate SHA. Local and live SHA-256 hashes
were byte-identical:

| File | SHA-256 |
| --- | --- |
| `index.html` | `c081753c7178e2ada3c32abd386e6dfdc3cf6987806b8a0b47ce894a951421d2` |
| `assets/index-B8p0AfOh.js` | `0341ff815d5f6132b26b4a5a3243aaf47d178a01306c5d5282a82468b67d344b` |
| `assets/index-B2Qaf5JO.css` | `ec6e1655c444db5663d63fd2ee6d86e66c881e1d3d9efdc7f066832210a3f991` |

## Accessibility, responsive behavior, and browser quality

Desktop and 390px sweeps covered `/`, `/demo`, `/app`, `/privacy`, `/terms`,
and a real `/not-a-page` 404. Every screen had one H1, a main landmark,
`lang=en-GB`, the correct route title, no horizontal overflow, and zero axe
serious/critical findings. The local suite found zero axe violations of any
severity.

- First Tab focused the visible skip link with a 3 px brass outline.
- Keyboard-only Tab/Enter entered the demo; dialog focus moved to the first
  field, Escape closed it, and focus returned to the trigger.
- User-facing mobile targets were at least 44 px. The visually clipped native
  file inputs are operated by their visible 48 px labelled controls.
- At 200% text size, 390px had no horizontal overflow.
- With reduced motion, animation and transition duration were `0s`, animation
  name was `none`, and scroll behavior was `auto`.
- No normal-flow console or page errors occurred.

## Privacy, headers, caching, and performance

The complete live demo mutation flow made 34 requests, all to
`https://mtd-evidence-rail.sociobot.in`. No tracker, third-party script,
private-workspace key, or subscription token left the demo. Checkout is the
clearly labelled, deliberate exception and redirects through Sociobot to Dodo.

Live HTML/API responses send `Cache-Control: no-cache`, `nosniff`, strict
referrer policy, a permissions policy, and a CSP including header-only
`frame-ancestors 'none'`. Hashed JS/CSS are immutable for one year;
unversioned hero media revalidates after one hour. The designed unknown route
returns HTTP 404. `robots.txt`, sitemap, favicon, touch icon, social card,
internal links, Sociobot link, and hosted-checkout redirect all resolved.

Fresh mobile Lighthouse evidence is
`.factory/evidence/verification-14/lighthouse.json`:

| Category/metric | Result |
| --- | ---: |
| Performance | 99 |
| Accessibility | 100 |
| Best practices | 100 |
| SEO | 100 |
| FCP / LCP | 1.080 s / 1.905 s |
| TBT / CLS | 0 ms / 0 |
| Transfer | 181,664 bytes |

This is a web-with-backend product, not a library/CLI or PWA. Consumer-package
and service-worker update tests do not apply; the browser confirmed no service
worker, Cache Storage, or manifest. Sign-in does not apply because the product
deliberately uses unguessable workspace keys and requires no account.

## Contract and documentation review

The product covers capture, dated quarter display, bank-CSV suggestions,
missing-evidence review, ZIP accountant export, user export/deletion, monthly
billing, and isolated sample data. It does not claim to file with HMRC or give
tax advice. README, MIT license, privacy, terms, demo documentation, visual
thesis, original-asset provenance, copy audit, claims file, and handoff are
present and consistent. No missed-leverage release blocker was identified.

## Reverification

After this verification-only commit, set the tested product identity explicitly:

```sh
npm ci
npm test
npm run lint
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-release
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-workspace-consistency
EXPECTED_SHA=bf15534cef6692e35f5ad62b610eb51648dcfe88 npm run test:live-rate-limit
```
