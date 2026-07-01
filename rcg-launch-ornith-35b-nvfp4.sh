./launch-cluster.sh --solo \
  -t vllm-node \
  --apply-mod mods/fix-qwen3.5-autoround \
  --apply-mod mods/fix-ornith-dflash-kv \
  exec vllm serve AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4 \
  --host 0.0.0.0 \
  --port 8089 \
  --trust-remote-code \
  --quantization compressed-tensors \
  --max-model-len 262144 \
  --max-num-seqs 2 \
  --max-num-batched-tokens 16384 \
  --gpu-memory-utilization 0.6 \
  --mamba-cache-dtype float32 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --limit-mm-per-prompt '{"image":4,"video":2}' \
  --mm-encoder-tp-mode data \
  --attention-backend flash_attn \
  --enable-chunked-prefill \
  --enable-prefix-caching \
  --speculative-config '{"method":"dflash","model":"z-lab/Qwen3.6-35B-A3B-DFlash","num_speculative_tokens":6}' \
  --served-model-name AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4

