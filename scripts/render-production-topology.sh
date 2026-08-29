#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
resource_file=${1:--}
contract_file=${TOPOLOGY_CONTRACT:-"$repo_dir/.factory/container-app.json"}

jq -c --slurpfile contract "$contract_file" '
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
