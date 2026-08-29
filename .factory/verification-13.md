# Independent verification 13 — FAIL

**Candidate:** `dc3b37c98d580be466ea3fa3f5cc84a455d50daa`  
**Live URL:** <https://mtd-evidence-rail.sociobot.in>  
**Verified:** 2026-08-29 UTC  
**Decision:** **FAIL — do not release this candidate.**

## Release-blocking findings

### Critical — deployed backend identity is not the candidate

`GET /health` returned:

```json
{"build_sha":"8eabb53a7fdaebe7372c655d4e265c02dd0d21bb","status":"ok"}
```

That is not candidate `dc3b37c98d580be466ea3fa3f5cc84a455d50daa`. The live HTML
uses the same hashed frontend asset names as a local candidate build, but the
running server identity differs. The git diff between the two commits is
currently confined to `graphify-out`, which is not a Docker input; the exact
release identity check nevertheless fails.

### Critical — unsafe live topology makes two required claims fail

Both declared live claim commands stopped at this topology guard:

```text
Unsafe live topology: mode=Single min=1 max=3 containers=1 mount= volume=: vfs= active=2 running=1
```

The deployment has a maximum of three replicas, two active revisions, no
reported durable Azure Files mount and no `SQLITE_VFS` setting. This violates
the one-replica/durable-storage contract and prevents acceptance of the live
persistence boundary and the one-process rate-limit allowance.

| Claim | Exact command | Result |
| --- | --- | --- |
| `live-workspace-consistency` | `npm run test:live-workspace-consistency` | FAIL — unsafe topology |
| `live-api-rate-limit` | `npm run test:live-rate-limit` | FAIL — unsafe topology |

## Claims evidence

After `npm ci`, I ran every one of the 25 commands in
`.factory/claims.json` individually. These 23 claims passed:

```text
demo-isolation, no-account, workspace-key-recovery, workspace-key-auth,
quarter-capture, csv-matching, atomic-import, calendar-dates, evidence-types,
missing-review, demo-sample, evidence-pack, workspace-delete, free-limit,
paid-limit, hosted-checkout, license-return, no-trackers, runtime-defaults,
durable-storage, shared-state-boundary, production-topology, api-rate-limit
```

This includes the local Rust unit suite, TypeScript check, production Vite
build, fresh demo Playwright claims, startup with only `PORT`, restart and
three-process storage checks, and the local rate-limit test. Hosted checkout
passed: HTTP 303 to Dodo product `pdt_0NmPnl9rqkKtKbVXh6baV`, GBP 1500,
monthly subscription.

An independent same-forwarded-IP probe of 200 concurrent `POST /api/demo`
requests observed 198 `201` and 2 `429`; every limited response had
`Retry-After: 1`. A limiter exists, but its documented single-process
allowance cannot be accepted with up to three live replicas. Source/unit
evidence specifies a 40-token burst and a 20 requests/second refill.

## Product QA that passed

Cold first read passed: “Link each expense to evidence” says what it does;
the page names UK sole traders, tutors and small club operators; and the
visible one-click **Try it with sample data** says it opens a ready 24-hour
demo. It opened `/?demo=1` with the persistent Reset demo / Start for real
banner, six sample transactions and two missing-evidence rows.

On the live demo I saved a valid transaction, reviewed missing evidence,
imported valid CSV, exercised ZIP export, and used keyboard dialog controls.
Amount zero gave “Enter an amount greater than zero.” and recovered after a
valid correction. Invalid CSV headings gave the specific recovery message and
the subsequent valid CSV imported. Escape restored focus to Add a transaction.

Desktop and 390px checks on `/`, `/demo`, `/app`, `/privacy`, `/terms`, and
the real 404 each found one H1 and zero axe serious/critical findings. The
first Tab reaches a visible skip link; keyboard Enter begins the demo;
reduced-motion was active; and 390px had no horizontal overflow. Normal cold
and demo flows made same-origin requests only, with no console/page errors.

Responses sent CSP with `frame-ancestors 'none'`, `nosniff`, strict referrer
and permissions policies, and `no-cache` for HTML/API. Hashed JS was immutable
and the hero revalidated after one hour. Candidate output is 33.89 kB JS
(11.05 kB gzip) and 18.13 kB CSS (5.01 kB gzip).

## Local checks and re-test steps

`npm run lint` (TypeScript, rustfmt and clippy),
`cargo build --release --locked`, and `npm run build` were run after the
claims. Docker/Podman is unavailable in this verifier image, so a local image
build could not be run; direct live evidence already rejects the release.

Before requesting a new verification: deploy the exact candidate SHA, then
restore one active revision and one replica with Azure Files mounted at `/data`
and `SQLITE_VFS=unix-dotfile`. Re-run both failed live claims and verify:

```sh
test "$(git rev-parse HEAD)" = "$(curl -fsS https://mtd-evidence-rail.sociobot.in/health | jq -r .build_sha)"
```
