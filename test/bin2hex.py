#!/usr/bin/env python3
"""Convert a little-endian binary to $readmemh-compatible hex (one 32-bit word per line)."""
import sys, struct

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input.bin> <output.dat>")
    sys.exit(1)

with open(sys.argv[1], 'rb') as f:
    data = f.read()

# Pad to 4-byte boundary
while len(data) % 4:
    data += b'\x00'

with open(sys.argv[2], 'w') as f:
    for i in range(0, len(data), 4):
        word = struct.unpack_from('<I', data, i)[0]
        f.write(f'{word:08x}\n')

print(f"Wrote {len(data)//4} words to {sys.argv[2]}")
