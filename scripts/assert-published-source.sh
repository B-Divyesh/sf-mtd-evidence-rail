#!/bin/bash
set -euo pipefail

# Bind a verification candidate to the bytes that are actually deployed. A
# candidate may be the published source itself. When evidence must be recorded
# after deployment, it may instead be one direct child that changes only the
# release manifest and handoff. Longer or product-changing gaps are rejected.
repo_dir=${1:-$(cd "$(dirname "$0")/.." && pwd)}
release_manifest=${RELEASE_MANIFEST:-"$repo_dir/.factory/release.json"}
candidate_sha=${CANDIDATE_SHA:-$(git -C "$repo_dir" rev-parse HEAD)}
published_sha=$(jq -er '.source_commit | select(test("^[0-9a-f]{40}$"))' "$release_manifest")

git -C "$repo_dir" cat-file -e "${candidate_sha}^{commit}"
git -C "$repo_dir" cat-file -e "${published_sha}^{commit}"

if [ "$candidate_sha" = "$published_sha" ]; then
  echo "Candidate is the exact published source $published_sha."
  exit 0
fi

parent_sha=$(git -C "$repo_dir" rev-parse "${candidate_sha}^" 2>/dev/null || true)
if [ "$parent_sha" != "$published_sha" ]; then
  echo "Candidate $candidate_sha is not the published source $published_sha or its direct metadata child." >&2
  exit 1
fi

unexpected_paths=$(git -C "$repo_dir" diff-tree --no-commit-id --name-only -r "$candidate_sha" |
  grep -Ev '^\.factory/(handoff\.md|release\.json)$' || true)
if [ -n "$unexpected_paths" ]; then
  echo "Metadata-only candidate $candidate_sha changes release inputs:" >&2
  printf '%s\n' "$unexpected_paths" >&2
  exit 1
fi

manifest_at_candidate=$(git -C "$repo_dir" show "${candidate_sha}:.factory/release.json" |
  jq -er '.source_commit | select(test("^[0-9a-f]{40}$"))')
if [ "$manifest_at_candidate" != "$published_sha" ]; then
  echo "Candidate release manifest names $manifest_at_candidate, expected $published_sha." >&2
  exit 1
fi

echo "Candidate $candidate_sha is the direct metadata-only child of published source $published_sha."
