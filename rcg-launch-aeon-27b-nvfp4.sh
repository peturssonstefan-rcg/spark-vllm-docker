./launch-cluster.sh --solo \
  -t vllm-node \
  --apply-mod mods/fix-qwen3.5-autoround \
  exec vllm serve AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Text-NVFP4-MTP \
  --host 0.0.0.0 \
  --port 8089 \
  --trust-remote-code \
  --quantization modelopt \
  --language-model-only \
  --max-model-len 262144 \
  --max-num-seqs 2 \
  --kv-cache-dtype fp8 \
  --gpu-memory-utilization 0.9 \
  --reasoning-parser qwen3 \
  --speculative-config '{"method":"qwen3_5_mtp","num_speculative_tokens":4}' \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --served-model-name AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Text-NVFP4-MTP
