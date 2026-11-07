# Post-Quantum Supply-Chain Verification Pack

Reusable evidence pack testing whether four pinned post-quantum library
targets rebuild deterministically from published source, and whether the
distributed artifacts a consumer can actually download trace back to that
source with verifiable hashes or signatures.

## Headline results

- **liboqs 0.16.0 — NONDETERMINISTIC with upstream defaults.** Two clean
  Release builds produce different `lib/liboqs.a` hashes
  (`1fdf54c7…e6114` vs `fbd5dc65…2d56`, both 38,720,354 bytes). Exactly one
  of 2,634 archive members differs — `src/common/common.c.o` — and the only
  difference inside it is the absolute build path embedded by GCC. The
  standard `-ffile-prefix-map` flag removes it: recompiled objects are
  byte-identical (`862b2aac…65c7e`) and re-archiving yields identical
  libraries (`9349b6d5…6849b`). Upstream documents no reproducible-build
  support.
- **pq-crystals kyber + dilithium references — DETERMINISTIC.** All
  artifacts per repo byte-identical across two fresh-clone rebuilds
  (16 kyber, 17 dilithium), no determinism flags needed. 24/24
  test-binary runs exit 0; KAT `.rsp` outputs identical across runs.
- **Go stdlib `crypto/mlkem` + `crypto/mldsa` (Go 1.27.3) — DETERMINISTIC.**
  Two clean builds of a fixed ML-KEM-768 / ML-DSA-65 test program produce
  byte-identical binaries (`d81e1efa…ab22`, 2,968,564 bytes); the program
  passes on both. The Go 1.27.3 toolchain tarball checksum verifies against
  the published value; the installed tree is byte-identical to the verified
  distribution.
- **Rust `ml-kem` 0.3.4 (RustCrypto/KEMs) — DETERMINISTIC, with conditions.**
  Two `--locked` release builds byte-identical (`bbe66602…99d686`,
  504,928 bytes) — but only with vendored dependencies and canonical
  path remapping (three `--remap-path-prefix` flags: target dir, cargo
  home, source copy) and a fixed `SOURCE_DATE_EPOCH`; the remap makes
  the hash checkout-independent. Plain builds in differently-named
  directories differ: rustc embeds absolute registry source paths
  (panic locations) and path-derived LLVM symbol hashes. The
  published `.crate` checksum matches `Cargo.lock` exactly and its source
  is byte-identical to the tagged repo tree.
- **Highest-severity finding (F-01): liboqs 0.16.0 publishes no verifiable
  artifact at all** — no signed release, no published hash, no attestation,
  no binary; the tag is lightweight (unsigned). A consumer has no
  upstream-issued integrity value to check; the only independently
  checkable hash is the one Homebrew republishes for the same tarball URL
  (verified here: `162d5b51…f01eae`).

## Targets (pinned)

| Target | Pinned version / commit | Source |
|---|---|---|
| liboqs | 0.16.0, tag commit `5a1a854b0dc9f2141bdc771c555ee60c37950183` (2026-07-09) | https://github.com/open-quantum-safe/liboqs |
| pq-crystals/kyber | HEAD `3edd5af5991927164edd4aacebfcbee00b8064e7` (2026-08-02) | https://github.com/pq-crystals/kyber |
| pq-crystals/dilithium | HEAD `d35ba3fe5449bee3e6d43e1f296c3ca818bd36be` (2026-06-03) | https://github.com/pq-crystals/dilithium |
| Go stdlib | Go 1.27.3 (`crypto/mlkem` ML-KEM-768, `crypto/mldsa` ML-DSA-65) | https://go.dev/dl/ |
| Rust `ml-kem` | 0.3.4, tag `ml-kem/v0.3.4` commit `6855b16a6cca9fc1c3eaea76776a7cd50ad67846` (2026-10-31) | https://github.com/RustCrypto/KEMs |

## Quickstart

```sh
# Fast check: verify every recorded artifact hash in the pack (seconds)
python3 src/verify_hashes.py

# Full check: rebuild all four targets twice from clean state and compare
# against the recorded verdicts (~40-60 min on 4 cores; liboqs dominates)
./src/run_all.sh
```

`run_all.sh` exits 0 only if every observed outcome matches its recorded
expectation (liboqs nondeterministic with equal sizes; the other three
deterministic with hashes matching the recorded values). It clones from the
pinned upstream sources, so it needs network access for the liboqs and
pq-crystals clones. The Rust section needs no network (vendored
dependencies).

## Layout

- `findings.md` — severity-ranked findings, each linked to its runnable
  check and output.
- `matrix.md` — source-to-evidence traceability matrix: every distributed
  binary/package found, mapped to its source commit, build script, and
  hash — or the gap marked explicitly.
- `index.md` — claim-to-evidence index: every claim in this pack and the
  file that proves it.
- `rubric.md` — what was checked, how, and what the verdicts mean.
- `index.html` — rendered findings page (self-contained).
- `src/` — harness: `run_all.sh` (full rebuild), `verify_hashes.py`
  (hash check), per-target test programs and build scripts.
- `outputs/` — `SHA256SUMS` (95 entries, all verify with `sha256sum -c`),
  preserved build artifacts, unedited build/test logs, and the four
  per-target result reports (`RESULT-*.md`).
- `walkthrough.log` — dated build/run notes, including the incidents
  encountered (disk-space failures, the three failed Rust determinism
  attempts, the liboqs member-level investigation).

## Environment the measurements were made in

Linux x86_64 (Ubuntu 24.04-based VM), gcc 13.3.0, cmake 3.28.3, git 2.43.0,
Go 1.27.3, rustc/cargo 1.99.1, python3 3.12.3. All work 2026-11-07.
Single machine, single toolchain — reproducibility on other
compilers/architectures was not tested.

## Limitations (short version)

- liboqs: static library only; the `-ffile-prefix-map` fix was demonstrated
  at object + re-archive level, not by a third pair of full clean rebuilds;
  the test suite was not run; Ninja (upstream's documented generator) was
  not installed, Makefiles were used.
- pq-crystals: `ref/` only (`avx2/` not built); KAT check is r1-vs-r2
  self-consistency, not comparison against NIST-published KAT files.
- Go: "rebuild" is defined explicitly (see rubric.md §3) because the stdlib
  ships inside the toolchain; the toolchain `.asc` signature is UNVERIFIED
  (no obtainable release public key).
- Rust: determinism holds only under the stated conditions (three-path
  remap + fixed SOURCE_DATE_EPOCH); ML-KEM-768 only; the crate's own
  NIST KAT suite was not run.
- Several upstream attestation/signature questions are UNVERIFIED because
  the unauthenticated GitHub API rate-limited during the session; each is
  labelled as such in the matrix rather than claimed either way.
