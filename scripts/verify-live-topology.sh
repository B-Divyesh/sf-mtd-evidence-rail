#!/bin/bash
set -euo pipefail

base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
expected_sha=${EXPECTED_SHA:-}
restart=${1:-}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
app_name=${AZURE_CONTAINER_APP:-sf-mtd-evidence-rail}

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
  command -v az >/dev/null || return
  resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
  mode=$(printf '%s' "$resource" | jq -r .properties.configuration.activeRevisionsMode)
  minimum=$(printf '%s' "$resource" | jq -r .properties.template.scale.minReplicas)
  maximum=$(printf '%s' "$resource" | jq -r .properties.template.scale.maxReplicas)
  containers=$(printf '%s' "$resource" | jq -r '.properties.template.containers | length')
  mount=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].volumeMounts[]? | select(.volumeName == "data")][0].mountPath // ""')
  volume=$(printf '%s' "$resource" | jq -r '[.properties.template.volumes[]? | select(.name == "data")][0] | "\(.storageType // ""):\(.storageName // "")"')
  vfs=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].env[]? | select(.name == "SQLITE_VFS")][0].value // ""')
  active=$(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query '[?properties.active==`true`] | length(@)' --output tsv)
  revision=$(printf '%s' "$resource" | jq -r .properties.latestReadyRevisionName)
  replicas=$(az containerapp replica list --resource-group "$resource_group" --name "$app_name" --revision "$revision" --query 'length(@)' --output tsv)
  [ "$mode" = Single ] && [ "$minimum" = 1 ] && [ "$maximum" = 1 ] && [ "$containers" = 1 ] && [ "$mount" = /data ] && [ "$volume" = AzureFile:mtd-evidence-rail-data ] && [ "$vfs" = unix-dotfile ] && [ "$active" = 1 ] && [ "$replicas" = 1 ] || {
    echo "Unsafe topology: mode=$mode min=$minimum max=$maximum containers=$containers mount=$mount volume=$volume vfs=$vfs active=$active replicas=$replicas" >&2
    exit 1
  }
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

assert_shared_limiter() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  for request_number in $(seq 1 120); do
    curl -sS --http1.1 -H 'Connection: close' \
      -H 'X-Forwarded-For: 198.18.3.1' \
      -D "$tmp_dir/$request_number.headers" \
      -o /dev/null -w '%{http_code}' \
      "$base_url/api/workspace" > "$tmp_dir/$request_number.status" &
  done
  wait
  local accepted rejected
  if grep -L -E '^(401|429)$' "$tmp_dir"/*.status >/dev/null; then
    echo "Limiter probe returned an unexpected or empty status" >&2
    rm -rf "$tmp_dir"
    exit 1
  fi
  accepted=$(grep -L '^429$' "$tmp_dir"/*.status | wc -l)
  rejected=$(grep -l '^429$' "$tmp_dir"/*.status | wc -l)
  [ "$accepted" -le 80 ] && [ "$rejected" -ge 40 ] || {
    echo "Limiter was not shared: accepted=$accepted rejected=$rejected" >&2
    rm -rf "$tmp_dir"
    exit 1
  }
  while IFS= read -r status_file; do
    header_file=${status_file%.status}.headers
    grep -qi '^retry-after: 1' "$header_file" || {
      echo "A 429 response lacked Retry-After: 1" >&2
      rm -rf "$tmp_dir"
      exit 1
    }
  done < <(grep -l '^429$' "$tmp_dir"/*.status)
  rm -rf "$tmp_dir"
  echo "shared limiter: $rejected/120 requests returned 429; $accepted reached the one-replica allowance."
}

wait_for_health
assert_control_plane
private_key=$(curl -fsS -H 'X-Forwarded-For: 198.18.1.1' -X POST "$base_url/api/workspace" | workspace_id)
demo_key=$(curl -fsS -H 'X-Forwarded-For: 198.18.1.2' -X POST "$base_url/api/demo" | workspace_id)
test -n "$private_key"
test -n "$demo_key"
assert_reads "$private_key" private
assert_reads "$demo_key" demo
node "$(dirname "$0")/live-browser-smoke.mjs" "$base_url"
assert_shared_limiter

if [ "$restart" = --restart ]; then
  command -v az >/dev/null || { echo 'Azure CLI is required for --restart.' >&2; exit 1; }
  revision=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --query properties.latestReadyRevisionName --output tsv)
  az containerapp revision restart --resource-group "$resource_group" --name "$app_name" --revision "$revision" --output none
  wait_for_health
  assert_control_plane
  assert_reads "$private_key" private-after-restart
  assert_reads "$demo_key" demo-after-restart
  node "$(dirname "$0")/live-browser-smoke.mjs" "$base_url"
  assert_shared_limiter
fi

echo "Live topology verification passed for build $live_sha."
