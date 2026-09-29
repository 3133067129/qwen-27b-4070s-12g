"""Independent GGUF reader for the verify scripts (restores the module the bundle omitted).

`check_row_order.py` and `check_assembly.py` import `_ternary_ref.Gguf`, but the release bundle
never shipped `_ternary_ref` -- it lived only in the author's workspace (\`<WORKSPACE>\\tools\`),
so neither script could run as published.

This module is written as a deliberately INDEPENDENT implementation: it shares no code with
`tools/pack.py`, which is what produced the artifact.  Agreement between the two therefore counts
as cross-implementation evidence rather than a self-consistency check (docs/04 section 1.6).

API used by the scripts::

    gguf = Gguf(path)
    ne, type, offset = gguf.tensors[name]
    payload = gguf.raw(name, rows)        # raw GGML payload, ne[0] contiguous
    gguf.kv                               # decoded GGUF metadata
"""

from __future__ import annotations

import struct
from pathlib import Path

# GGML tensor types used by the ternary source: element bytes, or bytes per 128-weight block.
_TERNARY_BLOCK_BYTES = {142: 34, 143: 28}  # PQ2_0, PTQ1_0
_PLAIN_ELEMENT_BYTES = {0: 4, 1: 2, 30: 2}  # F32, F16, BF16
_BLOCK = 128


class Gguf:
    """Seek-based GGUF reader: header, metadata, tensor table, payload slices."""

    def __init__(self, path: str | Path):
        self.path = Path(path)
        self.tensors: dict[str, tuple[list[int], int, int]] = {}
        with self.path.open("rb") as handle:
            self._parse(handle)

    # -- parsing ----------------------------------------------------------
    def _parse(self, handle) -> None:
        magic = handle.read(4)
        if magic != b"GGUF":
            raise SystemExit(f"{self.path}: not a GGUF file (magic {magic!r})")
        self.version = self._u32(handle)
        n_tensors = self._u64(handle)
        n_kv = self._u64(handle)
        self.kv: dict[str, object] = {}
        for _ in range(n_kv):
            key = self._string(handle)
            self.kv[key] = self._value(handle, self._u32(handle))
        for _ in range(n_tensors):
            name = self._string(handle)
            rank = self._u32(handle)
            dims = [self._u64(handle) for _ in range(rank)]
            kind = self._u32(handle)
            offset = self._u64(handle)
            self.tensors[name] = (dims, kind, offset)
        # header_end is the end of the TENSOR INFO LIST, not of the KV block.  Taking it right
        # after the KVs shifts data_start down by the size of that list (~50 KB in this file):
        # names, shapes and types all still parse and a byte round trip through the same wrong
        # offset still passes, which is the silent failure docs/04 section 1.1 describes.
        self.header_end = handle.tell()
        self.alignment = int(self.kv.get("general.alignment", 32))
        self.data_start = -(-self.header_end // self.alignment) * self.alignment

    @staticmethod
    def _u32(handle) -> int:
        return struct.unpack("<I", handle.read(4))[0]

    @staticmethod
    def _u64(handle) -> int:
        return struct.unpack("<Q", handle.read(8))[0]

    def _string(self, handle) -> str:
        length = self._u64(handle)
        return handle.read(length).decode("utf-8", "replace")

    def _value(self, handle, kind: int):
        scalar = {
            0: "<B", 1: "<b", 2: "<H", 3: "<h", 4: "<I",
            5: "<i", 6: "<f", 10: "<Q", 11: "<q", 12: "<d",
        }
        if kind in scalar:
            return struct.unpack(scalar[kind], handle.read(struct.calcsize(scalar[kind])))[0]
        if kind == 7:
            return bool(handle.read(1)[0])
        if kind == 8:
            return self._string(handle)
        if kind == 9:
            element_kind, count = self._u32(handle), self._u64(handle)
            return [self._value(handle, element_kind) for _ in range(count)]
        raise SystemExit(f"{self.path}: unsupported GGUF metadata type {kind}")

    # -- payload ----------------------------------------------------------
    def tensor_bytes(self, name: str) -> int:
        dims, kind, _ = self.tensors[name]
        elements = 1
        for dim in dims:
            elements *= int(dim)
        if kind in _TERNARY_BLOCK_BYTES:
            if elements % _BLOCK:
                raise SystemExit(f"{name}: {elements} elements is not a multiple of {_BLOCK}")
            return elements // _BLOCK * _TERNARY_BLOCK_BYTES[kind]
        if kind in _PLAIN_ELEMENT_BYTES:
            return elements * _PLAIN_ELEMENT_BYTES[kind]
        raise SystemExit(f"{name}: tensor type {kind} is not supported by this reference reader")

    def raw(self, name: str, rows: int | None = None) -> bytes:
        dims, _kind, offset = self.tensors[name]
        if rows is not None and len(dims) > 1 and int(dims[1]) != rows:
            raise SystemExit(f"{name}: requested {rows} rows, source declares {dims[1]}")
        size = self.tensor_bytes(name)
        with self.path.open("rb") as handle:
            handle.seek(self.data_start + offset)
            data = handle.read(size)
        if len(data) != size:
            raise SystemExit(f"{name}: short read ({len(data)} of {size} bytes)")
        return data


__all__ = ["Gguf"]
