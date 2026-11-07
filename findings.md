# Findings — Post-Quantum Supply-Chain Verification Pack

Severity-ranked. Each finding links to its runnable check and output.
"UNVERIFIED" means the claim could not be established from the sources
checked — it is never presented as a pass.

## F-01 — HIGH — liboqs 0.16.0 publishes no verifiable artifact at all

Upstream publishes no signed release, no published hash, no attestation,
and no binary for 0.16.0. The GitHub release has an empty assets list
(GitHub Releases API, 2026-11-07); the tag `0.16.0` is lightweight
(unsigned). A consumer fetching 0.16.0 has no upstream-issued integrity
value to compare against — any supply-chain claim for a liboqs 0.16.0
binary rests on the distributor, not on upstream. The only independently
checkable hash is the one Homebrew republishes for the same codeload
tarball URL, verified here: tarball SHA-256
`162d5b510518ee5f285f82fa1f16402a885176e818bf1b1a4c3c91c9a2f01eae`
matches Homebrew's published checksum for that URL. Distro packages
(openSUSE, FreeBSD, MacPorts, AUR, MSYS2) are third-party rebuilds whose
hashes were not compared to this build.

- Check: `outputs/RESULT-liboqs.md` § "Traceability findings";
  `outputs/logs/build1.log` (release page/API evidence in the report).
- Mitigation: pin the tag commit
  `5a1a854b0dc9f2141bdc771c555ee60c37950183` and rebuild from source;
  verify the tarball against the Homebrew-published checksum.

## F-02 — HIGH — liboqs 0.16.0 is not deterministically rebuildable with upstream defaults

Two clean Release builds (`cmake -DCMAKE_BUILD_TYPE=Release`, Unix
Makefiles, gcc 13.3.0) produce different `lib/liboqs.a` hashes —
build1 `1fdf54c7e56434c7c360593a81686de79f105a4ac213446710556298922e6114`,
build2 `fbd5dc65047d46d0d91c79da119a9665db6946e8fa7fc1f5a2c2a05ca4232d56`
— same size (38,720,354 bytes), same 2,634 members in the same order.
Member-by-member comparison (independently re-run for this pack: exactly
1 differing member of 2,634) shows the sole difference is
`src/common/common.c.o`, whose only differing content is the absolute
source path embedded by GCC (`STT_FILE` symbol; CMake passes absolute
paths). No `__DATE__`/`__TIME__`, no debug info, no timestamps in the
archive (all member timestamps already epoch 0). Upstream documents no
reproducible-build support: no mention of `SOURCE_DATE_EPOCH`,
`-ffile-prefix-map`, or reproducibility in `CMakeLists.txt`,
`CONFIGURE.md`, or `README.md` at 0.16.0.

Remediation demonstrated: recompiling only `common.c` with
`-ffile-prefix-map=<srcdir>=/liboqs` makes both objects byte-identical
(`862b2aac3b28887a4ccd01f5ced7c429d649f014bf6f84e48b1f9663b5965c7e`),
and re-archiving with the fixed member yields byte-identical libraries
(`9349b6d5d2301c3868ede55b58d5863c58f8a28c95f26febc38dd583de16849b`).
Demonstrated at object + re-archive level, NOT by a third pair of full
clean rebuilds (each full build ~33 min on this 4-core host).

- Check: `src/run_all.sh` (liboqs section); `outputs/RESULT-liboqs.md`
  §§ "SHA-256 hashes", "Deterministic? NO"; `outputs/logs/build1.log`,
  `outputs/logs/build2.log`, `outputs/logs/fix_experiment.log`;
  the two differing members are preserved as
  `outputs/artifacts/liboqs/common.c.o-build1` /
  `common.c.o-build2` (SHA-256 `91b6caea…` / `bb316ae5…`).

## F-03 — MEDIUM — Rust `ml-kem` 0.3.4: plain builds are not bit-reproducible

`ml-kem` 0.3.4 (RustCrypto/KEMs, tag `ml-kem/v0.3.4`,
`6855b16a6cca9fc1c3eaea76776a7cd50ad67846`) is deterministic only under
stated conditions: identical build paths plus canonical path remapping
and a fixed `SOURCE_DATE_EPOCH`. The pack's canonical method (see
rubric.md) vendors all dependencies into `src/rust-mlkem/vendor/` and
remaps three path families — target dir, cargo home, and source copy
(the vendor dir lives under the source copy) — to fixed placeholders,
which makes the hash checkout-independent: two builds in different
directories produce byte-identical binaries,
`bbe66602760785e69e5f03f913a7b9369896737f90e2a3cc8d8f3ae07699d686`
(504,928 bytes). Vendoring also removes the build's network dependency:
the crates.io index fetch failed twice during validation with
"transfer too slow", killing two full runs; the vendored build needs no
network and Cargo still verifies every vendored crate against the
`Cargo.lock` checksums. Hash lineage (same sources, different embedded
paths): the worker's original single-remap v4 pair produced `98aec69a…`
(path-dependent, preserved in `outputs/RESULT-rust-mlkem.md` §4); the
three-remap registry build produced `315becfe…` (checkout-independent);
the vendored build produces `bbe66602…` (checkout-independent, the
pack's canonical recorded hash — embedded paths are now
`/src/vendor/...` instead of `/cargo-home/registry/...`).
Three earlier pairs with a single remap (target dir only) all differed,
each documented with its cause:

- v1 plain builds: `7fb78d57…` vs `972c1dff…` — rustc embeds absolute
  registry source paths (panic locations) plus path-derived
  `.llvm.<hash>` symbol suffixes (39,249 differing bytes).
- v2 remap with a non-canonical prefix (`..` in the path): remap silently
  did not apply; still differed.
- v3 canonical remap but differently-named cargo homes
  (`cargo-home-ra` vs `cargo-home-rb`): the directory names still leak
  into embedded paths (37,375 differing bytes).
- v4 (pack method at the time: three remaps, registry sources, builds
  in two different checkout paths): identical,
  `315becfe141f1f6137b5a2ad3802668615b26718dab7e644eb16038343fd8f09`
  (504,928 bytes). The pack's canonical method is now the VENDORED
  build (see rubric.md), which produces
  `bbe66602760785e69e5f03f913a7b9369896737f90e2a3cc8d8f3ae07699d686`
  instead — same sources, different embedded paths
  (`/src/vendor/...` vs `/cargo-home/registry/...`). (The worker's
  original v4 pair, with only the target dir remapped, produced
  `98aec69a…` — a path-dependent hash preserved in
  `outputs/RESULT-rust-mlkem.md` §4.)

This is a property of the Rust toolchain/build setup, not of the `ml-kem`
source. A downstream rebuilder who does not replicate the path discipline
will get a different binary and cannot tell from the hash alone whether
the difference is benign.

- Check: `src/run_all.sh` (rust section); `outputs/RESULT-rust-mlkem.md`
  §§4–5; `outputs/logs/build-a*.log`, `outputs/logs/build-b*.log`;
  final binaries in `outputs/artifacts/rust-mlkem/`.

## F-04 — MEDIUM — pq-crystals references publish no releases, binaries, or checksums

Neither `pq-crystals/kyber` nor `pq-crystals/dilithium` has any GitHub
release, published artifact, published checksum, or install target — both
release pages read "There aren't any releases here" (fetched 2026-11-07).
Repology has no project entry for the reference repos. The only stable
identifiers are git commit hashes (kyber `3edd5af5…`, dilithium
`d35ba3fe…`); the single stale 2021 tags (v3.0 / v3.1) do not point at
current HEAD. Verification can therefore only rest on the pinned commit +
independent rebuild reproducibility (demonstrated here: all artifacts
per repo byte-identical (16 kyber, 17 dilithium) across two fresh-clone rebuilds, no flags needed)
+ the deterministic in-repo KAT vectors — never on matching a vendor
checksum. Kyber's README additionally states the software "is no longer
actively maintained" and points production users to mlkem-native.

- Check: `src/run_all.sh` (pq-crystals section);
  `outputs/RESULT-pq-crystals.md` §§1, 7;
  `outputs/logs/kyber-r*-build.log`, `outputs/logs/dilithium-r*-build.log`;
  artifacts in `outputs/artifacts/pq-crystals/`.

## F-05 — MEDIUM — Go toolchain `.asc` signature UNVERIFIED (checksum verified)

The Go 1.27.3 distribution checksum verifies: published SHA-256
`65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40`
(go.dev JSON index and dl.google.com `.sha256` agree; downloaded
70,588,678-byte tarball matches, `sha256sum -c` OK), and the installed
`/usr/local/go` tree is byte-identical to the extracted verified tarball
(`diff -r` exit 0). The detached PGP signature
(`go1.27.3.linux-amd64.tar.gz.asc`, signer key ID `FD533C07C264648F`)
could NOT be verified: no trusted copy of the Go release public key could
be obtained in this environment (both keyservers failed). The signature
file is preserved for later verification. The checksum result is
independent of the signature and stands on two agreeing published sources
plus the installed-tree diff.

- Check: `outputs/RESULT-go-stdlib.md` §5; `src/run_all.sh` does not
  re-fetch the toolchain (it uses the installed one) — the checksum
  verification is recorded in the report, not re-runnable offline.

## F-06 — LOW — RustCrypto/KEMs publishes via lightweight unsigned tags; no GitHub Releases

Tag `ml-kem/v0.3.4` is lightweight (`git cat-file -t` → `commit`; `git
verify-tag` fails: "cannot verify a non-tag object"). The repo has zero
GitHub Release objects (releases page, 2026-11-07). Mitigations verified
here: the published `.crate` SHA-256
(`84ca78b66f46050d49fa21693ae8adab2081d8101b65d8067316b6b70b64a0d1`)
exactly matches the `Cargo.lock` checksum, Cargo verifies it on every
`--locked` build, and the `.crate`'s `src/` is byte-identical to the
tagged repo tree (`diff -r` clean). A branch named `ml-kem/v0.3.4` also
exists and points at a different commit (`c53fd02b…`); the tag commit is
authoritative, and the `ml-kem/` tree is identical at both (tree hash
`834e541c…`), so the distinction does not change the built source — but a
naive `git clone --branch ml-kem/v0.3.4` checks out the branch, not the
tag.

- Check: `outputs/RESULT-rust-mlkem.md` §§1, 6;
  `outputs/artifacts/rust-mlkem/ml-kem-0.3.4.crate`.

## F-07 — LOW — Vendored-dependency assessment (build-graph level)

- **liboqs 0.16.0**: no `FetchContent`/`ExternalProject` in
  `CMakeLists.txt` — the default build fetches nothing at build time. It
  vendors its own AES/SHA-2/SHA-3 implementations in-tree
  (`src/common/aes`, `src/common/sha2`, `src/common/sha3`) plus the
  algorithm implementations themselves; the only external dependency is
  the optional system OpenSSL (`find_package(OpenSSL 1.1.1)`, off unless
  `OQS_USE_OPENSSL`). In-tree provenance of each vendored implementation
  was not individually audited — this is a build-graph assessment, not a
  per-file provenance audit.
- **pq-crystals references**: no vendored dependencies; plain Makefiles,
  only system OpenSSL headers/libcrypto for the nistkat KAT binaries.
- **Go stdlib**: no third-party dependencies in the test program
  (`GOPROXY=off`, stdlib only); the stdlib itself ships inside the
  checksum-verified toolchain.
- **Rust `ml-kem`**: 28 packages in the committed `Cargo.lock`
  (`ml-kem 0.3.4`, `module-lattice 0.2.4`, `kem 0.3.0`, `hybrid-array
  0.4.15`, `sha3 0.12.0`, `rand_core 0.10.1`, `getrandom 0.4.3`,
  `ctutils 0.4.8`, `libc 0.2.191`, …); every package checksum is verified
  by Cargo on each `--locked` build against fresh registries. The
  `ml-kem` checksum itself was verified directly (F-06).
- **Downstream copies**: liboqs 0.16.0 exists in Homebrew, openSUSE
  Tumbleweed, FreeBSD, MacPorts, AUR, MSYS2 as third-party rebuilds; a
  third-party `liboqs-binaries` repo ships prebuilt 0.16.0 binaries (not
  upstream, not verified, listed only because a consumer could mistake it
  for official). No downstream package hash was compared to this build.

## F-08 — INFO — Go stdlib rebuild cache timestamps are not build artifacts

`go build -a std` twice: 2,618 of 2,619 cache entries byte-identical after
normalizing Go cache entries' embedded write timestamps; the sole
exception is `trim.txt`, a bare cache-trim epoch timestamp — not a
compiled artifact. Raw cache manifests are therefore not a valid
byte-equality check for stdlib rebuilds; the final linked binaries (the
primary check) matched byte-for-byte with no normalization.

- Check: `outputs/RESULT-go-stdlib.md` §6; `outputs/logs/stdbuild1.log`,
  `outputs/logs/stdbuild2.log`.

## Findings that are NOT present (checked, absent)

- No `__DATE__`/`__TIME__` macros in either pq-crystals `ref/` tree
  (grep, 2026-11-07).
- No timestamps in liboqs archive output (all member timestamps epoch 0).
- No massaged outputs anywhere: every differing pair is reported with both
  hashes, and every remediation attempt (including failed ones) is logged.
- No secret, key, or key material appears in this pack; test programs print
  sizes and booleans only.
