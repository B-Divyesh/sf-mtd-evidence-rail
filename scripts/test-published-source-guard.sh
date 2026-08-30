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

# Reproduce verification 18 exactly: the factory adds a generated code-map
# commit after the release-evidence commit. The candidate still represents the
# published bytes because its cumulative delta is release-neutral.
mkdir -p "$fixture/graphify-out/cache"
printf '{}\n' > "$fixture/graphify-out/cache/stat-index.json"
printf '{}\n' > "$fixture/graphify-out/graph.json"
printf '{}\n' > "$fixture/graphify-out/manifest.json"
git -C "$fixture" add graphify-out
git -C "$fixture" commit -qm 'factory code map'
wrapped_candidate=$(git -C "$fixture" rev-parse HEAD)
CANDIDATE_SHA="$wrapped_candidate" \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null

# A generated code-map commit is never allowed to hide a product change. The
# cumulative source-to-candidate diff must still reject this later revision.
printf 'changed product\n' >> "$fixture/src/main.rs"
git -C "$fixture" add src/main.rs
git -C "$fixture" commit -qm 'later product change'
if CANDIDATE_SHA=$(git -C "$fixture" rev-parse HEAD) \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null 2>&1; then
  echo 'Regression: a stale published source accepted a later candidate.' >&2
  exit 1
fi

# A candidate from another line of history must fail even when its visible
# files happen to match the published source.
unrelated_candidate=$(printf 'unrelated candidate\n' |
  git -C "$fixture" commit-tree "${wrapped_candidate}^{tree}")
if CANDIDATE_SHA="$unrelated_candidate" \
  "$repo_dir/scripts/assert-published-source.sh" "$fixture" >/dev/null 2>&1; then
  echo 'Regression: an unrelated candidate passed the ancestry guard.' >&2
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

echo 'Published-source guard PASS — exact source and release-neutral factory descendants are accepted; unrelated or product-changing candidates are rejected.'
