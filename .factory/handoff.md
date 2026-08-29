# MTD Evidence Rail repair handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-repair-6`.

## Repair

Verification 6's exact failure was reproduced from the Azure control plane:
revision `sf-mtd-evidence-rail--0000025` mounts Azure Files at `/data` using
the volume name `mtd-data`, while the candidate manifest and live checker used
the obsolete literal `data`. The old checker therefore resolved `mount=` even
though the real mount was healthy.

The source-owned contract now names the canonical Azure Files volume
`mtd-data` everywhere. `verify:live-topology` reads the identifier, mount,
storage type/name, and SQLite VFS from `.factory/container-app.json`; it no
longer carries a second hard-coded contract. The renderer regression rejects a
return to `data` and asserts the canonical mount/volume pair.

The live verifier now also proves the related verification-5 failure modes
against the one-replica deployment: 100 fresh reads each for a private and
demo workspace, an unconfirmed workspace delete of 400, confirmed delete of
204, 20 fresh reads of 404 after deletion and after revision restart, then a
single-limiter burst probe with `Retry-After: 1` on every 429. This preserves
the product's existing claims and makes deletion, persistence, and rate-limit
proof part of the deploy gate.

## Local verification

- Clean install: `npm ci` — 34 packages, 0 audit vulnerabilities.
- Complete suite: `npm test` — TypeScript check; Vite production build;
  4 Rust tests; runtime-default, durable-storage, shared-storage, and
  production-topology claims; 21 Chromium tests. All passed.
- Browser coverage includes desktop and 390px mobile, keyboard skip/demo and
  dialog focus return, 200% text, reduced motion, offline recovery, all routes,
  and Axe scans with zero violations.
- `cargo fmt -- --check`, `cargo clippy --all-targets --all-features -- -D
  warnings`, `cargo build --release --locked`, and `npm audit --audit-level=low`
  passed.
- Build output: JS 30.36 kB raw / 10.31 kB gzip; CSS 16.96 kB raw / 4.80 kB
  gzip. There is no package consumer or service-worker update path for this
  container-served web application.

## Deploy and live verification

Deploy with `scripts/deploy.sh`. It builds the root multi-stage Dockerfile,
applies the source-owned single-replica Azure Files topology, and invokes:

```sh
EXPECTED_SHA=<deployed commit> BASE_URL=https://mtd-evidence-rail.sociobot.in \
  npm run verify:live-topology -- --restart
```

That gate validates live identity, source/live topology alignment, shared
storage before and after restart, confirmed deletion, browser demo isolation,
same-origin privacy behaviour, and the per-client rate limit. The final live
output is recorded in the deployment job before release.

## Known gaps

None. The product is intentionally not a PWA and does not claim offline reload;
its offline UI recovery path is covered. No AI feature is needed for the brief,
and no account or consumer package applies.
