#!/bin/bash
set -euo pipefail

# A quiet three-replica deployment can look healthy while only one replica is
# running. Check the declared Azure topology before any live data or limiter
# claim so those claims cannot pass by chance between scale-out events.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
app_name=${AZURE_CONTAINER_APP:-sf-mtd-evidence-rail}
contract_file=${TOPOLOGY_CONTRACT:-"$repo_dir/.factory/container-app.json"}

command -v az >/dev/null || {
  echo 'Azure CLI is required to verify the live deployment topology.' >&2
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
mount=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.containers[0].volumeMounts[]? | select(.volumeName == $volume_name)][0].mountPath // ""')
volume=$(printf '%s' "$resource" | jq -r --arg volume_name "$volume_name" '[.properties.template.volumes[]? | select(.name == $volume_name)][0] | "\(.storageType // ""):\(.storageName // "")"')
vfs=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].env[]? | select(.name == "SQLITE_VFS")][0].value // ""')
active=$(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query '[?properties.active==`true`] | length(@)' --output tsv)
revision=$(printf '%s' "$resource" | jq -r .properties.latestReadyRevisionName)
running=$(az containerapp replica list --resource-group "$resource_group" --name "$app_name" --revision "$revision" --query '[?properties.runningState==`Running`] | length(@)' --output tsv)

if [ "$mode" != Single ] || [ "$minimum" != 1 ] || [ "$maximum" != 1 ] || [ "$containers" != 1 ] ||
   [ "$mount" != "$mount_path" ] || [ "$volume" != "$storage_type:$storage_name" ] ||
   [ "$vfs" != "$vfs_name" ] || [ "$active" != 1 ] || [ "$running" != 1 ]; then
  echo "Unsafe live topology: mode=$mode min=$minimum max=$maximum containers=$containers mount=$mount volume=$volume vfs=$vfs active=$active running=$running" >&2
  exit 1
fi

echo "Live topology: Single; replicas=$minimum/$maximum; running=$running; $volume_name mounted at $mount; VFS=$vfs."
