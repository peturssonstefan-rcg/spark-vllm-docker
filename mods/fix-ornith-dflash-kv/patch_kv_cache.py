#!/usr/bin/env python3
"""Patch vLLM KV page-size unification for Ornith GDN + DFlash.

Ornith mixes full attention with GatedDeltaNet recurrent state; the DFlash
drafter adds sliding-window attention layers with a larger KV page. In
unify_kv_cache_spec_page_size, Mamba/GDN layers pass the divisibility check
(max_page_size % layer_page_size == 0) but scaling `block_size` doesn't
actually change their `page_size_bytes` (which is shape-based, not
proportional to block_size). The subsequent assertion fires.

Fix: add a MambaSpec early-branch that pads via `page_size_padded` instead
of trying to scale block_size. This mirrors the existing padding path used
for AttentionSpec layers that index by block stride.

Idempotent. Approach adapted from AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored
(hotfixes/ornith_dflash_kvfix/patch_vllm_kv_cache.py) but with anchors updated
to match the current upstream vLLM code (which already has a padding branch
for AttentionSpec that AEON-7's original patch predates).
"""

from __future__ import annotations

from pathlib import Path

import vllm.v1.core.kv_cache_utils as kv_cache_utils


OLD = """            layer_page_size = layer_spec.page_size_bytes
            if max_page_size % layer_page_size == 0:
                ratio = max_page_size // layer_page_size
                new_block_size = layer_spec.block_size * ratio
                new_spec = replace(layer_spec, block_size=new_block_size)
            elif (
                isinstance(layer_spec, AttentionSpec)
                and layer_spec.indexes_kv_by_block_stride
            ):
                new_spec = replace(layer_spec, page_size_padded=max_page_size)
            else:
"""

NEW = """            layer_page_size = layer_spec.page_size_bytes
            if isinstance(layer_spec, MambaSpec):
                # Mamba/GDN state pages are shape-based and do not scale with
                # block_size. Pad the backing page to the common max size,
                # mirroring the AttentionSpec padding path below.
                new_spec = replace(layer_spec, page_size_padded=max_page_size)
            elif max_page_size % layer_page_size == 0:
                ratio = max_page_size // layer_page_size
                new_block_size = layer_spec.block_size * ratio
                new_spec = replace(layer_spec, block_size=new_block_size)
            elif (
                isinstance(layer_spec, AttentionSpec)
                and layer_spec.indexes_kv_by_block_stride
            ):
                new_spec = replace(layer_spec, page_size_padded=max_page_size)
            else:
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
