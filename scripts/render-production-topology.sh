#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
image=""
resource_file=-

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image)
      image=${2:?"--image requires an image reference"}
      shift 2
      ;;
    --)
      shift
      resource_file=${1:--}
      shift || true
      ;;
    *)
      resource_file=$1
      shift
      ;;
  esac
done

contract_file=${TOPOLOGY_CONTRACT:-"$repo_dir/.factory/container-app.json"}

jq -c --arg image "$image" --slurpfile contract "$contract_file" '
  ($contract[0]) as $wanted |
  .properties.template.containers[0] as $container |
  {
    properties: {
      configuration: {
        activeRevisionsMode: $wanted.activeRevisionsMode
      },
      template: {
        containers: [
          $container + {
            image: (if $image == "" then $container.image else $image end),
            env: (
              [
                $container.env[]?
                | select(.name as $name | [$wanted.container.environment[].name] | index($name) | not)
              ] + $wanted.container.environment
            ),
            volumeMounts: $wanted.container.volumeMounts
          }
        ],
        scale: $wanted.scale,
        volumes: $wanted.volumes
      }
    }
  }
' "$resource_file"
