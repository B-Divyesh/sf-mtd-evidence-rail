#!/bin/bash
set -euo pipefail

# The image reports the Git commit supplied by the deployer. Only let that
# identity stand for the release when every image input and the source-owned
# deployment contract are committed. Evidence and working notes are
# deliberately outside this list: Docker never copies them into the image.
repo_dir=${1:-$(cd "$(dirname "$0")/.." && pwd)}
build_inputs=(
  Dockerfile
  package.json
  package-lock.json
  tsconfig.json
  vite.config.ts
  Cargo.toml
  Cargo.lock
  frontend
  migrations
  src
  scripts
  .factory/container-app.json
)

git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null

if ! git -C "$repo_dir" diff --quiet HEAD -- "${build_inputs[@]}" ||
   ! git -C "$repo_dir" diff --cached --quiet HEAD -- "${build_inputs[@]}" ||
   [ -n "$(git -C "$repo_dir" status --porcelain --untracked-files=all -- "${build_inputs[@]}")" ]; then
  echo 'Refusing deployment: release build inputs are not committed at HEAD.' >&2
  exit 1
fi

echo "Committed Docker build inputs verified at $(git -C "$repo_dir" rev-parse HEAD)."
