#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

git -C "$fixture" init -q
git -C "$fixture" config user.name 'Release guard fixture'
git -C "$fixture" config user.email 'release-guard@example.invalid'
mkdir -p "$fixture/.factory" "$fixture/src"
printf 'fn main() {}\n' > "$fixture/src/main.rs"
printf '{"source_commit":"0000000000000000000000000000000000000000"}\n' > "$fixture/.factory/release.json"
printf '# Initial handoff\n' > "$fixture/.factory/handoff.md"
git -C "$fixture" add .
git -C "$fixture" commit -qm 'source'
source_sha=$(git -C "$fixture" rev-parse HEAD)

printf '{"source_commit":"%s"}\n' "$source_sha" > "$fixture/.factory/release.json"
printf '# Verified release\n' > "$fixture/.factory/handoff.md"
git -C "$fixture" add .factory
git -C "$fixture" commit -qm 'release evidence'
CANDIDATE_SHA=$(git -C "$fixture" rev-parse HEAD) \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null

# Reproduce the verification-17 loophole: a manifest can name an older live
# source while the candidate is no longer its direct evidence-only child.
printf 'changed product\n' >> "$fixture/src/main.rs"
git -C "$fixture" add src/main.rs
git -C "$fixture" commit -qm 'later product change'
if CANDIDATE_SHA=$(git -C "$fixture" rev-parse HEAD) \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null 2>&1; then
  echo 'Regression: a stale published source accepted a later candidate.' >&2
  exit 1
fi

# Even a direct child is not metadata-only if it changes a product file.
git -C "$fixture" switch --detach -q "$source_sha"
printf '{"source_commit":"%s"}\n' "$source_sha" > "$fixture/.factory/release.json"
printf 'changed product\n' >> "$fixture/src/main.rs"
git -C "$fixture" add .factory/release.json src/main.rs
git -C "$fixture" commit -qm 'mixed release and product change'
if CANDIDATE_SHA=$(git -C "$fixture" rev-parse HEAD) \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null 2>&1; then
  echo 'Regression: product changes passed as release-only metadata.' >&2
  exit 1
fi

echo 'Published-source guard PASS — exact source and one direct evidence-only child are accepted; stale or product-changing candidates are rejected.'
