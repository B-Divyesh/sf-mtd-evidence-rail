#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

jq -n '{properties:{configuration:{activeRevisionsMode:"Single"},template:{containers:[{name:"app",image:"example.invalid/app:test",env:[{name:"PORT",value:"8080"},{name:"BUILD_SHA",value:"stale-commit"},{name:"GIT_SHA",value:"stale-commit"},{name:"SOURCE_COMMIT",value:"stale-commit"}],resources:{cpu:0.5,memory:"1Gi"}}],scale:{minReplicas:1,maxReplicas:3},volumes:null}}}' > "$tmp_dir/unsafe.json"

"$repo_dir/scripts/render-production-topology.sh" --image 'registry.invalid/mtd-evidence-rail:repair-test' "$tmp_dir/unsafe.json" > "$tmp_dir/patch.json"

test "$(jq -r '.properties.configuration.activeRevisionsMode' "$tmp_dir/patch.json")" = Single
test "$(jq -r '.properties.template.scale.minReplicas' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.scale.maxReplicas' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.containers | length' "$tmp_dir/patch.json")" = 1
test "$(jq -r '.properties.template.containers[0].image' "$tmp_dir/patch.json")" = registry.invalid/mtd-evidence-rail:repair-test
test "$(jq -r '.properties.template.containers[0].volumeMounts[0].volumeName' "$tmp_dir/patch.json")" = mtd-data
test "$(jq -r '.properties.template.containers[0].volumeMounts[0].mountPath' "$tmp_dir/patch.json")" = /data
test "$(jq -r '.properties.template.volumes[0].name' "$tmp_dir/patch.json")" = mtd-data
test "$(jq -r '.properties.template.volumes[0].storageType' "$tmp_dir/patch.json")" = AzureFile
test "$(jq -r '.properties.template.volumes[0].storageName' "$tmp_dir/patch.json")" = mtd-evidence-rail-data
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")][0].value' "$tmp_dir/patch.json")" = unix-dotfile
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "PORT")][0].value' "$tmp_dir/patch.json")" = 8080
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "SQLITE_VFS")] | length' "$tmp_dir/patch.json")" = 1
test "$(jq -r '[.properties.template.containers[0].env[] | select(.name == "BUILD_SHA" or .name == "GIT_SHA" or .name == "SOURCE_COMMIT")] | length' "$tmp_dir/patch.json")" = 0

# Live claim commands must reject a quiet but unsafe 1-3 deployment before a
# request happens to hit its only warm replica.
grep -F 'assert-live-topology.sh' "$repo_dir/scripts/test-live-workspace-consistency.sh" >/dev/null
grep -F 'assert-live-topology.sh' "$repo_dir/scripts/test-live-rate-limit.sh" >/dev/null
grep -F 'one_limiter_max=' "$repo_dir/scripts/test-live-rate-limit.sh" >/dev/null
grep -F '.factory/release.json' "$repo_dir/scripts/assert-live-topology.sh" >/dev/null
jq -e '.source_commit | test("^[0-9a-f]{40}$")' "$repo_dir/.factory/release.json" >/dev/null
"$repo_dir/scripts/test-live-release-guard.sh"

# Verification 6 found that the live checker had a stale literal `data` even
# though Azure's canonical volume was `mtd-data`. Keep the lookup contract-led.
grep -F 'select(.volumeName == $volume_name)' "$repo_dir/scripts/assert-live-topology.sh" >/dev/null
grep -F 'select(.name == $volume_name)' "$repo_dir/scripts/assert-live-topology.sh" >/dev/null
! grep -F 'volumeName == "data"' "$repo_dir/scripts/assert-live-topology.sh" >/dev/null
if jq -e '.properties.template.containers[0].volumeMounts[0].volumeName == "data" or .properties.template.volumes[0].name == "data"' "$tmp_dir/patch.json" >/dev/null; then
  echo 'Regression: rendered topology reverted to the obsolete data volume identifier.' >&2
  exit 1
fi

# The generic factory helper creates a fresh app with a three-replica,
# container-local template. Running it after the product topology is rendered
# silently discards the Azure Files mount and the limiter's one-replica
# boundary. The product deployer must build the image itself and patch the
# complete desired revision in one operation.
grep -F 'az acr build' "$repo_dir/scripts/deploy.sh" >/dev/null
grep -F 'PREBUILT_IMAGE' "$repo_dir/scripts/deploy.sh" >/dev/null
grep -F 'render-production-topology.sh" --image "$image"' "$repo_dir/scripts/deploy.sh" >/dev/null
grep -F 'storageType // ""):\(.storageName // "")' "$repo_dir/scripts/deploy.sh" >/dev/null
grep -F 'assert-build-inputs-committed.sh' "$repo_dir/scripts/deploy.sh" >/dev/null
if grep -F '/opt/fleet/lib/deploy-container.sh' "$repo_dir/scripts/deploy.sh" >/dev/null; then
  echo 'Regression: deployment delegates to the generic three-replica helper.' >&2
  exit 1
fi

# Candidate identity is meaningful only if the image inputs and the deployment
# contract match HEAD. The deployment must reject a local frontend/backend edit
# rather than tagging it with the previous commit. This temporary repository
# gives the check an exact clean and dirty case without touching this checkout.
identity_repo="$tmp_dir/identity-repo"
mkdir -p "$identity_repo"/{frontend,migrations,src,scripts,.factory}
touch "$identity_repo"/{Dockerfile,package.json,package-lock.json,tsconfig.json,vite.config.ts,Cargo.toml,Cargo.lock}
touch "$identity_repo"/frontend/main.ts "$identity_repo"/migrations/0001.sql "$identity_repo"/src/main.rs
touch "$identity_repo"/scripts/deploy.sh "$identity_repo"/.factory/container-app.json
git -C "$identity_repo" init --quiet
git -C "$identity_repo" config user.email 'test@example.invalid'
git -C "$identity_repo" config user.name 'Topology test'
git -C "$identity_repo" add .
git -C "$identity_repo" commit --quiet -m 'fixture'
"$repo_dir/scripts/assert-build-inputs-committed.sh" "$identity_repo" >/dev/null
printf 'changed source' >> "$identity_repo/src/main.rs"
identity_log="$tmp_dir/identity.log"
if "$repo_dir/scripts/assert-build-inputs-committed.sh" "$identity_repo" >"$identity_log" 2>&1; then
  echo 'Regression: deployment identity check accepted an uncommitted build input.' >&2
  exit 1
fi
grep -F 'release build inputs are not committed at HEAD' "$identity_log" >/dev/null

# The verifier's failed candidate was rolled out after the product deployer by
# the generic factory template. It supplied only PORT, left /data inside the
# container layer, and still became healthy. The binary must now refuse that
# exact Azure runtime boundary, so a later unsafe rollout cannot take traffic.
if [ ! -x "$repo_dir/target/debug/mtd-evidence-rail" ]; then
  cargo build --quiet --locked --manifest-path "$repo_dir/Cargo.toml"
fi
unsafe_log="$tmp_dir/unsafe-runtime.log"
set +e
env -i \
  CONTAINER_APP_NAME=sf-mtd-evidence-rail \
  CONTAINER_APP_REVISION=sf-mtd-evidence-rail--unsafe \
  CONTAINER_APP_REPLICA_NAME=unsafe-replica \
  DATA_DIR=/data \
  PORT=8299 \
  STATIC_DIR="$repo_dir/dist" \
  "$repo_dir/target/debug/mtd-evidence-rail" >"$unsafe_log" 2>&1
unsafe_status=$?
set -e
test "$unsafe_status" -eq 78
grep -F 'Azure Container Apps has no dedicated /data mount; refusing container-local SQLite' "$unsafe_log" >/dev/null

echo '@claim:production-topology PASS — an unsafe three-replica payload renders as one durable replica, and an Azure revision without the /data mount exits before serving traffic'
