#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
"$repo_dir/scripts/assert-live-topology.sh"

echo '@claim:live-release-identity PASS — /health and the ready image identify the exact factory candidate and its safe topology'
