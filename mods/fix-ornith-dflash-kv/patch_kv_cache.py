#!/usr/bin/env python3
"""Patch vLLM KV page-size unification for Ornith GDN + DFlash.

Ornith mixes full attention with GatedDeltaNet recurrent state; the DFlash
drafter adds sliding-window attention with a larger KV page. vLLM tries to
unify by scaling `block_size`, but Mamba/GDN pages are shape-based and don't
scale that way — the resulting page_size_bytes mismatch fires an assertion.

Fix: for `MambaSpec` layers, pad the backing page to the common max size
instead of scaling `block_size`. Non-Mamba layers use the original path.

Adapted verbatim from AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored
(hotfixes/ornith_dflash_kvfix/patch_vllm_kv_cache.py). Idempotent.
"""

from __future__ import annotations

from pathlib import Path

import vllm.v1.core.kv_cache_utils as kv_cache_utils


OLD = """            ratio = max_page_size // layer_page_size
            new_block_size = layer_spec.block_size * ratio
            new_spec = replace(layer_spec, block_size=new_block_size)
            assert new_spec.page_size_bytes == max_page_size
            new_kv_cache_spec[layer_name] = new_spec
"""

NEW = """            if isinstance(layer_spec, MambaSpec):
                # Mamba/GDN state pages do not scale with block_size. Pad the
                # backing page instead, matching the hybrid mamba_page_size_padded
                # mechanism used during block-size alignment.
                new_spec = replace(layer_spec, page_size_padded=max_page_size)
            else:
                ratio = max_page_size // layer_page_size
                new_block_size = layer_spec.block_size * ratio
                new_spec = replace(layer_spec, block_size=new_block_size)
            assert new_spec.page_size_bytes == max_page_size
            new_kv_cache_spec[layer_name] = new_spec
"""


def main() -> None:
    path = Path(kv_cache_utils.__file__).resolve()
    text = path.read_text()

    if NEW in text:
        print(f"[fix-ornith-dflash-kv] already patched: {path}")
        return

    if OLD not in text:
        raise SystemExit(f"[fix-ornith-dflash-kv] patch anchor not found in {path}")

    path.write_text(text.replace(OLD, NEW, 1))
    print(f"[fix-ornith-dflash-kv] patched: {path}")


if __name__ == "__main__":
    main()
