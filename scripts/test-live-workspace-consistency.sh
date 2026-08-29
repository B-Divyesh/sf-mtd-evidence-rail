#!/bin/bash
set -euo pipefail

base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
repo_dir=$(cd "$(dirname "$0")/.." && pwd)

"$repo_dir/scripts/assert-live-topology.sh"

workspace_id() {
  sed -n 's/.*"workspace_id":"\([^"]*\)".*/\1/p'
}

assert_reads() {
  local key=$1 label=$2 ip_group=$3 request_number status
  for request_number in $(seq 1 100); do
    status=$(curl -sS --http1.1 --max-time 15 -H 'Connection: close' \
      -H "X-Forwarded-For: 198.19.$ip_group.$request_number" \
      -H "X-Workspace-Key: $key" \
      -o /dev/null -w '%{http_code}' \
      "$base_url/api/workspace?from=2026-04-06&to=2026-07-05")
    if [ "$status" != 200 ]; then
      echo "$label read $request_number returned $status, expected 200" >&2
      exit 1
    fi
  done
}

private_key=$(curl -fsS --max-time 15 -H 'X-Forwarded-For: 198.19.0.1' -X POST "$base_url/api/workspace" | workspace_id)
demo_key=$(curl -fsS --max-time 15 -H 'X-Forwarded-For: 198.19.0.2' -X POST "$base_url/api/demo" | workspace_id)
test -n "$private_key"
test -n "$demo_key"
assert_reads "$private_key" private 1
assert_reads "$demo_key" demo 2

echo '@claim:live-workspace-consistency PASS — private and demo workspaces each returned 200 on 100/100 fresh-connection reads'
