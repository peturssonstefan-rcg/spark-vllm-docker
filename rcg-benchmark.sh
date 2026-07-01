#!/bin/bash
# Sweep llama-benchy across concurrency levels against the local vLLM endpoint.
# Simple wrapper for quick throughput A/B (see rcg-bench-guidellm.sh for SLO tests).
set -euo pipefail

MODEL="${MODEL:-AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Text-NVFP4-MTP}"
BASE_URL="${BASE_URL:-http://localhost:8089/v1}"
PP="${PP:-2048}"
TG="${TG:-128}"

for c in 1 2; do
  echo "=== concurrency $c ==="
  uvx llama-benchy \
    --base-url "$BASE_URL" \
    --model "$MODEL" \
    --pp "$PP" \
    --tg "$TG" \
    --concurrency "$c"
done
