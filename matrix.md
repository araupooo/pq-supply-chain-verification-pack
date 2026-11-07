# Source-to-Evidence Traceability Matrix

For each distributed binary/package found, the mapping to its source
commit, build script, and hash — or the gap, marked explicitly. "Gap"
means: no published artifact, no published hash, or no signature file.

## 1. Pinned sources

| Target | Version / commit | Source URL | Build script in this pack |
|---|---|---|---|
| liboqs | 0.16.0, `5a1a854b0dc9f2141bdc771c555ee60c37950183` (2026-07-09) | https://github.com/open-quantum-safe/liboqs | `src/liboqs/build.sh` |
| pq-crystals/kyber | HEAD `3edd5af5991927164edd4aacebfcbee00b8064e7` (2026-08-02) | https://github.com/pq-crystals/kyber | `src/pq-crystals/build.sh` |
| pq-crystals/dilithium | HEAD `d35ba3fe5449bee3e6d43e1f296c3ca818bd36be` (2026-06-03) | https://github.com/pq-crystals/dilithium | `src/pq-crystals/build.sh` |
| Go stdlib | Go 1.27.3, toolchain built 2026-10-19T22:20:36Z | https://go.dev/dl/ | `src/go-stdlib/run_build.sh` |
| Rust `ml-kem` | 0.3.4, tag `ml-kem/v0.3.4` = `6855b16a6cca9fc1c3eaea76776a7cd50ad67846` (2026-10-31) | https://github.com/RustCrypto/KEMs | `src/run_all.sh` (rust section) |

## 2. Deterministic-rebuild results

| Target | Artifact compared | Build 1 SHA-256 | Build 2 SHA-256 | Deterministic |
|---|---|---|---|---|
| liboqs | `build/lib/liboqs.a` (38,720,354 B) | `1fdf54c7e56434c7c360593a81686de79f105a4ac213446710556298922e6114` | `fbd5dc65047d46d0d91c79da119a9665db6946e8fa7fc1f5a2c2a05ca4232d56` | **NO** — 1 of 2,634 members differs (F-02) |
| liboqs (fixed) | `liboqs.a` re-archived with `-ffile-prefix-map` object | `9349b6d5d2301c3868ede55b58d5863c58f8a28c95f26febc38dd583de16849b` | `9349b6d5d2301c3868ede55b58d5863c58f8a28c95f26febc38dd583de16849b` | YES (object-level fix, F-02) |
| kyber | `ref/test/test_kyber512` (+15 more) | `0dddaf013fe872b87544e32a14669c04130c6077d8ca9d9d94d775fb4a28cfad` | `0dddaf013fe872b87544e32a14669c04130c6077d8ca9d9d94d775fb4a28cfad` | **YES** — all 16 artifacts |
| dilithium | `ref/test/test_dilithium2` (+16 more) | `e1187499d2fd9d157d92ed8e9b07ebddd2e3c0ec74c5f908d23499f13543e287` | `e1187499d2fd9d157d92ed8e9b07ebddd2e3c0ec74c5f908d23499f13543e287` | **YES** — all 17 artifacts |
| Go stdlib | `pqcheck` test program (2,968,564 B) | `d81e1efa546db902d66b25fbee72e45827b493b0400a4f80f447ffcb20abab22` | `d81e1efa546db902d66b25fbee72e45827b493b0400a4f80f447ffcb20abab22` | **YES** |
| Rust `ml-kem` | `rust-mlkem-verify` (504,928 B) | `bbe66602760785e69e5f03f913a7b9369896737f90e2a3cc8d8f3ae07699d686` | `bbe66602760785e69e5f03f913a7b9369896737f90e2a3cc8d8f3ae07699d686` | **YES** — under stated conditions (F-03) |

Full per-artifact hashes: `outputs/SHA256SUMS` (95 entries, all verify)
and the per-target `outputs/sha256sums-*.txt` files. Preserved artifacts:
`outputs/artifacts/`.

## 3. Distributed artifacts — traceability

### liboqs 0.16.0

| Distributed artifact | Source commit | Build script | Hash / signature | Status |
|---|---|---|---|---|
| GitHub release assets | `5a1a854b…` | n/a | none published | **GAP** — release has zero assets: no binary, no `.sig`/`.asc`, no `SHA256SUMS`, no SLSA/Sigstore attestation (F-01) |
| Git tag `0.16.0` | `5a1a854b…` | n/a | lightweight (unsigned) tag | **GAP** — no signature to verify |
| Codeload tarball (`archive/refs/tags/0.16.0.tar.gz`) | `5a1a854b…` | n/a | SHA-256 `162d5b51…f01eae`, verified against Homebrew's published checksum for the same URL | VERIFIED (third-party checksum, not upstream-published) |
| GitHub artifact attestations | — | — | — | **UNVERIFIED** — attestations API call rate-limited; release page shows none |
| Homebrew bottle (GHCR, x86_64_linux) | `5a1a854b…` (same tarball URL) | Homebrew formula | bottle SHA-256 `85a55828…` published | NOT COMPARED — bottle not downloaded (different platform/toolchain) |
| Distro packages (openSUSE, FreeBSD, MacPorts, AUR, MSYS2) | 0.16.0 | distro build systems | distro-published | NOT COMPARED — third-party rebuilds |
| Docker Hub `openquantumsafe` images | — | — | — | **GAP** — CI images only, no 0.16.0 release image |
| Third-party `liboqs-binaries` repo | 0.16.0 (claimed) | unknown | unknown | NOT UPSTREAM, NOT VERIFIED — listed only so it is not mistaken for official |
| `liboqs-python` 0.16.0.2 (PyPI) | — | — | PyPI page shows "With provenance"; PyPI JSON API returned `attestations: false` | **UNVERIFIED** (ambiguous); wrapper only, does not bundle a compiled liboqs |

### pq-crystals kyber / dilithium

| Distributed artifact | Source commit | Build script | Hash / signature | Status |
|---|---|---|---|---|
| GitHub releases | — | — | — | **GAP** — no releases at all, either repo ("There aren't any releases here") |
| Binaries / packages | — | — | — | **GAP** — no install target in either Makefile; Repology has no project entry |
| Downstream vendored copies (liboqs ≤0.12.0 Kyber Round 3; Dilithium removed in liboqs 0.15.0) | older commits (e.g. kyber `441c051`) | liboqs build | — | NOT THE REFERENCE REPO — vendored copies, not distributions of this code |

### Go 1.27.3 toolchain (carries `crypto/mlkem` / `crypto/mldsa`)

| Distributed artifact | Source commit | Build script | Hash / signature | Status |
|---|---|---|---|---|
| `go1.27.3.linux-amd64.tar.gz` (70,588,678 B) | Go 1.27.3 | Go release process | SHA-256 `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40` — published JSON index and dl.google.com `.sha256` agree; downloaded file matches (`sha256sum -c` OK) | VERIFIED |
| Installed `/usr/local/go` vs verified tarball | — | — | `diff -r` exit 0, zero differences | VERIFIED |
| `go1.27.3.src.tar.gz` | Go 1.27.3 | — | SHA-256 `6e7749035cf360f06b2575d162ea79df9fda8ef671889e5c375f8e50777f26bb` (published) | NOT DOWNLOADED — published value recorded only |
| Detached `.asc` signature | — | — | signer key ID `FD533C07C264648F`, created 2026-10-20 | **UNVERIFIED** — no trusted Go release public key obtainable (keyservers failed) (F-05) |

### Rust `ml-kem` 0.3.4

| Distributed artifact | Source commit | Build script | Hash / signature | Status |
|---|---|---|---|---|
| `ml-kem-0.3.4.crate` (48,011 B, crates.io) | tag `ml-kem/v0.3.4` = `6855b16a…` | `cargo build --release --locked` | SHA-256 `84ca78b66f46050d49fa21693ae8adab2081d8101b65d8067316b6b70b64a0d1` — exactly matches the `Cargo.lock` checksum | VERIFIED |
| `.crate` source vs tagged repo tree | `6855b16a…` | — | `diff -r` of `src/` clean (test-vector files excluded per `Cargo.toml`, as expected) | VERIFIED |
| Git tag `ml-kem/v0.3.4` | `6855b16a…` | n/a | lightweight (unsigned) tag | **GAP** — no signature exists to verify (F-06) |
| GitHub Releases | — | — | — | **GAP** — zero Release objects; publishes via tags only |

## 4. Runtime checks (test programs)

| Check | Result | Evidence |
|---|---|---|
| Go `pqcheck`: ML-KEM-768 keygen/encap/decap, ML-DSA-65 keygen/sign/verify | ALL CHECKS PASSED on both builds; sizes match FIPS 203/204 (ek 1184, dk seed 64, ct 1088, ss 32; pk 1952, sig 3309; tampered message rejected) | `outputs/logs/build1.log`, `outputs/logs/build2.log` |
| Rust `rust-mlkem-verify`: ML-KEM-768 round-trip | `RESULT: ML-KEM-768 round-trip OK` on both builds; ek 1184, dk seed 64 / expanded 2400, ct 1088, ss 32, shared secrets match | `outputs/logs/run-a.txt`, `outputs/logs/run-b.txt` |
| kyber `test_kyber512/768/1024` | exit 0, 100 iterations each; stdout hashes identical r1 vs r2 | `outputs/logs/kyber-r*-retest.log` |
| kyber `test_vectors512/768/1024` | exit 0, 60,000 lines each (10,000 deterministic vectors); stdout hashes identical | `outputs/logs/kyber-r*-retest.log` |
| kyber KAT `PQCgenKAT_kem512` | exit 0; `PQCkemKAT_1632.rsp` (660,402 B) identical r1 vs r2, `a30184ed…` | `outputs/artifacts/pq-crystals/PQCkemKAT_1632-r1.rsp` |
| dilithium `test_dilithium2/3/5` | exit 0, 10,000 iterations each + tampered-signature rejection; stdout hashes identical | `outputs/logs/dilithium-r*-retest.log` |
| dilithium `test_vectors2/3/5` | exit 0, 360k/480k/620k lines; stdout hashes identical | `outputs/logs/dilithium-r*-retest.log` |
| dilithium KAT `PQCgenKAT_sign2` | exit 0; `PQCsignKAT_Dilithium2.rsp` (1,941,571 B) identical r1 vs r2, `1d29c3b4…` | `outputs/artifacts/pq-crystals/PQCsignKAT_Dilithium2-r1.rsp` |
