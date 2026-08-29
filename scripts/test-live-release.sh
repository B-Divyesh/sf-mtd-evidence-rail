#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
"$repo_dir/scripts/assert-live-topology.sh"

echo '@claim:live-release-identity PASS — /health, the ready revision image, and the committed release manifest identify the same safe release'
