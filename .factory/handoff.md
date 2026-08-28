# MTD Evidence Rail v1 handoff

Completed 28 August 2026 for work order `mtd-evidence-rail-build-1`.

## What shipped

- A Rust 2021 `axum` service with SQLite migrations, structured logs, graceful
  shutdown, security headers, a build-aware `/health`, and forwarded-IP rate
  limiting. The service starts with only `PORT`; storage defaults are generated.
- Private bearer-key workspaces and separate 24-hour demo workspaces. Creating a
  demo clears expired demo data. Users can delete a complete workspace.
- Manual income and expense capture, MTD-aligned quarterly periods, and one
  dated transaction view.
- Receipt and invoice evidence files up to 5 MB, with link and remove audit
  entries.
- Bank CSV review with quoted-cell parsing, date normalisation, and same-day
  amount match suggestions. Likely matches are skipped on confirmation.
- A missing-evidence filter and a ZIP evidence pack containing
  `transactions.csv`, linked files, and a plain README.
- A free 25-transaction quarter and a £15/month paid route through the Sociobot
  checkout. Returned licences are stored, verified, cached daily, and can be
  restored by pasting a token. No product id is embedded beyond the required
  product slug.
- Landing, app, demo, privacy, terms, and designed not-found routes. History,
  keyboard focus, mobile layout, errors, empty states, loading, and offline
  notices are included.
- Original surreal editorial hero art, responsive WebP outputs, local fonts,
  social card, favicon, sitemap, robots file, and route metadata. Provenance is
  in `.factory/design.md` and `assets/src/`.
- Container build stages for Vite and Rust. The runtime is non-root and stores
  SQLite under `/data`.

## Run and verify

```sh
npm ci
npm test
npm run build
STATIC_DIR=dist DATA_DIR=data PORT=8080 cargo run --release
```

Container build command:

```sh
docker build --build-arg BUILD_SHA=$(git rev-parse HEAD) -t mtd-evidence-rail .
```

The factory may pass `BUILD_SHA`, `GIT_SHA`, and `SOURCE_COMMIT`; only
`BUILD_SHA` is needed by the image and it has a `dev` default.

## Verification evidence

- `npm test`: passed. This ran 2 Rust tests and 9 Chromium tests.
- All 7 entries in `.factory/claims.json`: passed from fresh browser contexts.
- Playwright axe integration: 0 serious or critical findings on `/` and `/demo`.
- Factory `verify-url.sh`: passed with one title, `en-GB`, one `h1`, a `main`,
  complete image alt text, labelled buttons, and 0 console errors.
- Lighthouse mobile: performance 99, accessibility 100, best practices 100,
  SEO 100. LCP 2.0 s, CLS 0, and total blocking time 0 ms. Lab INP was not
  available; the 0 ms blocking result is the closest lab signal.
- Production payload: JS 29.67 KB / 10.20 KB gzip; CSS 16.33 KB / 4.69 KB gzip;
  hero 172 KB desktop and 60 KB mobile; fonts 108 KB total.
- Health load smoke: 100 parallel requests, 100 returned HTTP 200.
- API limiter test: request 41 in a one-second client window returns 429 with
  `Retry-After: 1`.
- `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, and
  `npm audit`: passed. Production and development npm dependencies report zero
  known vulnerabilities.
- The release binary was started with a scrubbed environment and only
  `PORT=8090`; `/health` returned `{"build_sha":"dev","status":"ok"}`.

Evidence files are under `.factory/evidence/`.

## Known boundaries and next steps

- This is a record aid, not HMRC-accredited filing software or tax advice.
- Workspace access uses an unguessable browser-held key. V1 has no account
  recovery or multi-device sync; users should export before clearing a browser.
- The factory must register the `mtd-evidence-rail` billing product before the
  live checkout can sell or verify licences.
- Expired demo rows are physically removed when the next demo is created. A
  scheduled cleanup can be added if demo volume warrants it.
- Docker tooling was not installed in the worker image, so the multi-stage
  Dockerfile was reviewed but not executed locally. Both constituent builds
  (`npm run build` and `cargo build --release --locked`) passed.
