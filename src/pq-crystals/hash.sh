#!/bin/bash
# Hash only built artifacts (executables + shared libs) in a checkout's ref/ dir.
# Usage: ./hash.sh <repo> <run-label> [checkout-dir]
set -u
REPO="$1"; RUN="$2"; DIR="${3:-${REPO}-${RUN}}"
BASE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE/$DIR/ref" || exit 1
find . -type f -executable | sort | xargs sha256sum > "$BASE/sha256sums-${REPO}-${RUN}.txt"
cat "$BASE/sha256sums-${REPO}-${RUN}.txt"
