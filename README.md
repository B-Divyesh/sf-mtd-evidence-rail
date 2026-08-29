# MTD Evidence Rail

Link each expense to evidence before your quarterly update.

MTD Evidence Rail is for UK sole traders, tutors, and small club operators
preparing an MTD quarterly update. It keeps transactions, receipts, and
invoices together in a dated quarter view.

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

Copy the workspace access key to open the same records on another device.
Anyone with this key can change the records, so keep it private.

## Try the isolated demo

Open [the sample workspace](https://mtd-evidence-rail.sociobot.in/?demo=1), or
use `http://localhost:8080/?demo=1` locally. It contains six realistic
transactions, four linked files, and two missing items. Demo changes stay in a
separate workspace for 24 hours. See [`.factory/demo.md`](.factory/demo.md).

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
npm run test:live-workspace-consistency # also rejects unsafe live replica/storage topology
npm run test:live-rate-limit # repeats the deployed burst-limit probe
npm run verify:live-topology # checks 12 fresh demos and 100 reads per workspace
docker build --build-arg BUILD_SHA=local -t mtd-evidence-rail .
docker run --rm -p 8080:8080 mtd-evidence-rail
```

`npm test` builds the frontend, runs the Rust tests, starts the complete server,
and runs Playwright in Chromium. Claim tests are listed in
`.factory/claims.json`.

## Data and security

Workspace data remains available after a service restart. Production uses one
app instance with shared durable storage. Every private API request must include
the workspace's 64-character key. Demo keys use a separate browser and database
namespace.

The API temporarily blocks a client that sends too many requests. Behind a
proxy, it identifies the client from the first forwarded IP address.

There are no advertising trackers or third-party runtime scripts. The server
enforces the free quarter limit even if browser storage is changed. See
`/privacy` and `/terms` in the running product.

## Deploy

The root `Dockerfile` builds the Vite frontend and Rust server in separate
stages. Run `scripts/deploy.sh` through the factory work order. It builds the
committed image, then applies that image with the one-replica Azure Files
topology in one revision and refuses completion unless the live resource
proves the mount, VFS, replica count, workspace reads, restart recovery, and
rate limiter. At startup, an Azure Container Apps revision also checks that
`/data` is a dedicated mount. It exits before serving traffic if a later
generic rollout replaces the durable topology with container-local storage.
The factory owns product registration and billing configuration.
Deployment details are recorded in the handoff.

If the work-order runner builds the image first, run the same command with
`PREBUILT_IMAGE` set to that exact commit-tagged image. The script skips the
second build but still applies and verifies the product topology.

## Licence

[MIT](LICENSE). Generated hero artwork is original to this product. Its prompt
and provenance are recorded in [`.factory/design.md`](.factory/design.md).
