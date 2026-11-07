# Rubric — Post-Quantum Supply-Chain Verification Pack

## The question

Do four pinned post-quantum library targets — liboqs, the pq-crystals
reference implementations (kyber + dilithium), the Go standard library's
`crypto/mlkem` and `crypto/mldsa`, and one named Rust ML-KEM
implementation (`ml-kem` from RustCrypto/KEMs) — rebuild deterministically
from pinned published source, and can a consumer trace each distributed
binary or package back to that source with a verifiable hash or
signature?

## What counts as an answer

For each target, all of the following, with unedited evidence:

1. **Pinned source.** Exact version and commit hash, from the primary
   upstream source (repo, release page, package registry), recorded with
   the URL and the date checked.
2. **Two independent clean rebuilds.** Separate build directories, clean
   caches where the toolchain allows, identical commands except for the
   workdir. SHA-256 of the produced artifacts compared.
3. **Deterministic verdict.** YES only if the two hashes match with no
   output massaging. NO, with both hashes, if they differ — plus a
   root-cause investigation (which member/bytes differ, and why) and the
   upstream-supported determinism measures tried, each with its effect.
4. **Runtime check.** The built artifact must do the cryptography, not
   merely compile: keygen/encapsulate/decapsulate or sign/verify with
   sizes matching the FIPS 203 / FIPS 204 parameter sets, and the
   reference test/KAT programs passing.
5. **Traceability.** For each distributed binary/package found: source
   commit, build script, hash — or the gap marked explicitly. Release
   signatures/attestations checked where published and verified, or
   marked UNVERIFIED with the reason.
6. **Limitations stated.** Anything that could not be established is
   labelled UNVERIFIED, never inferred as a pass.

## How "rebuild" is defined per target

- **liboqs / pq-crystals:** the upstream-documented build from a fresh
  clone at the pinned commit (`cmake -DCMAKE_BUILD_TYPE=Release` +
  `cmake --build` for liboqs; `make` in `ref/` for pq-crystals).
- **Go stdlib:** the stdlib ships inside the toolchain, so there is no
  upstream source tarball to rebuild in the usual sense. "Rebuild" here
  means (a) primary check: build a fixed test program importing
  `crypto/mlkem` (ML-KEM-768) and `crypto/mldsa` (ML-DSA-65) twice from
  clean state (separate dirs, separate GOCACHE/GOMODCACHE/GOPATH,
  `-trimpath`, `CGO_ENABLED=0`) and compare binary hashes; (b)
  additional check: `go build -a std` twice in clean caches and compare
  the cache manifests with timestamp normalization (Go cache entries
  embed a write timestamp, so raw manifests are not a valid byte check).
  The toolchain distribution itself is verified separately against the
  published checksum and the installed tree diffed against the verified
  distribution.
- **Rust `ml-kem`:** build a fixed binary crate depending on the pinned
  `ml-kem =0.3.4` with a committed `Cargo.lock`, twice, with
  `cargo build --release --locked --offline`. All dependencies are
  VENDORED in `src/rust-mlkem/vendor/` (`cargo vendor` output, with
  `.cargo/config.toml` redirecting crates-io to it), so the build needs
  no network — the crates.io index fetch failed twice during validation
  with "transfer too slow". Because rustc embeds absolute registry and
  source paths, the pack's canonical method remaps three path families
  to fixed placeholders (`--remap-path-prefix` for the target dir, the
  cargo home, and the source copy — the vendor dir lives under the
  source copy) plus a fixed `SOURCE_DATE_EPOCH`; a single fresh
  CARGO_HOME is reused for both builds (only the target dir is wiped
  between builds). This makes the recorded hash checkout-independent
  (verified: two builds in different directories are byte-identical).
  Cargo verifies every vendored crate against the `Cargo.lock`
  checksums on each build. Plain builds without those measures were
  also run and are reported (they differ); the worker's original
  single-remap v4 pair (`98aec69a…`, path-dependent) and the
  three-remap registry pair (`315becfe…`) are preserved in
  `outputs/RESULT-rust-mlkem.md` §4 and findings.md F-03 as hash
  lineage — the canonical recorded hash is the vendored build's
  `bbe66602…`.

## Expected behavior (what "good" looks like)

- A deterministic target produces byte-identical artifacts from two
  independent clean rebuilds, and the hash matches a published or
  independently verified value where one exists.
- A nondeterministic target is reported as such with both hashes, the
  differing bytes identified, and a demonstrated fix — not hidden or
  massaged into a match.
- A distributed artifact traces to a pinned commit and a published hash
  or a verified signature. Where no such value exists, the gap is stated
  plainly with its consequence for a consumer.

## What this pack does NOT claim

- It does not claim the implementations are correct against NIST
  known-answer vectors, except where the in-repo deterministic KAT
  vectors were run (pq-crystals) — and there the check is r1-vs-r2
  self-consistency, not comparison against NIST-published KAT files.
- It does not claim cross-machine or cross-toolchain reproducibility:
  one machine, one toolchain per target (see README.md).
- It does not claim the absence of vulnerabilities, backdoors, or
  malicious code in any target; it checks build determinism and
  traceability only.
- UNVERIFIED items (GitHub attestations for liboqs, the Go `.asc`
  signature, Debian's liboqs 0.16.0 status, the `liboqs-python`
  provenance label) remain UNVERIFIED; no conclusion is drawn from them.

## How to re-run

```sh
python3 src/verify_hashes.py   # seconds: checks the 95 recorded hashes
./src/run_all.sh               # ~40-60 min: full rebuild of all targets
```

`run_all.sh` exits 0 only if every observed outcome matches its recorded
expectation. It clones from the pinned upstream sources and needs network
access for the liboqs and pq-crystals clones (the Rust section needs no
network — vendored dependencies). `TMPDIR` is set inside the workdir
because `/tmp` on the verification machine is a 512 MB tmpfs that the
liboqs build exhausts.
