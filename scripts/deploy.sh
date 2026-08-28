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

/opt/fleet/lib/deploy-container.sh mtd-evidence-rail "$repo_dir" Dockerfile 8080

az containerapp revision set-mode \
  --resource-group "$resource_group" \
  --name "$app_name" \
  --mode single \
  --output none

resource=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
patch=$(printf '%s' "$resource" | jq -c '{properties:{template:{containers:[.properties.template.containers[0] + {volumeMounts:[{volumeName:"data",mountPath:"/data"}]}],scale:(.properties.template.scale + {minReplicas:1,maxReplicas:1}),volumes:[{name:"data",storageName:"mtd-evidence-rail-data",storageType:"AzureFile"}]}}}')
az rest \
  --method patch \
  --uri "https://management.azure.com/subscriptions/${subscription}/resourceGroups/${resource_group}/providers/Microsoft.App/containerApps/${app_name}?api-version=2024-03-01" \
  --body "$patch" \
  --output none

echo "Deployed one replica with durable Azure Files storage mounted at /data."
