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

A workspace needs no account. Its 64-character key stays in the browser. The
free plan accepts 25 transactions per quarter. A £15/month subscription accepts
more than 25. Checkout and subscription checks use the Sociobot billing API and
open a Dodo-hosted checkout.

## Try the isolated demo

Open [the sample workspace](https://mtd-evidence-rail.sociobot.in/demo), or use
`http://localhost:8080/demo` locally. It contains six realistic transactions,
four linked files, and two missing items. Demo workspaces are separate from
private workspaces and expire after 24 hours. See [`.factory/demo.md`](.factory/demo.md).

## Run locally

Requirements: Node 22+, current stable Rust, and SQLite build support.

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
npm run test:deployment-topology # rejects the verifier's unsafe rollout shape
npm run test:live-checkout # checks the live Dodo subscription contract
npm run verify:live-topology # checks 12 fresh demos and 100 reads per workspace
docker build --build-arg BUILD_SHA=local -t mtd-evidence-rail .
docker run --rm -p 8080:8080 mtd-evidence-rail
```

`npm test` builds the frontend, runs the Rust tests, starts the complete server,
and runs Playwright in Chromium. Claim tests are listed in
`.factory/claims.json`.

## Data and security

Records and evidence are stored in SQLite under `DATA_DIR`. Production mounts
that directory from Azure Files and runs one replica, so every request reaches
the same durable database. Its deployment-only `SQLITE_VFS=unix-dotfile`
setting uses lock files supported by SMB; the one-replica policy remains
mandatory. A 64-character workspace key scopes every API request. Demo keys use a separate
browser and database namespace. API endpoints enforce per-IP burst limits and
respect the first `X-Forwarded-For` hop. Security headers include a restrictive
CSP.

There are no advertising trackers or third-party runtime scripts. The product
contacts `api.sociobot.in` only to verify subscription access or start checkout. The
server enforces the free quarter limit even if browser storage is changed. See
`/privacy` and `/terms` in the running product.

## Deploy

The root `Dockerfile` builds the Vite frontend and Rust server in separate
stages. The runtime image runs as a non-root user, reads `PORT`, and serves
`/health` with the supplied `BUILD_SHA`. The work-order deployment is wrapped
by `scripts/deploy.sh`; it mounts Azure Files at `/data` and pins the app to one
replica because SQLite is a single-writer database. The source-owned
`.factory/container-app.json` contract is applied after the factory image
rollout. Deployment fails unless control-plane topology, cross-request reads,
one shared limiter, 12 fresh browsers, and restart persistence pass. The
factory owns product registration and billing configuration.

## Licence

[MIT](LICENSE). Generated hero artwork is original to this product. Its prompt
and provenance are recorded in [`.factory/design.md`](.factory/design.md).
