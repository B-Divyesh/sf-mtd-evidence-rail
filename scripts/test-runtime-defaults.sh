#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
server_pid=""
cleanup() {
  if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

ln -s "$repo_dir/dist" "$tmp_dir/dist"
(
  cd "$tmp_dir"
  env -i PORT=8199 "$repo_dir/target/debug/mtd-evidence-rail" >server.log 2>&1
) &
server_pid=$!
for _ in $(seq 1 80); do
  response=$(curl -fsS http://127.0.0.1:8199/health 2>/dev/null || true)
  if printf '%s' "$response" | grep -q '"status":"ok"'; then
    echo '@claim:runtime-defaults PASS — server started with only PORT'
    exit 0
  fi
  sleep 0.1
done
cat "$tmp_dir/server.log" >&2
exit 1
