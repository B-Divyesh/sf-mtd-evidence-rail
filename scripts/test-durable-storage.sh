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

start_server() {
  STATIC_DIR="$repo_dir/dist" DATA_DIR="$tmp_dir/data" SQLITE_VFS=unix-dotfile PORT=8200 \
    "$repo_dir/target/debug/mtd-evidence-rail" >"$tmp_dir/server.log" 2>&1 &
  server_pid=$!
  for _ in $(seq 1 80); do
    curl -fsS http://127.0.0.1:8200/health >/dev/null 2>&1 && return
    sleep 0.1
  done
  cat "$tmp_dir/server.log" >&2
  exit 1
}

start_server
workspace=$(curl -fsS -X POST http://127.0.0.1:8200/api/workspace | sed -n 's/.*"workspace_id":"\([^"]*\)".*/\1/p')
test -n "$workspace"
kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
server_pid=""
start_server
status=$(curl -sS -o "$tmp_dir/body" -w '%{http_code}' -H "X-Workspace-Key: $workspace" http://127.0.0.1:8200/api/workspace)
test "$status" = 200
echo '@claim:durable-storage PASS — workspace survived a server restart'
