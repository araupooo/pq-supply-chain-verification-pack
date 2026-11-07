#!/bin/bash
# Re-run of test binaries with stdout captured to WORKSPACE (not /tmp),
# because /tmp (512M tmpfs) filled to 100% during the first test runs and
# truncated/lost stdout (programs still exited 0: they do not check printf).
# For each binary: run, record exit code, sha256 + line count of full stdout,
# keep head/tail excerpts in the log, then delete the bulky raw capture.
# KAT generators are NOT re-run here: their .rsp outputs (written to the
# workspace, not /tmp) already matched byte-for-byte across r1/r2.
# Usage: ./retest.sh <repo> <run-label> [checkout-dir] ; caller tees stdout to logs/.
set -u
REPO="$1"; RUN="$2"; DIR="${3:-${REPO}-${RUN}}"
BASE="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="$BASE/testout-${REPO}-${RUN}"
mkdir -p "$OUTDIR"
cd "$BASE/$DIR/ref" || exit 1
run_one() {
  local bin="$1"
  local name
  name="$(basename "$bin")"
  local raw="$OUTDIR/${name}.stdout"
  echo "=== RUN $bin ==="
  echo "start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  timeout 900 "./$bin" > "$raw" 2> "$OUTDIR/${name}.stderr"
  local rc=$?
  echo "exit code: $rc"
  echo "stdout: $(wc -l < "$raw") lines, $(wc -c < "$raw") bytes, sha256 $(sha256sum "$raw" | cut -d' ' -f1)"
  echo "stderr bytes: $(wc -c < "$OUTDIR/${name}.stderr")"
  echo "--- stdout head (first 6 lines) ---"
  head -6 "$raw"
  echo "--- stdout tail (last 6 lines) ---"
  tail -6 "$raw"
  echo
  # Keep small outputs whole; delete bulky raw captures after hashing.
  if [ "$(wc -c < "$raw")" -gt 100000 ]; then rm -f "$raw"; echo "(bulky raw stdout deleted after hashing; head/tail above)"; fi
}
if [ "$REPO" = "kyber" ]; then
  run_one test/test_kyber512
  run_one test/test_kyber768
  run_one test/test_kyber1024
  run_one test/test_vectors512
  run_one test/test_vectors768
  run_one test/test_vectors1024
else
  run_one test/test_dilithium2
  run_one test/test_dilithium3
  run_one test/test_dilithium5
  run_one test/test_vectors2
  run_one test/test_vectors3
  run_one test/test_vectors5
fi
echo "retest done: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
