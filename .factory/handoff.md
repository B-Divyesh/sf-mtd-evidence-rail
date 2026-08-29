# Polish 1 handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-polish-1`.

## What changed

- Demo is reachable in one click at `/?demo=1` (with `/demo` retained).
- Demo mode uses only `sessionStorage` and demo API keys. It never reads,
  writes, verifies, or sends private subscription state.
- The demo banner now states the real boundary: changes stay in a 24-hour demo.
- Landing, legal, README, catalog, terminology, and deployment copy were
  rewritten to resolve every review 1 finding.
- `.factory/claims.json` and its demo-isolation proof now cover private
  workspace keys, licence keys, licence cache, request headers, reset, expiry,
  and same-origin demo requests.

## Verification before deployment

- Repair commit: `cab31b7ad31dd9034235797ace1aa66ff913ab5c`.
- Route-regression commit: `93abcb1f9f5363c33106690dac8819890ce46bf5`.
- A fresh clone at `93abcb1` received `npm ci` and passed `npm test`:
  TypeScript, Vite build, four Rust tests, runtime-defaults, durable-storage,
  shared-storage, deployment topology, and 21 Chromium tests passed.
- A separate fresh clone at `cab31b7` ran every exact command listed in
  `.factory/claims.json`; all 20 passed. The live checkout assertion observed
  HTTP 303 to Dodo, product `mtd-evidence-rail`, GBP 1500, monthly cadence.
- Local HTML/browser verification: `/opt/fleet/lib/verify-url.sh
  http://127.0.0.1:8081 .factory/evidence/polish-1/local-verify` passed with
  no console errors, `lang=en-GB`, one H1, a main landmark, and no missing alt
  text. Screenshots: `local-verify/screenshot-desktop.png` and
  `local-verify/screenshot-mobile.png`.
- The route accessibility test uses axe on `/`, `/?demo=1`, `/demo`, `/app`,
  `/privacy`, `/terms`, and a real 404, with zero violations.
- Built first-load JavaScript: 30.51 kB raw / 10.32 kB gzip; CSS: 16.96 kB raw
  / 4.80 kB gzip.

## Run and deploy

```sh
npm ci
npm test
npm run test:live-checkout
scripts/deploy.sh
```

The container starts on `PORT` with no required secret configuration. The
factory deployment mounts durable `/data`, runs one replica, and verifies the
live health SHA and restart persistence.

## Known gaps

None. Live deployment evidence is appended after the configured deployment.
