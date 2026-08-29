#!/bin/bash
set -euo pipefail

# Reproduce verification 13 without touching Azure: the desired candidate is
# latest, but it cannot start after the generic work-order deploy, so an older
# ready revision continues to answer /health.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

candidate=dc3b37c98d580be466ea3fa3f5cc84a455d50daa
older=8eabb53a7fdaebe7372c655d4e265c02dd0d21bb
candidate_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${candidate:0:12}"
older_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${older:0:12}"

jq -n --arg image "$candidate_image" '{properties:{configuration:{activeRevisionsMode:"Single"},latestRevisionName:"sf-mtd-evidence-rail--0000048",latestReadyRevisionName:"sf-mtd-evidence-rail--0000047",template:{containers:[{image:$image,env:[{name:"PORT",value:"8080"}],volumeMounts:null}],scale:{minReplicas:1,maxReplicas:3},volumes:null}}}' > "$tmp_dir/unsafe-resource.json"
jq -n --arg image "$older_image" '{properties:{template:{containers:[{image:$image}]}}}' > "$tmp_dir/old-ready.json"
jq -n --arg sha "$older" '{status:"ok",build_sha:$sha}' > "$tmp_dir/old-health.json"

jq -n --arg image "$candidate_image" '{properties:{configuration:{activeRevisionsMode:"Single"},latestRevisionName:"sf-mtd-evidence-rail--safe",latestReadyRevisionName:"sf-mtd-evidence-rail--safe",template:{containers:[{image:$image,env:[{name:"PORT",value:"8080"},{name:"SQLITE_VFS",value:"unix-dotfile"}],volumeMounts:[{volumeName:"mtd-data",mountPath:"/data"}]}],scale:{minReplicas:1,maxReplicas:1},volumes:[{name:"mtd-data",storageName:"mtd-evidence-rail-data",storageType:"AzureFile"}]}}}' > "$tmp_dir/safe-resource.json"
jq -n --arg image "$candidate_image" '{properties:{template:{containers:[{image:$image}]}}}' > "$tmp_dir/safe-ready.json"
jq -n --arg sha "$candidate" '{status:"ok",build_sha:$sha}' > "$tmp_dir/safe-health.json"

printf '%s\n' '#!/bin/bash' 'set -euo pipefail' \
  'case "$*" in' \
  '*"containerapp show"*) cat "$FAKE_RESOURCE" ;;' \
  '*"revision list"*) printf "%s\n" "$FAKE_ACTIVE" ;;' \
  '*"revision show"*) cat "$FAKE_READY" ;;' \
  '*"replica list"*) printf "%s\n" "$FAKE_RUNNING" ;;' \
  '*) echo "Unexpected az invocation: $*" >&2; exit 2 ;;' \
  'esac' > "$tmp_dir/az"
printf '%s\n' '#!/bin/bash' 'set -euo pipefail' 'cat "$FAKE_HEALTH"' > "$tmp_dir/curl"
chmod +x "$tmp_dir/az" "$tmp_dir/curl"

run_guard() {
  PATH="$tmp_dir:$PATH" \
    EXPECTED_SHA="$candidate" \
    EXPECTED_IMAGE="$candidate_image" \
    FAKE_RESOURCE="$1" \
    FAKE_READY="$2" \
    FAKE_HEALTH="$3" \
    FAKE_ACTIVE="$4" \
    FAKE_RUNNING="$5" \
    "$repo_dir/scripts/assert-live-topology.sh"
}

unsafe_log="$tmp_dir/unsafe.log"
if run_guard "$tmp_dir/unsafe-resource.json" "$tmp_dir/old-ready.json" "$tmp_dir/old-health.json" 2 1 >"$unsafe_log" 2>&1; then
  echo 'Regression: verification 13 unsafe deployment passed the live release guard.' >&2
  exit 1
fi
grep -F "expected_sha=$candidate live_sha=$older" "$unsafe_log" >/dev/null
grep -F 'latest=sf-mtd-evidence-rail--0000048 ready=sf-mtd-evidence-rail--0000047' "$unsafe_log" >/dev/null
grep -F 'max=3' "$unsafe_log" >/dev/null
grep -F 'mount= volume=:' "$unsafe_log" >/dev/null
grep -F 'active=2 running=1' "$unsafe_log" >/dev/null

# A safe topology must still fail if an older build answers health. This keeps
# identity from becoming a separate manual check outside the declared claims.
identity_log="$tmp_dir/identity.log"
if run_guard "$tmp_dir/safe-resource.json" "$tmp_dir/safe-ready.json" "$tmp_dir/old-health.json" 1 1 >"$identity_log" 2>&1; then
  echo 'Regression: a stale live build passed the release identity guard.' >&2
  exit 1
fi
grep -F "expected_sha=$candidate live_sha=$older" "$identity_log" >/dev/null

run_guard "$tmp_dir/safe-resource.json" "$tmp_dir/safe-ready.json" "$tmp_dir/safe-health.json" 1 1 >/dev/null

echo 'Release guard regression PASS — the verification 13 stale-build/two-revision shape is rejected, and only an exact healthy release passes.'
