#!/bin/bash
set -euo pipefail

status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 \
  https://api.sociobot.in/api/v1/products/mtd-evidence-rail/checkout)
case "$status" in
  301|302|303|307|308)
    echo '@claim:hosted-checkout PASS — Sociobot returned a checkout redirect'
    ;;
  *)
    echo "Expected a Sociobot checkout redirect, received HTTP $status" >&2
    exit 1
    ;;
esac
