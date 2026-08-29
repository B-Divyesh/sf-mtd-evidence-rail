#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

jq -n '{properties:{configuration:{activeRevisionsMode:"Single"},template:{containers:[{name:"app",image:"example.invalid/app:test",env:[{name:"PORT",value:"8080"}],resources:{cpu:0.5,memory:"1Gi"}}],scale:{minReplicas:1,maxReplicas:3},volumes:null}}}' > "$tmp_dir/unsafe.json"

"$repo_dir/scripts/render-production-topology.sh" "$tmp_dir/unsafe.json" > "$tmp_dir/patch.json"

test "$(jq -r '.properties.configuration.activeRevisionsMode' "$tmp_dir/patch.json")" = Single
test "$(jq -r '.properties.template.scale.minReplicas' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.scale.maxReplicas' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.containers | length' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.containers[0].volumeMounts[0].volumeName' "$tmp_dir/patch.json")" = mtd-data
test "$(jq -r '.properties.template.containers[0].volumeMounts[0].mountPath' "$tmp_dir/patch.json")" = /data
test "$(jq -r '.properties.template.volumes[0].name' "$tmp_dir/patch.json")" = mtd-data
test "$(jq -r '.properties.template.volumes[0].storageType' "$tmp_dir/patch.json")" = AzureFile
test "$(jq -r '.properties.template.volumes[0].storageName' "$tmp_dir/patch.json")" = mtd-evidence-rail-data
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")][0].value' "$tmp_dir/patch.json")" = unix-dotfile
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "PORT")][0].value' "$tmp_dir/patch.json")" = 8080
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")] | length' "$tmp_dir/patch.json")" = 1

# Verification 6 found that the live checker had a stale literal `data` even
# though Azure's canonical volume was `mtd-data`. Keep the lookup contract-led.
grep -F 'select(.volumeName == $volume_name)' "$repo_dir/scripts/verify-live-topology.sh" >/dev/null
grep -F 'select(.name == $volume_name)' "$repo_dir/scripts/verify-live-topology.sh" >/dev/null
! grep -F 'volumeName == "data"' "$repo_dir/scripts/verify-live-topology.sh" >/dev/null
if jq -e '.properties.template.containers[0].volumeMounts[0].volumeName == "data" or .properties.template.volumes[0].name == "data"' "$tmp_dir/patch.json" >/dev/null; then
  echo 'Regression: rendered topology reverted to the obsolete data volume identifier.' >&2
  exit 1
fi

echo '@claim:production-topology PASS — an unsafe three-replica payload renders as one replica with the canonical mtd-data Azure Files volume at /data and the SMB-safe SQLite VFS'
