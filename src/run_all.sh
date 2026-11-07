#!/bin/bash
# Post-quantum supply-chain verification pack — consolidated rerun harness.
#
# Rebuilds all four pinned targets twice from clean state, compares SHA-256
# hashes, and checks the observed verdicts against the recorded ones:
#   liboqs 0.16.0        -> expected NONDETERMINISTIC (hashes differ, same size)
#   pq-crystals kyber    -> expected DETERMINISTIC, hashes match the recorded ones
#   pq-crystals dilithium-> expected DETERMINISTIC, hashes match the recorded ones
#   Go stdlib mlkem/mldsa-> expected DETERMINISTIC, hash matches the recorded one
#   Rust ml-kem 0.3.4    -> expected DETERMINISTIC, hash matches the recorded one
# Exit 0 only if every observed outcome matches its recorded expectation.
#
# Usage: ./run_all.sh [workdir]   (default workdir: ./rerun)
# Requirements: git, cmake, gcc, make, python3, Go >= 1.27, cargo/rustc >= 1.87.
# TMPDIR is set inside the workdir: /tmp on this machine is a 512 MB tmpfs and
# the liboqs build exhausts it. A full run takes roughly 40-60 minutes on 4 cores
# (liboqs dominates); the other three targets finish in a few minutes.
set -u
cd "$(dirname "$0")/.." || exit 1
PACK_ROOT="$PWD"
WORK="${1:-$PACK_ROOT/rerun}"
case "$WORK" in /*) ;; *) WORK="$PACK_ROOT/$WORK";; esac
if [ -e "$WORK" ] && [ -n "$(ls -A "$WORK" 2>/dev/null)" ]; then
  echo "ERROR: workdir $WORK already exists and is not empty." >&2
  echo "Remove it first, or pass a different workdir: ./run_all.sh ./rerun2" >&2
  echo "Refusing to run: two concurrent runs sharing one workdir corrupt each other." >&2
  exit 2
fi
mkdir -p "$WORK"
export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"
export PATH="/usr/local/go/bin:$HOME/.cargo/bin:$PATH"
LOG="$WORK/rerun.log"
: > "$LOG"
say() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }
FAIL=0
mkdir -p "$WORK/hashes"

# ---------------- liboqs 0.16.0 ----------------
say "=== liboqs 0.16.0: two clean Release builds ==="
for N in 1 2; do
  B="$WORK/liboqs-build$N"
  git clone --depth 1 --branch 0.16.0 https://github.com/open-quantum-safe/liboqs.git "$B/liboqs" >>"$LOG" 2>&1
  (cd "$B/liboqs" && git rev-parse HEAD >>"$LOG" 2>&1)
  mkdir -p "$B/liboqs/build" && (cd "$B/liboqs/build" && cmake -DCMAKE_BUILD_TYPE=Release .. >>"$LOG" 2>&1 && cmake --build . -- -j4 >>"$LOG" 2>&1)
  sha256sum "$B/liboqs/build/lib/liboqs.a" | awk '{print $1}' > "$WORK/hashes/liboqs-$N.txt"
  stat -c %s "$B/liboqs/build/lib/liboqs.a" > "$WORK/hashes/liboqs-size-$N.txt"
done
H1=$(cat "$WORK/hashes/liboqs-1.txt"); H2=$(cat "$WORK/hashes/liboqs-2.txt")
S1=$(cat "$WORK/hashes/liboqs-size-1.txt"); S2=$(cat "$WORK/hashes/liboqs-size-2.txt")
say "liboqs build1: $H1 ($S1 bytes)"
say "liboqs build2: $H2 ($S2 bytes)"
if [ "$H1" != "$H2" ] && [ "$S1" = "$S2" ]; then
  say "liboqs verdict: NONDETERMINISTIC (as recorded) — hashes differ, sizes equal"
else
  say "liboqs verdict: UNEXPECTED (hashes equal, or sizes differ)"; FAIL=1
fi

# ---------------- pq-crystals ----------------
say "=== pq-crystals: kyber + dilithium, two clean rebuilds each ==="
for REPO in kyber dilithium; do
  case $REPO in
    kyber) COMMIT=3edd5af5991927164edd4aacebfcbee00b8064e7;;
    dilithium) COMMIT=d35ba3fe5449bee3e6d43e1f296c3ca818bd36be;;
  esac
  for N in 1 2; do
    B="$WORK/$REPO-r$N"
    git clone https://github.com/pq-crystals/$REPO.git "$B" >>"$LOG" 2>&1
    (cd "$B" && git checkout -q "$COMMIT" && git rev-parse HEAD >>"$LOG" 2>&1)
    (cd "$B/ref" && make >>"$LOG" 2>&1)
    if [ "$REPO" = dilithium ]; then (cd "$B/ref" && make speed shared nistkat >>"$LOG" 2>&1); fi
    (cd "$B/ref" && find . -type f \( -name '*.so' -o -name 'test_*' -o -name 'PQCgenKAT_*' \) ! -name '*.c' ! -name '*.h' -exec sha256sum {} + | sort -k2 > "$WORK/hashes/$REPO-r$N.txt")
  done
  if cmp -s "$WORK/hashes/$REPO-r1.txt" "$WORK/hashes/$REPO-r2.txt"; then
    say "$REPO verdict: DETERMINISTIC (r1 == r2, $(wc -l < "$WORK/hashes/$REPO-r1.txt") artifacts)"
  else
    say "$REPO verdict: UNEXPECTED — r1 != r2"; diff "$WORK/hashes/$REPO-r1.txt" "$WORK/hashes/$REPO-r2.txt" | tee -a "$LOG"; FAIL=1
  fi
done

# ---------------- Go stdlib ----------------
say "=== Go stdlib: crypto/mlkem + crypto/mldsa test program, two clean builds ==="
go version >>"$LOG" 2>&1
for N in 1 2; do
  B="$WORK/go-build$N"; mkdir -p "$B"; cp src/go-stdlib/main.go src/go-stdlib/go.mod "$B/"
  (cd "$B" && env CGO_ENABLED=0 GOFLAGS='-trimpath -buildvcs=false' GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local GOCACHE="$B/gocache" GOMODCACHE="$B/gomodcache" GOPATH="$B/gopath" go build -trimpath -buildvcs=false -o pqcheck . >>"$LOG" 2>&1)
  sha256sum "$B/pqcheck" | awk '{print $1}' > "$WORK/hashes/go-$N.txt"
  "$B/pqcheck" > "$WORK/hashes/go-run-$N.txt" 2>&1 || FAIL=1
done
G1=$(cat "$WORK/hashes/go-1.txt"); G2=$(cat "$WORK/hashes/go-2.txt")
say "go build1: $G1"; say "go build2: $G2"
if [ "$G1" = "$G2" ] && [ "$G1" = "d81e1efa546db902d66b25fbee72e45827b493b0400a4f80f447ffcb20abab22" ]; then
  say "go verdict: DETERMINISTIC, hash matches recorded value"
else
  say "go verdict: UNEXPECTED"; FAIL=1
fi
grep -q "ALL CHECKS PASSED" "$WORK/hashes/go-run-1.txt" && grep -q "ALL CHECKS PASSED" "$WORK/hashes/go-run-2.txt" && say "go test program: ALL CHECKS PASSED on both builds" || { say "go test program: FAILED"; FAIL=1; }

# ---------------- Rust ml-kem ----------------
# Canonical method: dependencies are VENDORED in src/rust-mlkem/vendor/
# (cargo vendor output, with .cargo/config.toml redirecting crates-io to
# it), so the build needs NO network at all — the crates.io index fetch
# proved transiently flaky ("transfer too slow") and failed two full
# validation runs. Three --remap-path-prefix flags (target dir, cargo
# home, and source copy — the vendor dir lives under the source copy)
# plus a fixed SOURCE_DATE_EPOCH make the hash checkout-independent:
# verified in two different directories (bbe66602...). A single fresh
# CARGO_HOME is reused for both builds (same path; only the target dir
# is wiped between builds). Cargo verifies every vendored crate against
# Cargo.lock checksums on each --offline build.
say "=== Rust ml-kem 0.3.4: two clean rebuilds (vendored, three-path remap) ==="
cargo --version >>"$LOG" 2>&1; rustc --version >>"$LOG" 2>&1
RB="$WORK/rust"; mkdir -p "$RB"
rm -rf "$RB/cargo-home" "$RB/target" "$RB/src-copy"
mkdir -p "$RB/cargo-home" "$RB/target" "$RB/src-copy"
cp -r src/rust-mlkem/Cargo.toml src/rust-mlkem/Cargo.lock src/rust-mlkem/src src/rust-mlkem/vendor src/rust-mlkem/.cargo "$RB/src-copy/"
for N in 1 2; do
  rm -rf "$RB/target"; mkdir -p "$RB/target"
  (cd "$RB/src-copy" && env CARGO_HOME="$RB/cargo-home" CARGO_TARGET_DIR="$RB/target" SOURCE_DATE_EPOCH=1793484446 RUSTFLAGS="--remap-path-prefix $RB/target=/build/rust-mlkem --remap-path-prefix $RB/cargo-home=/cargo-home --remap-path-prefix $RB/src-copy=/src" cargo build --release --locked --offline >>"$LOG" 2>&1)
  cp "$RB/target/release/rust-mlkem-verify" "$WORK/hashes/rust-bin-$N"
  sha256sum "$WORK/hashes/rust-bin-$N" | awk '{print $1}' > "$WORK/hashes/rust-$N.txt"
  "$WORK/hashes/rust-bin-$N" > "$WORK/hashes/rust-run-$N.txt" 2>&1 || FAIL=1
done
R1=$(cat "$WORK/hashes/rust-1.txt"); R2=$(cat "$WORK/hashes/rust-2.txt")
say "rust build1: $R1"; say "rust build2: $R2"
if [ "$R1" = "$R2" ] && [ "$R1" = "bbe66602760785e69e5f03f913a7b9369896737f90e2a3cc8d8f3ae07699d686" ]; then
  say "rust verdict: DETERMINISTIC, hash matches recorded value"
else
  say "rust verdict: UNEXPECTED"; FAIL=1
fi
grep -q "RESULT: ML-KEM-768 round-trip OK" "$WORK/hashes/rust-run-1.txt" && grep -q "RESULT: ML-KEM-768 round-trip OK" "$WORK/hashes/rust-run-2.txt" && say "rust test program: round-trip OK on both builds" || { say "rust test program: FAILED"; FAIL=1; }

# ---------------- recorded-hash cross-check (pq-crystals) ----------------
say "=== cross-check pq-crystals hashes against recorded values ==="
grep -q "0dddaf013fe872b87544e32a14669c04130c6077d8ca9d9d94d775fb4a28cfad" "$WORK/hashes/kyber-r1.txt" && grep -q "e1187499d2fd9d157d92ed8e9b07ebddd2e3c0ec74c5f908d23499f13543e287" "$WORK/hashes/dilithium-r1.txt" && say "pq-crystals headline hashes match recorded values" || { say "pq-crystals headline hashes DO NOT match recorded values"; FAIL=1; }

say "=== SUMMARY ==="
if [ "$FAIL" = 0 ]; then say "ALL TARGETS: observed outcomes match the recorded expectations — PASS"; else say "MISMATCH — see above"; fi
echo "liboqs: $H1 / $H2 (expected: differ)"
echo "go: $G1 (expected: d81e1efa…ab22)"
echo "rust: $R1 (expected: bbe66602…99d686)"
exit $FAIL
