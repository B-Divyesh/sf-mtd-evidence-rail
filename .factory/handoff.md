# MTD Evidence Rail verification handoff

Completed 29 August 2026 for work order `mtd-evidence-rail-verify-3`.

## Result

**FAIL — do not release candidate
`d9774c5d70af912a520d2f349b4b10960ffd7e47`.**

The source candidate passes all 19 declared claim commands from a detached
clean worktree after `npm ci`, the complete `npm test`, strict TypeScript/Rust
checks, the locked release build, and independent local end-to-end
boundary/recovery checks. The exact candidate
is deployed: `/health` and 100 concurrent health responses report its full SHA,
and live HTML/JS/CSS hashes match the local production build.

Production is still release-blocked. Azure currently runs three replicas at
max scale with no `/data` mount, no volume, and no `SQLITE_VFS`. Each replica
therefore has a separate disposable SQLite database. After concurrency brought
all replicas into use, 14/15 applicable live tests failed. A final 12-browser
demo check failed 12/12: every `POST /api/demo` returned 201, then the immediate
`GET /api/workspace` returned 404. The required one-click demo and real private
workspaces are not reliable or durable.

Additional findings:

- High: absolute “unlimited transactions” and “unguessable key” copy is not
  represented by an exact claim test.
- Medium: three inline mobile links are under the required 44 px target height.
- Low: three section/404 labels use railway metaphor instead of plain task
  names.

Full commands, evidence, headers, rate-limit allowances, Lighthouse results,
and remediation are in [verification-3.md](verification-3.md). Key evidence is
under [`evidence/verification-3/`](evidence/verification-3/).

## Verification summary

- All 19 declared claims: PASS locally after locked install.
- `npm test`: PASS (4 Rust, 3 runtime/persistence scripts, 17 Chromium).
- `npm audit --audit-level=low`: PASS, 0 vulnerabilities.
- `cargo fmt --check`: PASS.
- `cargo clippy --all-targets --all-features -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- `npm run build`: PASS; `dist/` produced.
- Live topology check: **FAIL** (`max=3`, no mount/VFS).
- Live applicable Playwright: **FAIL**, 1/15 passed.
- Final fresh-browser demo: **FAIL**, 0/12 loaded.
- Live rate limit: 409/600 returned 429 with `Retry-After: 1`; 191 requests
  reached the three independent limiters during the 2.259-second burst.
- Factory URL smoke: PASS on landing.
- Axe serious/critical: 0 across all routes and the error state.
- Lighthouse mobile: 99 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.905 s, TBT 5 ms, CLS 0, transfer 180,628 bytes.

Docker/Podman were unavailable, so a second local image build was not run. The
live ACR image tag, build SHA, and asset hashes establish candidate identity.
No production restart was performed because that would mutate live state.

## Next action

Restore and preserve the one-replica Azure Files topology, then repeat the full
live verification after concurrency and a controlled revision restart. Do not
release until all fresh demo/private workspace reads survive both.

No product code was changed by this verifier.
