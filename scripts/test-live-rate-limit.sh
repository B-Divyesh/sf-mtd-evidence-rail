#!/bin/bash
set -euo pipefail

# This intentionally matches the independent verifier's fresh-connection
# probe. A single forwarded client must exhaust the deployed app's one shared
# limiter; testing only the in-process Router cannot detect replica fan-out.
base_url=${BASE_URL:-https://mtd-evidence-rail.sociobot.in}
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

request_count=200
started_ms=$(date +%s%3N)
for request_number in $(seq 1 "$request_count"); do
  curl -sS --http1.1 --max-time 30 -H 'Connection: close' \
    -H 'X-Forwarded-For: 198.51.100.9' \
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

[ "$unexpected" -eq 0 ] || {
  echo "Live limiter returned $unexpected unexpected responses: $(sort "$tmp_dir"/*.status | uniq -c | tr '\n' ' ')" >&2
  exit 1
}
[ "$limited" -gt 0 ] || {
  echo "Live limiter accepted all $request_count requests from one forwarded client." >&2
  exit 1
}

for status_file in "$tmp_dir"/*.status; do
  [ "$(tr -d '\r\n' < "$status_file")" = 429 ] || continue
  header_file=${status_file%.status}.headers
  grep -qi '^retry-after: 1' "$header_file" || {
    echo "A live 429 response did not include Retry-After: 1." >&2
    exit 1
  }
done

echo "@claim:live-api-rate-limit PASS — one forwarded client received $limited HTTP 429 responses with Retry-After: 1; $created/$request_count requests were accepted over ${elapsed_ms}ms."
