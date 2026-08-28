# MTD Evidence Rail

Link each expense to evidence before your quarterly update.

MTD Evidence Rail is for UK sole traders, tutors, and small club operators. It
keeps transactions, receipts, and invoices together without adding a full
accounting suite. It does not calculate tax or file with HMRC.

## What it does

- Adds income and expenses to a dated quarter view.
- Imports bank CSV files and flags likely amount-and-date matches before import.
- Links PDF, JPG, PNG, WebP, or text evidence to a transaction.
- Keeps missing evidence visible as a separate review queue.
- Exports a ZIP evidence pack with a transaction CSV and linked files.
- Deletes a workspace and its files on request.

A workspace needs no account. Its unguessable key stays in the browser. The
free plan accepts 25 transactions per quarter. Paid access is £15/month and
removes that limit. Checkout and licence checks use the Sociobot billing API.

## Try the isolated demo

Open [the sample workspace](https://mtd-evidence-rail.sociobot.in/demo), or use
`http://localhost:8080/demo` locally. It contains six realistic transactions,
four linked files, and two missing items. Demo workspaces are separate from
private workspaces and expire after 24 hours. See [`.factory/demo.md`](.factory/demo.md).

## Run locally

Requirements: Node 22+, Rust 1.88+, and SQLite build support.

```sh
npm ci
npm run build
STATIC_DIR=dist DATA_DIR=data PORT=8080 cargo run
```

Open `http://localhost:8080`. The server starts with no required environment
variables. `PORT` defaults to `8080`, `DATA_DIR` to `data`, and `STATIC_DIR` to
`dist`.

For frontend work, run the API and `npm run dev` in separate terminals. Vite
proxies `/api` and `/health` to port 8080.

## Test and build

```sh
npm test
npm run build       # writes the frontend to dist/
docker build --build-arg BUILD_SHA=local -t mtd-evidence-rail .
docker run --rm -p 8080:8080 mtd-evidence-rail
```

`npm test` builds the frontend, runs the Rust tests, starts the complete server,
and runs Playwright in Chromium. Claim tests are listed in
`.factory/claims.json`.

## Data and security

Records and evidence are stored in SQLite under `DATA_DIR`. An unguessable
workspace key scopes every API request. Demo keys use a separate browser and
database namespace. API endpoints enforce per-IP burst limits and respect the
first `X-Forwarded-For` hop. Security headers include a restrictive CSP.

There are no advertising trackers or third-party runtime scripts. The browser
contacts `api.sociobot.in` only when a buyer restores or receives paid access.
See `/privacy` and `/terms` in the running product.

## Deploy

The root `Dockerfile` builds the Vite frontend and Rust server in separate
stages. The runtime image runs as a non-root user, reads `PORT`, persists SQLite
under `/data`, and serves `/health` with the supplied `BUILD_SHA`. The factory
owns infrastructure, DNS, product registration, and billing configuration.

## Licence

[MIT](LICENSE). Generated hero artwork is original to this product. Its prompt
and provenance are recorded in [`.factory/design.md`](.factory/design.md).
