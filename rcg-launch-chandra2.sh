./launch-cluster.sh --solo \
        -t vllm-spark-chandra \
        exec vllm serve datalab-to/chandra-ocr-2 \
        --host 0.0.0.0 \
        --port 8086 \
        --trust-remote-code \
        --gpu-memory-utilization 0.7 \
        --limit-mm-per-prompt '{"image": 4}' \
        --served-model-name datalab-to/chandra-ocr-2
