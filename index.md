# Claim-to-Evidence Index

Every claim in this pack and the file that proves it. Paths are relative
to the pack root unless noted. "Working evidence" paths are in the
pack's working directory (not shipped in the public repository): the
full build trees, caches, and the 38 MB liboqs libraries.

## Determinism claims

| Claim | Evidence |
|---|---|
| liboqs 0.16.0 builds differ (`1fdf54c7…` vs `fbd5dc65…`) | `outputs/RESULT-liboqs.md`; `outputs/logs/build1.log`, `outputs/logs/build2.log`; full libraries in working evidence `targets/liboqs/build1/liboqs/build/lib/liboqs.a`, `targets/liboqs/build2/...` (hashes re-verified independently for this pack) |
| Exactly 1 of 2,634 liboqs archive members differs, and it is `src/common/common.c.o` | `outputs/RESULT-liboqs.md` § "Root-cause investigation"; the two differing members preserved as `outputs/artifacts/liboqs/common.c.o-build1` (`91b6caea…`) and `common.c.o-build2` (`bb316ae5…`); member comparison independently re-run for this pack with a Python `ar` parser |
| `-ffile-prefix-map` makes the liboqs objects and re-archived libraries identical (`862b2aac…`, `9349b6d5…`) | `outputs/logs/fix_experiment.log`; `outputs/RESULT-liboqs.md`; re-archived library in working evidence `targets/liboqs/liboqs-fixed-prefix-map.a` (hash re-verified) |
| kyber: all 16 artifacts identical across two rebuilds | `outputs/RESULT-pq-crystals.md` §4; `outputs/sha256sums-pq-crystals.txt`; artifacts in `outputs/artifacts/pq-crystals/kyber-r1/`, `kyber-r2/`; `outputs/logs/kyber-r1-build.log`, `kyber-r2-build.log` |
| dilithium: all 17 artifacts identical across two rebuilds | `outputs/RESULT-pq-crystals.md` §4; `outputs/sha256sums-pq-crystals.txt`; artifacts in `outputs/artifacts/pq-crystals/dilithium-r1/`, `dilithium-r2/`; `outputs/logs/dilithium-r1-build.log`, `dilithium-r2-build.log` |
| Go test program: byte-identical binaries (`d81e1efa…ab22`) | `outputs/RESULT-go-stdlib.md` §4; `outputs/artifacts/go-stdlib/pqcheck-build1`, `pqcheck-build2`; `outputs/logs/build1.log`, `outputs/logs/build2.log` |
| Rust test program: byte-identical binaries (`bbe66602…99d686`) under stated conditions | `outputs/RESULT-rust-mlkem.md` §4; `outputs/artifacts/rust-mlkem/rust-mlkem-verify-a`, `rust-mlkem-verify-b`; `outputs/logs/build-a.log`, `outputs/logs/build-b.log` |
| Rust plain builds differ (v1/v2/v3 pairs) | `outputs/RESULT-rust-mlkem.md` §5; `outputs/logs/build-*-trial-v1.log`, `build-*-v2-remap-broken.log`, `build-*-v3-remap.log` |
| All 95 recorded artifact hashes verify | `outputs/SHA256SUMS` — run `python3 src/verify_hashes.py` or `(cd outputs && sha256sum -c SHA256SUMS)` |

## Pinned-source claims

| Claim | Evidence |
|---|---|
| liboqs 0.16.0, tag commit `5a1a854b…`, released 2026-07-09 | `outputs/RESULT-liboqs.md` § "Pinned version" (verified via `git ls-remote` and both clones' HEAD) |
| kyber HEAD `3edd5af5…` (2026-08-02); dilithium HEAD `d35ba3fe…` (2026-06-03) | `outputs/RESULT-pq-crystals.md` §1 |
| Go 1.27.3; `crypto/mldsa` new in Go 1.27; `crypto/mlkem` implements FIPS 203 | `outputs/RESULT-go-stdlib.md` §2 (go.dev release notes, pkg.go.dev docs; raw fetches in working evidence `targets/go-stdlib/research/`) |
| `ml-kem` 0.3.4, tag commit `6855b16a…`, published 2026-10-31 | `outputs/RESULT-rust-mlkem.md` §1 (crates.io API, GitHub API, `git ls-remote`, local clone) |

## Traceability claims

| Claim | Evidence |
|---|---|
| liboqs 0.16.0 release has zero assets / no hash / no signature / no attestation | `outputs/RESULT-liboqs.md` § "Traceability findings" (GitHub Releases API response preserved in working evidence `targets/liboqs/releases_latest.json`) |
| liboqs tarball hash matches Homebrew's published checksum (`162d5b51…f01eae`) | `outputs/RESULT-liboqs.md`; tarball preserved as `outputs/artifacts/liboqs/liboqs-0.16.0.tar.gz` (in `outputs/SHA256SUMS`) |
| pq-crystals repos have no releases | `outputs/RESULT-pq-crystals.md` §1 (release pages fetched 2026-11-07) |
| Go toolchain checksum verified; installed tree byte-identical to verified distribution | `outputs/RESULT-go-stdlib.md` §5; published checksum file in working evidence `targets/go-stdlib/research/` |
| Go `.asc` signature UNVERIFIED (no obtainable public key) | `outputs/RESULT-go-stdlib.md` §5; signature file in working evidence `targets/go-stdlib/research/go1.27.3.linux-amd64.tar.gz.asc` |
| `ml-kem` `.crate` checksum matches `Cargo.lock`; source byte-identical to tagged tree | `outputs/RESULT-rust-mlkem.md` §6; `.crate` preserved as `outputs/artifacts/rust-mlkem/ml-kem-0.3.4.crate` (in `outputs/SHA256SUMS`) |
| `ml-kem/v0.3.4` is a lightweight unsigned tag; repo has zero GitHub Releases | `outputs/RESULT-rust-mlkem.md` §6 |
| GitHub attestations API for liboqs UNVERIFIED (rate-limited) | `outputs/RESULT-liboqs.md` § "Traceability findings" |

## Runtime claims

| Claim | Evidence |
|---|---|
| Go program: ALL CHECKS PASSED, sizes match FIPS 203/204 | `outputs/logs/build1.log`, `outputs/logs/build2.log`; `outputs/RESULT-go-stdlib.md` §4 |
| Rust program: ML-KEM-768 round-trip OK, sizes match FIPS 203 | `outputs/logs/run-a.txt`, `outputs/logs/run-b.txt`; `outputs/RESULT-rust-mlkem.md` §3 |
| kyber/dilithium tests 24/24 exit 0; KAT `.rsp` identical r1 vs r2 | `outputs/logs/*-retest.log`; `outputs/RESULT-pq-crystals.md` §6; `.rsp` files in `outputs/artifacts/pq-crystals/` |

## Limitation claims (what was NOT established)

| Claim | Evidence |
|---|---|
| liboqs fix demonstrated at object + re-archive level, not a third full rebuild pair | `outputs/RESULT-liboqs.md` §§ "Determinism measure tried" and "Limitations" |
| liboqs test suite not run; shared-lib build not attempted; Ninja not used | `outputs/RESULT-liboqs.md` § "Limitations" |
| pq-crystals `avx2/` not built; KAT is r1-vs-r2 self-consistency, not NIST-file comparison | `outputs/RESULT-pq-crystals.md` §8 |
| Go "rebuild" definition (stdlib ships in toolchain) | `outputs/RESULT-go-stdlib.md` §3 |
| Rust determinism requires identical paths + remap; ML-KEM-768 only; crate KAT suite not run | `outputs/RESULT-rust-mlkem.md` §§4, 8 |
| Single machine/toolchain for all targets | README.md; each `RESULT-*.md` environment section |
