# Independent verification 10 — FAIL

Verified 29 August 2026 against candidate commit
`b3acf78a26347d4bfa2f65988679eb55c60ee6a5` and the live URL
<https://mtd-evidence-rail.sociobot.in>.

## Release decision

**FAIL — release blocking.** The deployed service does not preserve either
private or demo workspaces across fresh requests. The required live-workspace
claim fails, so this is not a usable evidence store. The live API also did not
enforce its documented burst limit.

## First read and candidate identity

Cold desktop landing-page read: “Link each expense to evidence” tells a visitor
that this organises evidence for an MTD quarter; the following sentence names
UK sole traders, tutors, and small club operators; and the visible first action
is “Try it with sample data”, with the result explained as a ready 24-hour demo.
This gate passes.

The live root HTML SHA-256 exactly matched the fresh candidate build:
`c081753c7178e2ada3c32abd386e6dfdc3cf6987806b8a0b47ce894a951421d2`.
Both refer to `index-B8p0AfOh.js` and `index-B2Qaf5JO.css`. Live `/health`
returned HTTP 200 with build SHA
`b3acf78a26347d4bfa2f65988679eb55c60ee6a5`.

## Required claims and local quality gates

I began in a fresh detached clone at the candidate SHA, installed with
`npm ci`, and invoked every command listed in `.factory/claims.json` via the
shipped demo/test entry point. The ordinary sandboxed claims, runtime,
durability/shared-storage, topology rendering, checkout, and local rate-limit
tests pass. The one live claim fails:

```text
$ npm run test:live-workspace-consistency
private read 1 returned 404, expected 200
```

`npm test` passed: TypeScript typecheck, exact Vite production build, four Rust
tests, runtime-defaults, durable-storage, shared-storage, deployment-topology,
and the 25 Chromium tests all passed. `cargo test
api_rate_limit_returns_retry_after` passed locally. `npm run test:live-checkout`
passed and observed a 303 to Dodo, product `mtd-evidence-rail`, GBP 1500,
monthly. There is no separate lint command in `package.json`.

Production build output was 33.89 kB JS raw / 11.05 kB gzip and 18.13 kB CSS
raw / 5.01 kB gzip. `dist/` was produced.

## Blocking defects

### Critical — live workspace state is split between service instances

Fresh demo workspace, using 100 independent HTTP/1.1 connections with the same
workspace key: **50 HTTP 200, 50 HTTP 404**. A fresh private workspace under
the identical probe: **49 HTTP 200, 51 HTTP 404**. The 404 body was:

```json
{"error":"This workspace was not found. Start a new workspace."}
```

This reproduces in the browser: a demo initially displayed its six sample rows;
after CSV review identified one new row and one likely match, pressing “Import
new transactions” returned the same 404 and kept the dialog open. This breaks
record capture, import, export, recovery, and the explicit claim that a
workspace remains available.

Likely operational cause: the live revision is serving at least two instances
with different SQLite/data mounts, contrary to the declared one-replica shared
durable-store deployment. This is a deployment failure even though the source
topology-rendering test passes.

### Critical — live API rate allowance is not enforced

The documented implementation specifies burst 40 per client and requires a
429 with `Retry-After: 1`. I sent 200 concurrent `POST /api/demo` requests from
one `X-Forwarded-For: 198.51.100.9` client over fresh HTTP/1.1 connections.
All **200 returned 201**; no response returned 429 or `Retry-After`. Therefore
the observed live allowance is at least 200 requests in this burst (not the
documented 40), and the mandatory backend rate-limit contract fails.

## Other live QA observations

- Privacy/network: cold root and the attempted core demo flow made only
  same-origin asset/API requests; no third-party scripts or advertising
  requests were observed. Checkout was not activated during this check.
- Headers: `/` and `/health` supplied CSP with `frame-ancestors 'none'`,
  `X-Content-Type-Options: nosniff`, strict-origin referrer policy, and a
  restrictive permissions policy. Hashed JS was
  `public, max-age=31536000, immutable`; HTML was `no-cache`.
- Accessibility: axe on the cold 390 px landing screen found zero serious or
  critical violations (zero total violations). Keyboard Tab first reached the
  skip link with a visible `rgb(232, 191, 98) solid 3px` outline. The root page
  had one `<h1>` and `<main>`, no console/page errors, and no 390 px horizontal
  overflow.
- The repository does not include the referenced `verify-url.sh`; equivalent
  document/header/console checks were performed directly. This is a test
  tooling gap, not the reason for the release decision.

## Required remediation and re-verification

1. Make the deployed revision truly single-replica **or** make every replica
   use the same durable store at `/data`; then prove 100/100 fresh-connection
   reads for newly created private and demo workspaces, before and after a
   revision restart.
2. Configure live rate limiting at the ingress/application boundary so one
   forwarded client gets 429 and `Retry-After` after the stated allowance;
   repeat the burst probe against production.
3. Redeploy, retain the candidate/source identity in `/health`, and rerun this
   report's live workspace and rate-limit checks.
