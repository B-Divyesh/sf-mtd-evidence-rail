# Verification 16 handoff — FAIL

**Candidate:** `560392b27a89568a3e88ca461b060f42fec7e61f`

**Live URL:** <https://mtd-evidence-rail.sociobot.in>

**Verified:** 29 August 2026 UTC

**Status:** **FAIL — do not release**

## Release blocker

Fresh required claim tests show the live Azure Container App in an unsafe state:

```text
latest=sf-mtd-evidence-rail--0000054
ready=sf-mtd-evidence-rail--0000053
mode=Single min=1 max=3
mount= volume=: vfs=
active=2 running=1
```

The service stores financial evidence in SQLite, yet production may scale to
three replicas and has no Azure Files `/data` mount or required
`SQLITE_VFS=unix-dotfile`. Three mandatory claims fail:

- `npm run test:live-workspace-consistency`
- `npm run test:live-release`
- `npm run test:live-rate-limit`

This is release blocking even though the currently running replica served all
fresh functional probes successfully.

## What passed

- Cold first-read and one-click sample demo.
- 23/26 declared claims from a detached candidate checkout.
- `npm test` (7 Rust tests and 25 Chromium tests).
- `npm run lint`, `npm run build`, and `cargo build --release --locked`.
- Live add/validate/link/import/missing/export/reset flow and API boundaries.
- Independent limiter burst: 47 accepted, 153 limited; every 429 had
  `Retry-After: 1`.
- Live fresh-connection reads: private 100/100 and demo 100/100; deleted private
  workspace 404 on 20/20 reads.
- Axe: zero violations on six routes at desktop and 390 px; keyboard, focus,
  reduced motion, touch targets, 200% text, and mobile overflow checks pass.
- Lighthouse mobile: 99 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.80 s, TBT 80 ms, CLS 0.
- No third-party core-flow request, console error, page error, or broken link.
- Security headers and caching policy pass; JS/CSS/font/hero budgets pass.
- Hosted checkout redirects to Dodo for GBP 15/month.

The live HTML/JS/CSS are byte-identical to the candidate build. `/health`
identifies published product source `5779508…`; candidate `560392b…` adds only
factory metadata/graph changes after that source commit.

## Environment limitation

Docker, Podman, Buildah, and nerdctl are unavailable, so the container image
could not be rebuilt locally. The Dockerfile's frontend and locked Rust release
build stages were run directly and passed.

## Required next step

Deploy the source-owned topology with one active ready revision,
`minReplicas=maxReplicas=1`, Azure Files mounted at `/data`, and
`SQLITE_VFS=unix-dotfile`. Re-run the three failed live claims and a real
restart-backed persistence check before changing the verdict.

Full findings: [`.factory/verification-16.md`](verification-16.md). Evidence:
[`.factory/evidence/verification-16`](evidence/verification-16/).
