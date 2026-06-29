./launch-cluster.sh --solo \
  -t vllm-node \
  --apply-mod mods/fix-qwen3.5-autoround \
  exec vllm serve sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP \
  --host 0.0.0.0 \
  --port 8088 \
  --trust-remote-code \
  --quantization modelopt \
  --language-model-only \
  --max-model-len 262144 \
  --max-num-seqs 2 \
  --kv-cache-dtype fp8 \
  --gpu-memory-utilization 0.9 \
  --reasoning-parser qwen3 \
  --speculative-config '{"method":"qwen3_5_mtp","num_speculative_tokens":3}' \
  --served-model-name sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
