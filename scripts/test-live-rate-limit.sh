#!/bin/bash
set -euo pipefail

# This intentionally matches the independent verifier's fresh-connection
# probe. A single forwarded client must exhaust the deployed app's one shared
# limiter; testing only the in-process Router cannot detect replica fan-out.
base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
"$repo_dir/scripts/assert-live-topology.sh"

request_count=200
run_dir=$(mktemp -d)
trap 'rm -rf "$run_dir"' EXIT

probe_wave() {
  local wave=$1 tmp_dir started_ms elapsed_ms created limited unexpected status status_file header_file one_limiter_max
  tmp_dir="$run_dir/wave-$wave"
  mkdir -p "$tmp_dir"
  started_ms=$(date +%s%3N)
  for request_number in $(seq 1 "$request_count"); do
    curl -sS --http1.1 --max-time 15 -H 'Connection: close' \
      -H "X-Forwarded-For: 198.51.100.$((200 + wave))" \
      -D "$tmp_dir/$request_number.headers" \
      -o /dev/null -w '%{http_code}' \
      -X POST "$base_url/api/demo" > "$tmp_dir/$request_number.status" &
  done
  wait
  elapsed_ms=$(($(date +%s%3N) - started_ms))

  created=0
  limited=0
  unexpected=0
  for status_file in "$tmp_dir"/*.status; do
    status=$(tr -d '\r\n' < "$status_file")
    case "$status" in
      201) created=$((created + 1)) ;;
      429) limited=$((limited + 1)) ;;
      *) unexpected=$((unexpected + 1)) ;;
    esac
  done

  if [ "$unexpected" -ne 0 ]; then
    echo "Live limiter wave $wave returned $unexpected unexpected responses: $(sort "$tmp_dir"/*.status | uniq -c | tr '\n' ' ')" >&2
    rm -rf "$tmp_dir"
    exit 1
  fi
  if [ "$limited" -lt 1 ]; then
    echo "Live limiter wave $wave accepted all $request_count requests." >&2
    rm -rf "$tmp_dir"
    exit 1
  fi

  # Demo provisioning starts with 20 tokens and replenishes one per second.
  # Two extra tokens cover scheduler boundaries without permitting the old
  # continuously admitted, storage-saturating shape.
  one_limiter_max=$((20 + (elapsed_ms + 999) / 1000 + 2))
  if [ "$created" -gt "$one_limiter_max" ]; then
    echo "Live limiter wave $wave accepted $created requests, above its bound $one_limiter_max over ${elapsed_ms}ms." >&2
    rm -rf "$tmp_dir"
    exit 1
  fi

  for status_file in "$tmp_dir"/*.status; do
    [ "$(tr -d '\r\n' < "$status_file")" = 429 ] || continue
    header_file=${status_file%.status}.headers
    grep -qi '^retry-after: 1' "$header_file" || {
      echo "A live 429 response in wave $wave did not include Retry-After: 1." >&2
      rm -rf "$tmp_dir"
      exit 1
    }
  done

  echo "wave=$wave responses=$request_count created=$created limited=$limited bound=$one_limiter_max elapsed=${elapsed_ms}ms"
}

for wave in 1 2 3; do
  probe_wave "$wave"
done

echo '@claim:live-api-rate-limit PASS — all three 200-request waves completed; every limited response included Retry-After: 1.'
