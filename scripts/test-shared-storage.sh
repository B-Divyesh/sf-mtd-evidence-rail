#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
ports=(8210 8211 8212)
pids=()

cleanup() {
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

start_instances() {
  pids=()
  for port in "${ports[@]}"; do
    STATIC_DIR="$repo_dir/dist" DATA_DIR="$tmp_dir/data" SQLITE_VFS=unix-dotfile PORT="$port" \
      "$repo_dir/target/debug/mtd-evidence-rail" >"$tmp_dir/server-$port.log" 2>&1 &
    pids+=("$!")
    for _ in $(seq 1 100); do
      curl -fsS "http://127.0.0.1:$port/health" >/dev/null 2>&1 && break
      sleep 0.1
    done
    curl -fsS "http://127.0.0.1:$port/health" >/dev/null || {
      cat "$tmp_dir/server-$port.log" >&2
      exit 1
    }
  done
}

stop_instances() {
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done
  pids=()
}

workspace_id() {
  sed -n 's/.*"workspace_id":"\([^"]*\)".*/\1/p'
}

assert_reads() {
  local key=$1
  local label=$2
  local count=$3
  for request_number in $(seq 1 "$count"); do
    local port=${ports[$(((request_number - 1) % ${#ports[@]}))]}
    local status
    status=$(curl -sS --http1.1 -H 'Connection: close' \
      -H "X-Workspace-Key: $key" \
      -o /dev/null -w '%{http_code}' \
      "http://127.0.0.1:$port/api/workspace?from=2026-04-06&to=2026-07-05")
    if [ "$status" != 200 ]; then
      echo "$label read $request_number through port $port returned $status" >&2
      exit 1
    fi
  done
}

start_instances
private_key=$(curl -fsS -X POST "http://127.0.0.1:${ports[0]}/api/workspace" | workspace_id)
demo_key=$(curl -fsS -X POST "http://127.0.0.1:${ports[1]}/api/demo" | workspace_id)
test -n "$private_key"
test -n "$demo_key"
assert_reads "$private_key" private 100
assert_reads "$demo_key" demo 100

stop_instances
start_instances
assert_reads "$private_key" private-after-restart 100
assert_reads "$demo_key" demo-after-restart 100

echo '@claim:shared-state-boundary PASS — three processes returned 400/400 workspace reads before and after restart'
