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
test "$(jq -r '.properties.template.containers[0].volumeMounts[0].mountPath' "$tmp_dir/patch.json")" = /data
test "$(jq -r '.properties.template.volumes[0].storageType' "$tmp_dir/patch.json")" = AzureFile
test "$(jq -r '.properties.template.volumes[0].storageName' "$tmp_dir/patch.json")" = mtd-evidence-rail-data
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")][0].value' "$tmp_dir/patch.json")" = unix-dotfile
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "PORT")][0].value' "$tmp_dir/patch.json")" = 8080
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")] | length' "$tmp_dir/patch.json")" = 1

echo '@claim:production-topology PASS — an unsafe three-replica payload renders as one replica with Azure Files at /data and the SMB-safe SQLite VFS'
