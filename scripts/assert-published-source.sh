#!/bin/bash
set -euo pipefail

# Bind a verification candidate to the bytes that are actually deployed. A
# candidate may be the published source itself. Post-deploy evidence and the
# factory's generated code map may follow in one or more commits, but their
# cumulative diff must not change any product or deployment input.
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

if ! git -C "$repo_dir" merge-base --is-ancestor "$published_sha" "$candidate_sha"; then
  echo "Candidate $candidate_sha does not descend from published source $published_sha." >&2
  exit 1
fi

# Factory verification can add a report and its captured evidence after the
# product image has been published. Keep this list narrow: product contracts,
# claims, source, deployment inputs, and unclassified factory files must still
# force a new release. The fixture test covers every accepted path family.
release_neutral_paths='^(\.factory/(handoff\.md|plan\.md|release\.json|(review|verification|polish)-[0-9]+\.md|evidence/(review|verification|polish)-[0-9]+/.*)|graphify-out/)'
unexpected_paths=$(git -C "$repo_dir" diff --name-only "$published_sha..$candidate_sha" -- |
  grep -Ev "$release_neutral_paths" || true)
if [ -n "$unexpected_paths" ]; then
  echo "Release-neutral candidate $candidate_sha changes product or deployment inputs:" >&2
  printf '%s\n' "$unexpected_paths" >&2
  exit 1
fi

manifest_at_candidate=$(git -C "$repo_dir" show "${candidate_sha}:.factory/release.json" |
  jq -er '.source_commit | select(test("^[0-9a-f]{40}$"))')
if [ "$manifest_at_candidate" != "$published_sha" ]; then
  echo "Candidate release manifest names $manifest_at_candidate, expected $published_sha." >&2
  exit 1
fi

echo "Candidate $candidate_sha is a release-neutral descendant of published source $published_sha."
