#!/bin/bash
# Ornith-1.0-35B + DFlash: pad Mamba/GDN KV pages during page-size unification.
# See patch_kv_cache.py for full context. Idempotent.
set -e
python3 "$(dirname "$0")/patch_kv_cache.py"
