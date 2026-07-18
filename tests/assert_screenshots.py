#!/usr/bin/env python3
"""Validate screenshot signatures, dimensions, size, and uniqueness."""
from __future__ import annotations

import hashlib
import struct
import sys
from pathlib import Path

if len(sys.argv) != 5:
    print("Usage: assert_screenshots.py DIRECTORY COUNT WIDTH HEIGHT", file=sys.stderr)
    sys.exit(2)

root = Path(sys.argv[1])
count, expected_width, expected_height = map(int, sys.argv[2:])
digests: set[str] = set()
for index in range(1, count + 1):
    path = root / f"slide-{index:02d}.png"
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 24:
        raise SystemExit(f"FAIL: invalid PNG: {path}")
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (expected_width, expected_height):
        raise SystemExit(f"FAIL: {path} is {width}x{height}, expected {expected_width}x{expected_height}")
    digests.add(hashlib.sha256(data).hexdigest())

if len(digests) != count:
    raise SystemExit("FAIL: one or more slide captures are byte-identical")
print(f"PASS: validated {count} distinct {expected_width}x{expected_height} PNG screenshots")
