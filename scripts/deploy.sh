#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
subscription=${AZURE_SUBSCRIPTION_ID:-283af945-693b-4a6e-b952-df928d0a18a9}
resource_group=sociobot
environment=factory-env
storage_account=sociobotblob
storage_name=mtd-evidence-rail-data
share_name=sf-mtd-evidence-rail-data
app_name=sf-mtd-evidence-rail
hostname=mtd-evidence-rail.sociobot.in
app_uri="https://management.azure.com/subscriptions/${subscription}/resourceGroups/${resource_group}/providers/Microsoft.App/containerApps/${app_name}?api-version=2024-03-01"

patch_app() {
  local body=$1
  for attempt in $(seq 1 12); do
    if az rest --method patch --uri "$app_uri" --body "$body" --output none 2>/dev/null; then return 0; fi
    sleep 5
  done
  return 1
}

wait_for_app() {
  for attempt in $(seq 1 30); do
    local state
    state=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --query properties.provisioningState --output tsv)
    [ "$state" = Succeeded ] && return 0
    sleep 5
  done
  return 1
}

az storage share-rm create \
  --resource-group "$resource_group" \
  --storage-account "$storage_account" \
  --name "$share_name" \
  --quota 5 \
  --enabled-protocols SMB \
  --only-show-errors \
  --output none

storage_key=$(az storage account keys list \
  --resource-group "$resource_group" \
  --account-name "$storage_account" \
  --query '[0].value' \
  --output tsv)

az containerapp env storage set \
  --resource-group "$resource_group" \
  --name "$environment" \
  --storage-name "$storage_name" \
  --access-mode ReadWrite \
  --azure-file-account-name "$storage_account" \
  --azure-file-account-key "$storage_key" \
  --azure-file-share-name "$share_name" \
  --only-show-errors \
  --output none
unset storage_key

source_sha=$(git -C "$repo_dir" rev-parse HEAD)
if ! /opt/fleet/lib/deploy-container.sh mtd-evidence-rail "$repo_dir" Dockerfile 8080; then
  current_image=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --query properties.template.containers[0].image --output tsv)
  if [[ "$current_image" != *":${source_sha:0:12}" ]]; then
    echo "Container deployment failed before the requested image was installed." >&2
    exit 1
  fi
  echo "The image was installed; continuing after a transient hostname update failure."
fi
wait_for_app

az containerapp revision set-mode \
  --resource-group "$resource_group" \
  --name "$app_name" \
  --mode single \
  --output none

resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
patch=$(printf '%s' "$resource" | "$repo_dir/scripts/render-production-topology.sh")
az rest \
  --method patch \
  --uri "https://management.azure.com/subscriptions/${subscription}/resourceGroups/${resource_group}/providers/Microsoft.App/containerApps/${app_name}?api-version=2024-03-01" \
  --body "$patch" \
  --output none

wait_for_app
for attempt in $(seq 1 30); do
  resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
  latest=$(printf '%s' "$resource" | jq -r .properties.latestRevisionName)
  ready=$(printf '%s' "$resource" | jq -r .properties.latestReadyRevisionName)
  mount=$(printf '%s' "$resource" | jq -r '.properties.template.containers[0].volumeMounts[0].mountPath // ""')
  vfs=$(printf '%s' "$resource" | jq -r '[.properties.template.containers[0].env[]? | select(.name == "SQLITE_VFS")][0].value // ""')
  maximum=$(printf '%s' "$resource" | jq -r .properties.template.scale.maxReplicas)
  active=$(az containerapp revision list --resource-group "$resource_group" --name "$app_name" --query '[?properties.active==`true`] | length(@)' --output tsv)
  [ "$latest" = "$ready" ] && [ "$mount" = /data ] && [ "$vfs" = unix-dotfile ] && [ "$maximum" = 1 ] && [ "$active" = 1 ] && break
  sleep 5
done
[ "$latest" = "$ready" ] && [ "$mount" = /data ] && [ "$vfs" = unix-dotfile ] && [ "$maximum" = 1 ] && [ "$active" = 1 ]

domain_binding=$(printf '%s' "$resource" | jq -r --arg hostname "$hostname" '[.properties.configuration.ingress.customDomains[]? | select(.name == $hostname)][0].bindingType // ""')
if [ "$domain_binding" != SniEnabled ]; then
  disabled=$(jq -nc --arg hostname "$hostname" '{properties:{configuration:{ingress:{customDomains:[{name:$hostname,bindingType:"Disabled"}]}}}}')
  patch_app "$disabled"
  wait_for_app
  certificate_id="/subscriptions/${subscription}/resourceGroups/${resource_group}/providers/Microsoft.App/managedEnvironments/${environment}/managedCertificates/cert-mtd-evidence-rail"
  enabled=$(jq -nc --arg hostname "$hostname" --arg certificate "$certificate_id" '{properties:{configuration:{ingress:{customDomains:[{name:$hostname,bindingType:"SniEnabled",certificateId:$certificate}]}}}}')
  patch_app "$enabled"
  wait_for_app
fi

for attempt in $(seq 1 30); do
  live_sha=$(curl -fsS --max-time 10 "https://${hostname}/health" 2>/dev/null | jq -r .build_sha 2>/dev/null || true)
  [ "$live_sha" = "$source_sha" ] && break
  sleep 5
done
[ "$live_sha" = "$source_sha" ]

EXPECTED_SHA="$source_sha" BASE_URL="https://${hostname}" \
  bash "$repo_dir/scripts/verify-live-topology.sh" --restart

echo "Deployed ${source_sha}; one active replica, one limiter, and restart persistence are verified."
