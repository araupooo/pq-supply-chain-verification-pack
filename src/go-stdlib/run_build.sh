#!/bin/bash
# Usage: run_build.sh <build-dir> <log-file>
set -u
B="$1"; LOG="$2"
{
echo "=== BUILD START ==="
echo "build_dir=$B"
date -u +"%Y-%m-%dT%H:%M:%SZ start_utc"
date +"%Y-%m-%d %H:%M:%S %Z"
echo "--- toolchain ---"
/usr/local/go/bin/go version
echo "--- uname ---"
uname -a
echo "--- env (fixed for this build) ---"
echo "CGO_ENABLED=0"
echo "GOFLAGS=-trimpath -buildvcs=false"
echo "GOPROXY=off"
echo "GOSUMDB=off"
echo "GOFLAGS_EXTRA: -trimpath -buildvcs=false passed on command line as well"
echo "GOCACHE=$PWD/$B/gocache"
echo "GOMODCACHE=$PWD/$B/gomodcache"
echo "GOPATH=$PWD/$B/gopath"
echo "GOTOOLCHAIN=local"
echo "--- go env ---"
/usr/local/go/bin/go env GOVERSION GOROOT GOPATH GOCACHE GOMODCACHE GOOS GOARCH CGO_ENABLED GOFLAGS GOPROXY GOSUMDB GOTOOLCHAIN GOAMD64 2>&1 | head -30
echo "--- source hashes ---"
sha256sum "$B/main.go" "$B/go.mod"
echo "--- build command ---"
echo "cd $B && env CGO_ENABLED=0 GOFLAGS='-trimpath -buildvcs=false' GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local GOCACHE=\$PWD/gocache GOMODCACHE=\$PWD/gomodcache GOPATH=\$PWD/gopath /usr/local/go/bin/go build -trimpath -buildvcs=false -o pqcheck ."
echo "--- build output ---"
cd "$B" && env CGO_ENABLED=0 GOFLAGS='-trimpath -buildvcs=false' GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local GOCACHE="$PWD/gocache" GOMODCACHE="$PWD/gomodcache" GOPATH="$PWD/gopath" /usr/local/go/bin/go build -trimpath -buildvcs=false -o pqcheck . 2>&1
echo "build_exit=$?"
cd ..
echo "--- binary ---"
ls -l "$B/pqcheck"
sha256sum "$B/pqcheck"
echo "--- go version -m ---"
/usr/local/go/bin/go version -m "$B/pqcheck"
echo "--- run binary ---"
"./$B/pqcheck" 2>&1
echo "run_exit=$?"
date -u +"%Y-%m-%dT%H:%M:%SZ end_utc"
echo "=== BUILD END ==="
} 2>&1 | tee "$LOG"
