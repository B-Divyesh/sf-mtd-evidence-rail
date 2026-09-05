#!/bin/bash
set -euo pipefail

base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
source_repo=${SOURCE_REPO:-$repo_dir}
candidate_sha=${CANDIDATE_SHA:-$(git -C "$source_repo" rev-parse HEAD)}
release_manifest=${RELEASE_MANIFEST:-"$source_repo/.factory/release.json"}
if [ -n "${CANDIDATE_SHA:-}" ]; then
  expected_sha=$CANDIDATE_SHA
elif [ -n "${EXPECTED_SHA:-}" ]; then
  expected_sha=$EXPECTED_SHA
else
  CANDIDATE_SHA="$candidate_sha" RELEASE_MANIFEST="$release_manifest" \
    "$repo_dir/scripts/assert-published-source.sh" "$source_repo" >/dev/null
  expected_sha=$(jq -er '.source_commit | select(test("^[0-9a-f]{40}$"))' "$release_manifest")
fi
restart=${1:-}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
app_name=${AZURE_CONTAINER_APP:-sf-mtd-evidence-rail}
contract_file=${TOPOLOGY_CONTRACT:-"$repo_dir/.factory/container-app.json"}

if [[ ! "$expected_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Expected candidate SHA must be a 40-character lowercase Git SHA, got: $expected_sha" >&2
  exit 1
fi

# The Azure volume name is part of the deployment contract, not an incidental
# implementation detail. Read it from the source-owned manifest so this probe
# catches a renamed live volume as well as missing storage.
volume_name=$(jq -r '.container.volumeMounts[0].volumeName' "$contract_file")
mount_path=$(jq -r '.container.volumeMounts[0].mountPath' "$contract_file")
storage_type=$(jq -r '.volumes[] | select(.name == $name) | .storageType' --arg name "$volume_name" "$contract_file")
storage_name=$(jq -r '.volumes[] | select(.name == $name) | .storageName' --arg name "$volume_name" "$contract_file")
vfs_name=$(jq -r '.container.environment[] | select(.name == "SQLITE_VFS") | .value' "$contract_file")

test -n "$volume_name" && test -n "$mount_path" && test -n "$storage_type" && test -n "$storage_name" && test -n "$vfs_name"

workspace_id() {
  sed -n 's/.*"workspace_id":"\([^"]*\)".*/\1/p'
}

wait_for_health() {
  for _ in $(seq 1 60); do
    health=$(curl -fsS --max-time 10 "$base_url/health" 2>/dev/null || true)
    live_sha=$(printf '%s' "$health" | sed -n 's/.*"build_sha":"\([^"]*\)".*/\1/p')
    if [ -n "$live_sha" ] && { [ -z "$expected_sha" ] || [ "$live_sha" = "$expected_sha" ]; }; then
      return
    fi
    sleep 5
  done
  echo "Live health did not report expected build $expected_sha" >&2
  exit 1
}

assert_control_plane() {
  EXPECTED_SHA="$expected_sha" BASE_URL="$base_url" \
    AZURE_RESOURCE_GROUP="$resource_group" AZURE_CONTAINER_APP="$app_name" \
    TOPOLOGY_CONTRACT="$contract_file" "$repo_dir/scripts/assert-live-topology.sh"
}

assert_reads() {
  local key=$1
  local label=$2
  for request_number in $(seq 1 100); do
    octet=$(((request_number - 1) % 250 + 1))
    status=$(curl -sS --http1.1 -H 'Connection: close' \
      -H "X-Forwarded-For: 198.18.0.$octet" \
      -H "X-Workspace-Key: $key" \
      -o /dev/null -w '%{http_code}' \
      "$base_url/api/workspace?from=2026-04-06&to=2026-07-05")
    if [ "$status" != 200 ]; then
      echo "$label read $request_number returned $status" >&2
      exit 1
    fi
  done
  echo "$label: 100/100 fresh-connection reads returned 200."
}

assert_workspace_delete() {
  local key=$1 status
  status=$(curl -sS --http1.1 -H 'Connection: close' \
    -H 'X-Forwarded-For: 198.18.2.1' \
    -H "X-Workspace-Key: $key" \
    -X DELETE -o /dev/null -w '%{http_code}' "$base_url/api/workspace")
  [ "$status" = 400 ] || {
    echo "Workspace delete without confirmation returned $status, expected 400" >&2
    exit 1
  }
  status=$(curl -sS --http1.1 -H 'Connection: close' \
    -H 'X-Forwarded-For: 198.18.2.2' \
    -H "X-Workspace-Key: $key" -H 'X-Confirm-Delete: delete' \
    -X DELETE -o /dev/null -w '%{http_code}' "$base_url/api/workspace")
  [ "$status" = 204 ] || {
    echo "Confirmed workspace delete returned $status, expected 204" >&2
    exit 1
  }
  assert_workspace_is_deleted "$key" deleted
}

assert_workspace_is_deleted() {
  local key=$1 label=$2 status request_number
  for request_number in $(seq 1 20); do
    status=$(curl -sS --http1.1 -H 'Connection: close' \
      -H "X-Forwarded-For: 198.18.2.$((request_number + 2))" \
      -H "X-Workspace-Key: $key" -o /dev/null -w '%{http_code}' \
      "$base_url/api/workspace?from=2026-04-06&to=2026-07-05")
    [ "$status" = 404 ] || {
      echo "$label workspace read $request_number returned $status, expected 404" >&2
      exit 1
    }
  done
  echo "$label workspace: 20/20 fresh reads returned 404."
}

assert_shared_limiter() {
  local attempt tmp_dir accepted rejected unexpected status status_file header_file started_ms elapsed_ms one_limiter_max
  for attempt in 1 2 3; do
    tmp_dir=$(mktemp -d)
    started_ms=$(date +%s%3N)
    for request_number in $(seq 1 240); do
      curl -sS --http1.1 --max-time 20 -H 'Connection: close' \
        -H "X-Forwarded-For: 198.18.3.$attempt" \
        -D "$tmp_dir/$request_number.headers" \
        -o /dev/null -w '%{http_code}' \
        "$base_url/api/workspace" > "$tmp_dir/$request_number.status" &
    done
    wait
    accepted=0
    rejected=0
    unexpected=0
    for status_file in "$tmp_dir"/*.status; do
      status=$(tr -d '\r\n' < "$status_file")
      case "$status" in
        401) accepted=$((accepted + 1)) ;;
        429) rejected=$((rejected + 1)) ;;
        *) unexpected=$((unexpected + 1)) ;;
      esac
    done
    if [ "$unexpected" -ne 0 ]; then
      echo "Limiter attempt $attempt had $unexpected unexpected statuses: $(sort "$tmp_dir"/*.status | uniq -c | tr '\n' ' ')" >&2
      rm -rf "$tmp_dir"
      sleep 2
      continue
    fi
    elapsed_ms=$(($(date +%s%3N) - started_ms))
    one_limiter_max=$((40 + (elapsed_ms + 49) / 50 + 5))
    if [ "$accepted" -gt "$one_limiter_max" ] || [ "$rejected" -lt 1 ]; then
      echo "Limiter attempt $attempt exceeded one-process bounds: accepted=$accepted rejected=$rejected bound=$one_limiter_max elapsed=${elapsed_ms}ms" >&2
      rm -rf "$tmp_dir"
      sleep 2
      continue
    fi
    while IFS= read -r status_file; do
      header_file=${status_file%.status}.headers
      grep -qi '^retry-after: 1' "$header_file" || {
        echo "A 429 response lacked Retry-After: 1" >&2
        rm -rf "$tmp_dir"
        exit 1
      }
    done < <(grep -l '^429$' "$tmp_dir"/*.status)
    rm -rf "$tmp_dir"
    echo "shared limiter: $rejected/240 requests returned 429; accepted=$accepted within one-limiter bound=$one_limiter_max over ${elapsed_ms}ms."
    return
  done
  echo "One-replica limiter probe did not produce a stable shared allowance." >&2
  exit 1
}

wait_for_health
assert_control_plane
if [ "$restart" = --limiter-only ]; then
  assert_shared_limiter
  exit 0
fi
private_key=$(curl -fsS -H 'X-Forwarded-For: 198.18.1.1' -X POST "$base_url/api/workspace" | workspace_id)
demo_key=$(curl -fsS -H 'X-Forwarded-For: 198.18.1.2' -X POST "$base_url/api/demo" | workspace_id)
test -n "$private_key"
test -n "$demo_key"
assert_reads "$private_key" private
assert_reads "$demo_key" demo
assert_workspace_delete "$private_key"
node "$(dirname "$0")/live-browser-smoke.mjs" "$base_url"
assert_shared_limiter

if [ "$restart" = --restart ]; then
  command -v az >/dev/null || { echo 'Azure CLI is required for --restart.' >&2; exit 1; }
  revision=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --query properties.latestReadyRevisionName --output tsv)
  az containerapp revision restart --resource-group "$resource_group" --name "$app_name" --revision "$revision" --output none
  wait_for_health
  assert_control_plane
  assert_reads "$demo_key" demo-after-restart
  assert_workspace_is_deleted "$private_key" deleted-after-restart
  node "$(dirname "$0")/live-browser-smoke.mjs" "$base_url"
  assert_shared_limiter
fi

echo "Live topology verification passed for build $live_sha."
