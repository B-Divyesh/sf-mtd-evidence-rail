#!/bin/bash
set -euo pipefail

# Reproduce independent verification 16 exactly without touching Azure. The
# generic work-order rollout made candidate 560392b the latest revision, but it
# omitted the durable SQLite contract. That revision failed activation while
# the older 5779508 ready revision still answered health.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

candidate=560392b27a89568a3e88ca461b060f42fec7e61f
older=5779508e0a5c4eb3dcae6abd2dcbd709fa7167a9
candidate_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${candidate:0:12}"
older_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${older:0:12}"

jq -n --arg image "$candidate_image" '{properties:{configuration:{activeRevisionsMode:"Single"},latestRevisionName:"sf-mtd-evidence-rail--0000054",latestReadyRevisionName:"sf-mtd-evidence-rail--0000053",template:{containers:[{image:$image,env:[{name:"PORT",value:"8080"}],volumeMounts:null}],scale:{minReplicas:1,maxReplicas:3},volumes:null}}}' > "$tmp_dir/unsafe-resource.json"
jq -n --arg image "$older_image" '{properties:{active:true,template:{containers:[{image:$image}]}}}' > "$tmp_dir/old-ready.json"
jq -n --arg sha "$older" '{status:"ok",build_sha:$sha}' > "$tmp_dir/old-health.json"

jq -n --arg image "$candidate_image" '{properties:{configuration:{activeRevisionsMode:"Single"},latestRevisionName:"sf-mtd-evidence-rail--safe",latestReadyRevisionName:"sf-mtd-evidence-rail--safe",template:{containers:[{image:$image,env:[{name:"PORT",value:"8080"},{name:"SQLITE_VFS",value:"unix-dotfile"}],volumeMounts:[{volumeName:"mtd-data",mountPath:"/data"}]}],scale:{minReplicas:1,maxReplicas:1},volumes:[{name:"mtd-data",storageName:"mtd-evidence-rail-data",storageType:"AzureFile"}]}}}' > "$tmp_dir/safe-resource.json"
jq -n --arg image "$candidate_image" '{properties:{active:true,template:{containers:[{image:$image}]}}}' > "$tmp_dir/safe-ready.json"
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
    EXPECTED_SHA="$6" \
    EXPECTED_IMAGE="$7" \
    FAKE_RESOURCE="$1" \
    FAKE_READY="$2" \
    FAKE_HEALTH="$3" \
    FAKE_ACTIVE="$4" \
    FAKE_RUNNING="$5" \
    "$repo_dir/scripts/assert-live-topology.sh"
}

unsafe_log="$tmp_dir/unsafe.log"
if run_guard "$tmp_dir/unsafe-resource.json" "$tmp_dir/old-ready.json" "$tmp_dir/old-health.json" 2 1 "$older" "$older_image" >"$unsafe_log" 2>&1; then
  echo 'Regression: verification 16 unsafe deployment passed the live release guard.' >&2
  exit 1
fi
grep -F "expected_sha=$older live_sha=$older" "$unsafe_log" >/dev/null
grep -F 'latest=sf-mtd-evidence-rail--0000054 ready=sf-mtd-evidence-rail--0000053' "$unsafe_log" >/dev/null
grep -F 'max=3' "$unsafe_log" >/dev/null
grep -F 'mount= volume=:' "$unsafe_log" >/dev/null
grep -F 'active=2 running=1' "$unsafe_log" >/dev/null

# A safe topology must still fail if an older build answers health. This keeps
# identity from becoming a separate manual check outside the declared claims.
identity_log="$tmp_dir/identity.log"
if run_guard "$tmp_dir/safe-resource.json" "$tmp_dir/safe-ready.json" "$tmp_dir/old-health.json" 1 1 "$candidate" "$candidate_image" >"$identity_log" 2>&1; then
  echo 'Regression: a stale live build passed the release identity guard.' >&2
  exit 1
fi
grep -F "expected_sha=$candidate live_sha=$older" "$identity_log" >/dev/null

run_guard "$tmp_dir/safe-resource.json" "$tmp_dir/safe-ready.json" "$tmp_dir/safe-health.json" 1 1 "$candidate" "$candidate_image" >/dev/null

# Reproduce verification 20 exactly. The committed release manifest named the
# older 0719e627 build while the factory candidate, ready image, and /health
# all named 43e060d8. The topology assertion must use the candidate supplied by
# the factory instead of the stale published-source record.
stale_published=0719e6274bebc8e6333b4f0dad2b079295eed953
factory_candidate=43e060d81ab9d97443928a8548c840a97e0b2dc5
factory_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${factory_candidate:0:12}"
jq -n --arg sha "$stale_published" '{source_commit:$sha}' > "$tmp_dir/stale-release.json"
jq -n --arg image "$factory_image" '{properties:{configuration:{activeRevisionsMode:"Single"},latestRevisionName:"sf-mtd-evidence-rail--0000069",latestReadyRevisionName:"sf-mtd-evidence-rail--0000069",template:{containers:[{image:$image,env:[{name:"PORT",value:"8080"},{name:"SQLITE_VFS",value:"unix-dotfile"}],volumeMounts:[{volumeName:"mtd-data",mountPath:"/data"}]}],scale:{minReplicas:1,maxReplicas:1},volumes:[{name:"mtd-data",storageName:"mtd-evidence-rail-data",storageType:"AzureFile"}]}}}' > "$tmp_dir/verification-20-resource.json"
jq -n --arg image "$factory_image" '{properties:{active:true,template:{containers:[{image:$image}]}}}' > "$tmp_dir/verification-20-ready.json"
jq -n --arg sha "$factory_candidate" '{status:"ok",build_sha:$sha}' > "$tmp_dir/verification-20-health.json"

# Without the factory candidate, this is the report's failed assertion: the
# stale release value becomes the expected identity even though every live
# surface identifies 43e060d8. Keep the failure explicit so a precedence
# regression cannot make the fixture pass for the wrong reason.
verification_20_stale_log="$tmp_dir/verification-20-stale.log"
if PATH="$tmp_dir:$PATH" \
  EXPECTED_SHA="$stale_published" \
  FAKE_RESOURCE="$tmp_dir/verification-20-resource.json" \
  FAKE_READY="$tmp_dir/verification-20-ready.json" \
  FAKE_HEALTH="$tmp_dir/verification-20-health.json" \
  FAKE_ACTIVE=1 \
  FAKE_RUNNING=1 \
  "$repo_dir/scripts/assert-live-topology.sh" >"$verification_20_stale_log" 2>&1; then
  echo 'Regression: verification 20 stale release identity passed without the factory candidate.' >&2
  exit 1
fi
grep -F "expected_sha=$stale_published live_sha=$factory_candidate" "$verification_20_stale_log" >/dev/null

# The factory candidate has authority over an older expected value left by an
# earlier verification job. It makes the same complete live identity fixture
# pass without consulting the stale release manifest.
PATH="$tmp_dir:$PATH" \
  RELEASE_MANIFEST="$tmp_dir/stale-release.json" \
  EXPECTED_SHA="$stale_published" \
  CANDIDATE_SHA="$factory_candidate" \
  FAKE_RESOURCE="$tmp_dir/verification-20-resource.json" \
  FAKE_READY="$tmp_dir/verification-20-ready.json" \
  FAKE_HEALTH="$tmp_dir/verification-20-health.json" \
  FAKE_ACTIVE=1 \
  FAKE_RUNNING=1 \
  "$repo_dir/scripts/assert-live-topology.sh" >/dev/null

# Without an explicit factory value, a clean candidate checkout is itself the
# candidate. This is the path used by the exact npm claim commands.
checkout_candidate=$(git -C "$repo_dir" rev-parse HEAD)
checkout_image="sociobotregistry.azurecr.io/sf-mtd-evidence-rail:${checkout_candidate:0:12}"
jq --arg image "$checkout_image" '.properties.template.containers[0].image=$image' \
  "$tmp_dir/verification-20-resource.json" > "$tmp_dir/checkout-resource.json"
jq --arg image "$checkout_image" '.properties.template.containers[0].image=$image' \
  "$tmp_dir/verification-20-ready.json" > "$tmp_dir/checkout-ready.json"
jq -n --arg sha "$checkout_candidate" '{status:"ok",build_sha:$sha}' > "$tmp_dir/checkout-health.json"
PATH="$tmp_dir:$PATH" \
  RELEASE_MANIFEST="$tmp_dir/stale-release.json" \
  FAKE_RESOURCE="$tmp_dir/checkout-resource.json" \
  FAKE_READY="$tmp_dir/checkout-ready.json" \
  FAKE_HEALTH="$tmp_dir/checkout-health.json" \
  FAKE_ACTIVE=1 \
  FAKE_RUNNING=1 \
  "$repo_dir/scripts/assert-live-topology.sh" >/dev/null

echo 'Live release guard regressions PASS — unsafe topology and stale identity fail; verification 20 uses the exact factory candidate instead of a stale release manifest.'
