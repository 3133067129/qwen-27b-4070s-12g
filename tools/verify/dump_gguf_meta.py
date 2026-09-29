"""Dump a GGUF's metadata as JSON so check_signs.py can compare it against the artifact.

`check_signs.py` takes the GGUF key/value block (it filters the `prism.hadamard.` prefix), but the
bundle shipped no way to produce that JSON from the source GGUF.

Usage: dump_gguf_meta.py <source.gguf> <out.json>
"""

from __future__ import annotations

import json
import sys

from _ternary_ref import Gguf


def main() -> int:
    source, out_path = sys.argv[1], sys.argv[2]
    gguf = Gguf(source)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(gguf.kv, handle, ensure_ascii=False)
    prism = {k: v for k, v in gguf.kv.items() if k.startswith("prism.hadamard.")}
    print(f"wrote {out_path}: {len(gguf.kv)} keys, {len(prism)} of them prism.hadamard.*")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
