./launch-cluster.sh --solo \
  -t vllm-spark-glm \
  exec vllm serve zai-org/GLM-OCR \
  --port 8085 \
  --host 0.0.0.0 \
  --trust-remote-code \
  --gpu-memory-utilization 0.15
