#!/bin/bash
set -euo pipefail

# The factory's generic Container Apps deployer is deliberately not used here.
# It starts from a three-replica, container-local template, which is unsafe for
# this SQLite-backed product. Build the image, then apply the image and the
# source-owned durable topology together as one revision. The work order owns
# the existing /data storage and domain; this script never provisions either
# or reads a storage-account key.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
subscription=${AZURE_SUBSCRIPTION_ID:-283af945-693b-4a6e-b952-df928d0a18a9}
resource_group=sociobot
registry=sociobotregistry
app_name=sf-mtd-evidence-rail
hostname=mtd-evidence-rail.sociobot.in
app_uri="https://management.azure.com/subscriptions/${subscription}/resourceGroups/${resource_group}/providers/Microsoft.App/containerApps/${app_name}?api-version=2024-03-01"

patch_app() {
  local body=$1
  local output
  for attempt in $(seq 1 12); do
    if output=$(az rest --method patch --uri "$app_uri" --body "$body" --output none 2>&1); then
      return 0
    fi
    if printf '%s' "$output" | grep -qiE 'OperationInProgress|ContainerAppOperationInProgress|Too Many Requests|429|ServiceUnavailable|GatewayTimeout|InternalServerError'; then
      sleep $((attempt * 5))
      continue
    fi
    printf '%s\n' "$output" >&2
    return 1
  done
  printf '%s\n' "$output" >&2
  return 1
}

wait_for_candidate_readiness() {
  local resource state latest ready mount volume vfs minimum maximum active replicas deployed_image
  for _ in $(seq 1 60); do
    resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
    state=$(printf '%s' "$resource" | jq -r .properties.provisioningState)
    latest=$(printf '%s' "$resource" | jq -r .properties.latestRevisionName)
    ready=$(printf '%s' "$resource" | jq -r .properties.latestReadyRevisionName)
    deployed_image=$(printf '%s' "$resource" | jq -r .properties.template.containers[0].image)
    mount=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.containers[0].volumeMounts[]? | select(.volumeName == $volume_name)][0].mountPath // ""')
    volume=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.volumes[]? | select(.name == $volume_name)][0] | "\(.storageType // ""):\(.storageName // "")"')
    vfs=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].env[]? | select(.name == "SQLITE_VFS")][0].value // ""')
    minimum=$(printf '%s' "$resource" | jq -r .properties.template.scale.minReplicas)
    maximum=$(printf '%s' "$resource" | jq -r .properties.template.scale.maxReplicas)
    replicas=$(az containerapp replica list --resource-group "$resource_group" --name "$app_name" --revision "$ready" --query 'length(@)' --output tsv 2>/dev/null || true)
    if [ "$state" = Succeeded ] && [ "$latest" = "$ready" ] && [ "$deployed_image" = "$image" ] && [ "$mount" = "$mount_path" ] && [ "$volume" = "$storage_type:$storage_name" ] && [ "$vfs" = unix-dotfile ] && [ "$minimum" = 1 ] && [ "$maximum" = 1 ] && [ "$replicas" = 1 ]; then
      return 0
    fi
    sleep 5
  done
  echo "Candidate did not become a ready durable revision: state=$state latest=$latest ready=$ready image=$deployed_image mount=$mount volume=$volume vfs=$vfs min=$minimum max=$maximum replicas=$replicas" >&2
  return 1
}

deactivate_stale_revisions() {
  local ready stale_revision
  ready=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --query properties.latestReadyRevisionName --output tsv)
  for stale_revision in $(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query "[?properties.active==\`true\` && name != '$ready'].name" --output tsv); do
    echo "Deactivating stale revision $stale_revision after $ready became ready."
    az containerapp revision deactivate --resource-group "$resource_group" --name "$app_name" --revision "$stale_revision" --only-show-errors --output none
  done
}

wait_for_topology() {
  local resource latest ready active running
  for _ in $(seq 1 60); do
    resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
    latest=$(printf '%s' "$resource" | jq -r '.properties.latestRevisionName // ""')
    ready=$(printf '%s' "$resource" | jq -r '.properties.latestReadyRevisionName // ""')
    active=$(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query '[?properties.active==`true`] | length(@)' --output tsv)
    running=$(az containerapp replica list --resource-group "$resource_group" --name "$app_name" --revision "$ready" --query '[?properties.runningState==`Running`] | length(@)' --output tsv 2>/dev/null || true)
    if [ "$latest" = "$ready" ] && [ "$active" = 1 ] && [ "$running" = 1 ]; then
      return 0
    fi
    sleep 5
  done
  echo "Candidate ready revision was not the sole active running revision: latest=$latest ready=$ready active=$active running=$running" >&2
  return 1
}

source_sha=$(git -C "$repo_dir" rev-parse HEAD)
"$repo_dir/scripts/assert-build-inputs-committed.sh" "$repo_dir"
expected_image="${registry}.azurecr.io/${app_name}:${source_sha:0:12}"
image=${PREBUILT_IMAGE:-$expected_image}
if [ "$image" != "$expected_image" ]; then
  echo "Prebuilt image $image does not match committed source $expected_image." >&2
  exit 1
fi
volume_name=$(jq -r '.container.volumeMounts[0].volumeName' "$repo_dir/.factory/container-app.json")
mount_path=$(jq -r '.container.volumeMounts[0].mountPath' "$repo_dir/.factory/container-app.json")
storage_type=$(jq -r '.volumes[] | select(.name == $name) | .storageType' --arg name "$volume_name" "$repo_dir/.factory/container-app.json")
storage_name=$(jq -r '.volumes[] | select(.name == $name) | .storageName' --arg name "$volume_name" "$repo_dir/.factory/container-app.json")
test -n "$volume_name" && test -n "$mount_path" && test -n "$storage_type" && test -n "$storage_name"

# The work-order deployer may already have built this exact source image. Its
# post-deploy hook supplies PREBUILT_IMAGE so the product can repair the unsafe
# generic topology without rebuilding. Direct operation still builds in ACR.
if [ -z "${PREBUILT_IMAGE:-}" ]; then
  az acr build \
    --registry "$registry" \
    --image "${app_name}:${source_sha:0:12}" \
    --file Dockerfile \
    --build-arg "BUILD_SHA=$source_sha" \
    --build-arg "GIT_SHA=$source_sha" \
    --build-arg "SOURCE_COMMIT=$source_sha" \
    --only-show-errors \
    "$repo_dir"
else
  echo "Using work-order image $image; applying the product topology after the generic rollout."
fi

resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
patch=$(printf '%s' "$resource" | "$repo_dir/scripts/render-production-topology.sh" --image "$image")
patch_app "$patch"
wait_for_candidate_readiness
deactivate_stale_revisions
wait_for_topology

for _ in $(seq 1 60); do
  live_sha=$(curl -fsS --max-time 10 "https://${hostname}/health" 2>/dev/null | jq -r .build_sha 2>/dev/null || true)
  [ "$live_sha" = "$source_sha" ] && break
  sleep 5
done
[ "$live_sha" = "$source_sha" ]

EXPECTED_SHA="$source_sha" BASE_URL="https://${hostname}" \
  bash "$repo_dir/scripts/verify-live-topology.sh" --restart

echo "Deployed ${source_sha}; the live revision uses the mounted durable store, exactly one replica, and one rate limiter."
