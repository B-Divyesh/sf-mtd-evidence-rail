#!/bin/bash
set -euo pipefail

# A quiet multi-replica or stale-revision deployment can look healthy while an
# older process serves traffic. Require control-plane topology and the factory
# candidate's identity before any live data or limiter claim can run.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
app_name=${AZURE_CONTAINER_APP:-sf-mtd-evidence-rail}
base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
candidate_sha=${CANDIDATE_SHA:-$(git -C "$repo_dir" rev-parse HEAD)}
# A factory-supplied candidate is the release under test and takes precedence
# over legacy EXPECTED_SHA or release-manifest values left by earlier jobs.
expected_sha=${CANDIDATE_SHA:-${EXPECTED_SHA:-$candidate_sha}}
expected_image=${EXPECTED_IMAGE:-sociobotregistry.azurecr.io/${app_name}:${expected_sha:0:12}}
contract_file=${TOPOLOGY_CONTRACT:-"$repo_dir/.factory/container-app.json"}

if [[ ! "$expected_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Expected candidate SHA must be a 40-character lowercase Git SHA, got: $expected_sha" >&2
  exit 1
fi

command -v az >/dev/null || {
  echo 'Azure CLI is required to verify the live release.' >&2
  exit 1
}

volume_name=$(jq -r '.container.volumeMounts[0].volumeName' "$contract_file")
mount_path=$(jq -r '.container.volumeMounts[0].mountPath' "$contract_file")
storage_type=$(jq -r '.volumes[] | select(.name == $name) | .storageType' --arg name "$volume_name" "$contract_file")
storage_name=$(jq -r '.volumes[] | select(.name == $name) | .storageName' --arg name "$volume_name" "$contract_file")
vfs_name=$(jq -r '.container.environment[] | select(.name == "SQLITE_VFS") | .value' "$contract_file")

resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
mode=$(printf '%s' "$resource" | jq -r .properties.configuration.activeRevisionsMode)
minimum=$(printf '%s' "$resource" | jq -r .properties.template.scale.minReplicas)
maximum=$(printf '%s' "$resource" | jq -r .properties.template.scale.maxReplicas)
containers=$(printf '%s' "$resource" | jq -r '.properties.template.containers | length')
latest=$(printf '%s' "$resource" | jq -r '.properties.latestRevisionName // ""')
ready=$(printf '%s' "$resource" | jq -r '.properties.latestReadyRevisionName // ""')
mount=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.containers[0].volumeMounts[]? | select(.volumeName == $volume_name)][0].mountPath // ""')
volume=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.volumes[]? | select(.name == $volume_name)][0] | "\(.storageType // ""):\(.storageName // "")"')
vfs=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].env[]? | select(.name == "SQLITE_VFS")][0].value // ""')
active=$(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query '[?properties.active==`true`] | length(@)' --output tsv)
ready_resource=$(az containerapp revision show --resource-group "$resource_group" --name "$app_name" --revision "$ready" --output json)
ready_image=$(printf '%s' "$ready_resource" | jq -r '.properties.template.containers[0].image // ""')
ready_active=$(printf '%s' "$ready_resource" | jq -r '.properties.active // false')
running=$(az containerapp replica list --resource-group "$resource_group" --name "$app_name" --revision "$ready" --query '[?properties.runningState==`Running`] | length(@)' --output tsv)
health=$(curl -fsS --max-time 15 "$base_url/health")
live_sha=$(printf '%s' "$health" | jq -r '.build_sha // ""')

if [ "$mode" != Single ] || [ "$minimum" != 1 ] || [ "$maximum" != 1 ] || [ "$containers" != 1 ] ||
   [ "$mount" != "$mount_path" ] || [ "$volume" != "$storage_type:$storage_name" ] ||
   [ "$vfs" != "$vfs_name" ] || [ "$active" != 1 ] || [ "$running" != 1 ] ||
   [ "$latest" != "$ready" ] || [ "$ready_active" != true ] || [ "$ready_image" != "$expected_image" ] ||
   [ "$live_sha" != "$expected_sha" ]; then
  echo "Unsafe live release: expected_sha=$expected_sha live_sha=$live_sha expected_image=$expected_image ready_image=$ready_image latest=$latest ready=$ready ready_active=$ready_active mode=$mode min=$minimum max=$maximum containers=$containers mount=$mount volume=$volume vfs=$vfs active=$active running=$running" >&2
  exit 1
fi

echo "Live release: build=$live_sha; image=$ready_image; revision=$ready; Single; replicas=$minimum/$maximum; running=$running; $volume_name mounted at $mount; VFS=$vfs."
