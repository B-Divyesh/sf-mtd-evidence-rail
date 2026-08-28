# MTD Evidence Rail repair handoff

Completed 28 August 2026 for work order `mtd-evidence-rail-repair-1`.

## Result

All release-blocking findings in verifier commit
`bc3052694229645443825312b0c060e925cc1315` are repaired. The deployed code is
commit `3ff5921c9572a21fbae9ae2f10d76f0535684a67` at
<https://mtd-evidence-rail.sociobot.in>.

## Repairs

- Production now mounts the `sf-mtd-evidence-rail-data` Azure Files share at
  `/data`. The Container App uses single revision mode, one replica, and
  SQLite's `unix-dotfile` lock mode for SMB. The deployment script verifies
  those settings and recovers from transient hostname-update conflicts.
- The API enforces 25 transactions per MTD quarter. Requests above the limit
  require a licence that the server verifies through the Sociobot product API.
  Only a SHA-256 token hash and daily verdict are cached.
- The live Sociobot product is registered and enabled. Its checkout returns a
  Dodo-hosted redirect instead of 404.
- Imports validate every row before one database transaction commits. Real
  calendar dates are validated at the API edge.
- Foreign keys are enabled. Workspace deletion removes records, evidence blobs,
  and audit rows; expired demo cleanup uses the same database cascade.
- TypeScript now has matching Playwright types and Node types. `typecheck` is
  part of `npm test`.
- `.factory/claims.json` now lists 18 claims, including deletion, file types and
  size, browser-held keys, runtime defaults, durable restart behavior, paid
  enforcement, checkout, and forwarded-IP rate limiting.
- Legal-page contrast and 44 px mobile header/footer targets are fixed.
- The Rust builder uses `rust:1-slim`. Unknown routes return HTTP 404, hashed
  bundles remain immutable, and unversioned art/fonts revalidate after one hour.
- Workspace actions remain disabled until the initial asynchronous load
  completes. Browser tests wait for the same observable ready state.

## Local verification

Run from the repository root:

```sh
npm ci
npm test
npm audit --audit-level=low
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release --locked
bash scripts/test-live-checkout.sh
```

Observed results:

- `npm ci`: 34 packages installed; 0 vulnerabilities.
- `npm test`: PASS. It ran the TypeScript check, Vite production build, 4 Rust
  tests, runtime-with-only-`PORT`, durable stop/start, and 17 Chromium tests.
- All 18 claim entries passed through their listed test coverage. The paid path
  uses a recorded Sociobot verdict fixture; the live checkout test does not
  spend money.
- Formatting, strict Clippy, npm audit, and locked release compilation passed.
- Production output: JS 30,079 bytes raw / 10.26 KB gzip; CSS 16,617 bytes raw /
  4.73 KB gzip; local fonts 102,036 bytes; mobile hero 61,374 bytes.
- The ACR package build completed as run `chn1`; deployed image tag is
  `sf-mtd-evidence-rail:3ff5921c9572`.

## Live verification

- `/health` returned status `ok` and the exact deployed code SHA above.
- Local and live JS SHA-256 both equal
  `13e452d66c24410a9f67c58db7e6f802dc7931ff66b4908a48ff4e0fd80a1eca`.
- Factory `verify-url.sh` passed with no console errors, title, `en-GB`, one
  `h1`, `main`, image alternatives, and labelled buttons. Desktop and 390 px
  screenshots are in `.factory/evidence/repair-final/`.
- The live browser suite passed 15/15 applicable non-fixture tests. It covered
  the demo, capture, CSV matching, atomic failure, invalid dates, evidence
  types and 5 MB boundary, export, deletion, free enforcement, privacy,
  desktop routes, Axe, keyboard, and 390 px layout.
- Twelve additional fresh Chromium contexts loaded and reset the demo: 12/12
  passed.
- Axe found no serious or critical issue on `/`, `/demo`, `/app`, `/privacy`,
  `/terms`, or the designed 404 route. Keyboard dialog focus and Escape return
  passed. Every visible mobile header/footer link measured at least 44 px.
- A workspace and record survived a live revision restart. All 40 reads after
  restart returned 200, and the saved record remained present.
- A 100-request fixed first-hop burst returned 43 normal 401 responses and 57
  rate-limited 429 responses. Every 429 included `Retry-After: 1`.
- Azure reports single revision mode, max replicas 1, `/data` mounted from
  `mtd-evidence-rail-data`, and `SQLITE_VFS=unix-dotfile`.
- Hosted checkout returned HTTP 303. A 26th unlicensed transaction returned
  402; the recorded valid-licence integration allowed 26 records.
- Unknown routes return 404. CSP, `nosniff`, referrer policy, and permissions
  policy are present. Unversioned hero art returns
  `public, max-age=3600, must-revalidate`.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 1.08 s, LCP 1.91 s, TBT 1 ms, CLS 0, transfer 180,619 bytes.
- The core demo flow made same-origin requests only. There are no analytics or
  third-party runtime scripts.

This product does not ship a service worker or claim offline operation, so
offline cache/update testing is not applicable. It has no account system, so
live identity-provider testing is not applicable; workspace identity and
isolation were tested instead.

## Deliberate deviation and remaining boundary

The researched brief still records `£15/month`. The attached paid-unlock
contract and available Sociobot billing API support one-time licence purchases,
not subscriptions. To avoid a false recurring-billing claim, the shipped offer
is an honest **£15 one-time purchase**; the brief itself was preserved unchanged.

No release-blocking gap remains. A real card purchase was not completed during
verification; the live redirect and recorded valid-verdict flow cover the two
sides without spending. The 5 GiB evidence share should be monitored as usage
grows, and SQLite must remain at one configured replica.
