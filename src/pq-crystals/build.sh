#!/bin/bash
# Build-verification script for pq-crystals kyber / dilithium reference implementations.
# Usage: ./build.sh <kyber|dilithium> <run-label> [checkout-dir]
#   - If checkout-dir is omitted, a fresh clone is made into <repo>-<run-label>/.
#   - Builds the documented `make` default target in ref/ (kyber: all = test+speed+shared+nistkat;
#     dilithium: all = test binaries only), then `make speed shared nistkat` for dilithium
#     so the artifact set is comparable.
#   - Logs are written unedited to logs/<repo>-<run-label>-build.log (caller tees).
#   - No network writes, no installs, no signing. Deterministic build flags are NOT
#     forced here on purpose: run 1 is the plain upstream-documented build.
set -u
REPO="$1"          # kyber | dilithium
RUN="$2"           # e.g. r1, r2
DIR="${3:-${REPO}-${RUN}}"
BASE="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$BASE/$DIR" ]; then
  echo "Cloning https://github.com/pq-crystals/${REPO}.git -> $BASE/$DIR"
  git clone --quiet "https://github.com/pq-crystals/${REPO}.git" "$BASE/$DIR"
fi
cd "$BASE/$DIR" || exit 1
echo "=== checkout ==="
git rev-parse HEAD
git log -1 --format='%H %ad %s' --date=iso-strict
git status --short
echo "=== build: make in ref/ ==="
cd ref || exit 1
make clean >/dev/null 2>&1 || true
make 2>&1
MAKE_STATUS=$?
echo "make exit status: $MAKE_STATUS"
if [ "$REPO" = "dilithium" ]; then
  echo "=== build: make speed shared nistkat (dilithium default 'all' is test-only) ==="
  make speed shared nistkat 2>&1
  echo "make speed/shared/nistkat exit status: $?"
fi
echo "=== artifacts ==="
find . -type f -executable | sort
echo "=== sha256 ==="
find . -type f \( -name 'test_*' -o -name 'PQCgenKAT_*' -o -name '*.so' \) -exec sha256sum {} \; | sort -k2
exit 0
