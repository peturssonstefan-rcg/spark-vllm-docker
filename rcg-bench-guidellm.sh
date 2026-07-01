#!/bin/bash
# Run guidellm against the local vLLM endpoint on Spark.
# Designed for our AEON Qwen3.6-27B NVFP4 setup. Pass arguments to override
# defaults; otherwise it runs a sweep at 512/128 token sizes.
set -euo pipefail

MODEL="${MODEL:-AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Text-NVFP4-MTP}"
TARGET="${TARGET:-http://localhost:8089}"
PROFILE="${PROFILE:-sweep}"        # sweep | constant,rate=N | poisson,rate=N | throughput
DURATION="${DURATION:-120}"        # seconds
PROMPT_TOKENS="${PROMPT_TOKENS:-512}"
OUTPUT_TOKENS="${OUTPUT_TOKENS:-128}"
TS="$(date +%Y-%m-%d-%H%M)"
OUT_DIR="${OUT_DIR:-./bench-results}"

mkdir -p "$OUT_DIR"

uvx --from "guidellm[recommended]" guidellm run \
  --backend "kind=openai_http,target=${TARGET}" \
  --model "${MODEL}" \
  --profile "kind=${PROFILE}" \
  --constraint "kind=max_duration,seconds=${DURATION}" \
  --data "kind=synthetic_text,prompt_tokens=${PROMPT_TOKENS},output_tokens=${OUTPUT_TOKENS}" \
  --output "${OUT_DIR}/guidellm-${TS}-${PROFILE//,/_}-pp${PROMPT_TOKENS}-tg${OUTPUT_TOKENS}.html"
