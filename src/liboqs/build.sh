#!/bin/bash
# liboqs 0.16.0 reproducible-build check — build script (one instance).
# Usage: ./build.sh <workdir> <logfile> [extra cmake args...]
# Clones tag 0.16.0 fresh, configures Release static build, builds, hashes artifacts.
set -eu
WORK="$1"; LOG="$2"; shift 2
{
echo "=== liboqs build ==="
echo "start_utc: $(date -u +%FT%TZ)"
echo "host: $(uname -a)"
echo "gcc: $(gcc --version | head -1)"
echo "cmake: $(cmake --version | head -1)"
echo "git: $(git --version)"
echo "workdir: $WORK"
echo "TMPDIR=${TMPDIR:-<unset>} (gcc temp files go here; /tmp is a 512M tmpfs)"
echo "SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-<unset>}"
echo "CFLAGS=${CFLAGS:-<unset>} CXXFLAGS=${CXXFLAGS:-<unset>}"
echo "=== clone ==="
git clone --depth 1 --branch 0.16.0 https://github.com/open-quantum-safe/liboqs.git "$WORK/liboqs"
cd "$WORK/liboqs"
echo "HEAD: $(git rev-parse HEAD)"
git log -1 --format='%H %ci %s'
echo "=== configure ==="
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release "$@" ..
echo "=== build ==="
cmake --build . -- -j4
echo "=== artifacts ==="
ls -l lib/
sha256sum lib/liboqs.a
echo "end_utc: $(date -u +%FT%TZ)"
} 2>&1 | tee "$LOG"
