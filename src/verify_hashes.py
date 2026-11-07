#!/usr/bin/env python3
"""Verify the pack's recorded artifact hashes (outputs/SHA256SUMS).

Usage: python3 src/verify_hashes.py [pack-root]
Checks every file listed in outputs/SHA256SUMS against its recorded SHA-256
and reports OK / MISSING / MISMATCH per entry. Exit 0 only if all verify.
This checks the preserved artifacts shipped in the pack; it does not rebuild
anything — use src/run_all.sh for a full rebuild verification.
"""
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
sums_file = root / "outputs" / "SHA256SUMS"
if not sums_file.exists():
    print(f"SHA256SUMS not found at {sums_file}")
    sys.exit(2)

ok = missing = mismatch = 0
for line in sums_file.read_text().splitlines():
    if not line.strip():
        continue
    expected, _, rel = line.partition("  ")
    if not rel:
        expected, _, rel = line.partition(" *")
    path = root / "outputs" / rel
    if not path.exists():
        print(f"MISSING   {rel}")
        missing += 1
        continue
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest == expected.strip():
        ok += 1
    else:
        print(f"MISMATCH  {rel}\n  expected {expected.strip()}\n  actual   {digest}")
        mismatch += 1

print(f"verified: {ok} OK, {missing} missing, {mismatch} mismatch")
sys.exit(0 if missing == 0 and mismatch == 0 else 1)
