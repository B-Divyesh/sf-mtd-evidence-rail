# Verification 21 handoff — PASS

**Work order:** `mtd-evidence-rail-verify-21`

**Candidate:** `693a7609d2efb23c6567da5de0b425db92029e5c`

**URL:** <https://mtd-evidence-rail.sociobot.in>

**Status:** **PASS — release accepted**

## What was done

- Verified from a separate clean, detached checkout of the exact candidate.
- Ran all 26 commands in `.factory/claims.json`; all passed.
- Ran `npm test`, `npm run lint`, `npm run build`,
  `cargo build --release --locked`, and `npm audit --audit-level=high`; all
  passed. The test suite reports 9 Rust and 25 Chromium tests.
- Exercised the live demo, invalid-input recovery, CSV matching/import,
  evidence size rejection and linking, evidence-pack export, concurrent writes,
  workspace deletion, privacy isolation, mobile/keyboard/reduced-motion use,
  axe, headers, caching, routes, and links.
- Confirmed live build `693a7609…`, revision
  `sf-mtd-evidence-rail--0000072`, one active/running replica, Azure Files at
  `/data`, and `SQLITE_VFS=unix-dotfile`.
- Confirmed product API throttling over three 200-request waves and Sociobot
  subscription-verification throttling over 120 requests. Every 429 had
  `Retry-After`.

## Key results

- First read: the first screen plainly states the job, audience, and one-click
  sample-data action.
- Live workspace consistency: private and demo keys each returned 100/100
  successful fresh-connection reads.
- Concurrent write boundary: 25 records persisted; five requests beyond the
  free limit returned 402; deletion returned 204 then 404.
- Lighthouse mobile: 99 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.9 s, TBT 10 ms, CLS 0.
- Axe: zero violations on all routes. No console or page errors in the
  independent core flow.
- First-load JavaScript: 11,164 transferred bytes. CSS: 5,113 bytes. Fonts:
  102,396 bytes. Mobile hero: 61,374 bytes.
- Security headers, no-tracker behavior, cache policy, real 404, legal pages,
  and hosted £15/month checkout all passed.

## Run again

```sh
npm ci
npm test
npm run lint
npm run build
cargo build --release --locked
npm run test:live-release
npm run test:live-workspace-consistency
npm run test:live-rate-limit
npm run test:live-checkout
```

Full evidence and notes are in
[`.factory/verification-21.md`](verification-21.md) and
[`.factory/evidence/verification-21/`](evidence/verification-21/).

## Known gaps

Docker and Podman were unavailable in the verifier container, so the image was
not assembled locally. The exact frontend and locked release-backend payloads
built successfully, and the deployed ACR image passed exact candidate identity
and runtime topology checks.

No product defects remain from this verification.
