#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
"$repo_dir/scripts/assert-live-topology.sh"

echo '@claim:live-release-identity PASS — the candidate is tied to the published source; /health and the ready image identify that same safe release'
