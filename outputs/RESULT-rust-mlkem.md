# RESULT — Rust `ml-kem` crate (RustCrypto/KEMs), ML-KEM-768 build verification

- **Work directory:** `~/workspace/goals/postfiat-task-node-connection/hidden_files/task-c0496161/targets/rust-mlkem/`
- **Verification date:** 2026-11-07 (builds 17:00–17:09 UTC / 2026-11-08 00:00–00:09 WIB)
- **Crate:** `ml-kem` **0.3.4** (latest at time of check; `default_version`/`max_version`/`newest_version` all `0.3.4`)
- **Repo:** https://github.com/RustCrypto/KEMs
- **Crate page:** https://crates.io/crates/ml-kem
- **Docs:** https://docs.rs/ml-kem

## Verdicts

| Check | Result |
|---|---|
| Crate exists on crates.io, version pinned | ✅ VERIFIED — `ml-kem =0.3.4`, published 2026-10-31T22:07:26Z |
| Repo commit for the release | ✅ VERIFIED — tag `ml-kem/v0.3.4` = commit `6855b16a6cca9fc1c3eaea76776a7cd50ad67846` (also `master` HEAD at check time) |
| ML-KEM-768 round-trip (keygen → encapsulate → decapsulate) | ✅ PASS — shared secrets match, all sizes FIPS 203-correct |
| Deterministic build (two independent clean rebuilds) | ✅ **YES — with stated conditions** (see §4). Plain builds without path remapping are NOT bit-for-bit reproducible (see §5). |
| crates.io `.crate` checksum vs `Cargo.lock` | ✅ VERIFIED — identical SHA-256 (see §6) |
| Published `.crate` source vs tagged repo source | ✅ VERIFIED — `src/` byte-identical |
| Release tag signature | ⚠️ UNVERIFIED / not applicable — tag is lightweight (type `commit`), no GPG signature exists to verify; repo publishes via tags only, no GitHub Release objects |

## 1. Crate and repo identity (research first, primary sources only)

Sources consulted (all fetched 2026-11-07 ~16:50–16:58 UTC):

- crates.io API `https://crates.io/api/v1/crates/ml-kem` (saved as `crates-api.json`):
  `ml-kem` created 2023-08-24, `default_version`/`max_version`/`newest_version` = `0.3.4`,
  updated/created 2026-10-31T22:07:26.669701Z, 14,588,588 total downloads, 10,418,905 recent,
  license `Apache-2.0 OR MIT`, repository `https://github.com/RustCrypto/KEMs`,
  homepage `https://github.com/RustCrypto/KEMs/tree/master/ml-kem`.
  Description: "Pure Rust implementation of the Module-Lattice-Based Key-Encapsulation
  Mechanism Standard (formerly known as Kyber) as described in FIPS 203".
- GitHub API `https://api.github.com/repos/RustCrypto/KEMs` + `/tags?per_page=100`
  (saved as `github-repo.json`, `github-tags.json`): tag `ml-kem/v0.3.4` →
  `6855b16a6cca9fc1c3eaea76776a7cd50ad67846`.
- `git ls-remote https://github.com/RustCrypto/KEMs.git` (independent of the API):
  `refs/tags/ml-kem/v0.3.4` = `6855b16a6cca9fc1c3eaea76776a7cd50ad67846`,
  `refs/heads/master` = same commit, `HEAD` = same commit.
- Local clone `repo-ml-kem-v0.3.4/` (shallow, tag fetched explicitly):
  - Tag commit: `6855b16a6cca9fc1c3eaea76776a7cd50ad67846`,
    date 2026-10-31 16:05:50 -0600 (= 22:05:50 UTC), author Tony Arcieri
    <bascule@gmail.com>, subject `ml-kem v0.3.4 (#416)`.
    Changelog: perf improvement (NTT sampling, #387); fixes: redact secret key material
    from `Debug` (#394), harden equality testing (#414), harden zeroization (#415);
    security: bump `ctutils` to v0.4.5, MSRV 1.87 (#405), harden reduction (#409),
    bump `module-lattice` to v0.2.4 (#413).
  - `ml-kem/Cargo.toml` at the tag: `name = "ml-kem"`, `version = "0.3.4"`,
    `edition = "2024"`, `rust-version = "1.87"`, license `Apache-2.0 OR MIT`.
  - **Branch/commit confusion, resolved:** there is also a *branch* named
    `ml-kem/v0.3.4` pointing at a different commit
    `c53fd02ba7dcf5dc2c9287f814d1e401f26bfcce` ("ml-kem v0.3.4", 2026-10-31 15:59:55 -0600,
    version-bump commit touching only `Cargo.lock`, `ml-kem/CHANGELOG.md`,
    `ml-kem/Cargo.toml`). A naive `git clone --branch ml-kem/v0.3.4` checks out the
    **branch**, not the tag. The tag commit is authoritative: it is the commit the
    tag points to, it is `master` HEAD, and it was published to crates.io ~2 minutes
    after it (22:05:50 UTC → 22:07:26 UTC). Verified that the `ml-kem/` tree is
    **identical** at both commits (tree hash `834e541cf5a702b09ef35df857fcf2daab4fde74`
    in both; `git diff --name-only` between them is empty), so this distinction does
    not change the built source — but the recorded release commit is the tag commit
    `6855b16a…`.
- API used: `ml-kem/src/lib.rs` (tag `ml-kem/v0.3.4`, saved as `ml-kem-lib.rs.txt`),
  `src/encapsulation_key.rs`, `src/decapsulation_key.rs`, `src/param.rs`
  (saved as `ml-kem-*.rs.txt`), `ml-kem/Cargo.toml` and `README.md`
  (saved as `ml-kem-Cargo.toml.txt`, `ml-kem-README.md.txt`).
  Doc example: `MlKem768::generate_keypair()` (requires the `getrandom` feature),
  `ek.encapsulate()` → `(ct, k_send)`, `dk.decapsulate(&ct)` → `k_recv`,
  `assert_eq!(k_send, k_recv)`.
- Minor doc discrepancy noted: the README says "The default features are `[]`
  (nothing)", but `ml-kem/Cargo.toml` says `default = ["alloc"]`. The build used
  the Cargo.toml default plus `getrandom`; the README line appears stale.

## 2. Test program (fixed)

- `src/Cargo.toml` — binary crate `rust-mlkem-verify` 0.1.0, edition 2021,
  `ml-kem = { version = "=0.3.4", features = ["getrandom"] }`,
  `[profile.release] debug = false`. SHA-256:
  `a7353212ef4e7583edb0edc874f611e883e9c6d8d3722111f77a3c3c613ee275`.
- `src/src/main.rs` — ML-KEM-768 keygen → encapsulate → decapsulate, asserts the
  shared secrets match, prints sizes only (no key/ciphertext/secret material).
  SHA-256: `15610117e0e520952226ae3ef5dcc0b8fb523cedcac40061573634ffb64ed601`.
- `src/Cargo.lock` — generated with `cargo generate-lockfile`, committed in `src/`.
  SHA-256: `c9d13db7e653e65613b7e09a03200c3e4f617fe2711e3635300a425e73f31f97`.
  28 packages; key versions: `ml-kem 0.3.4`, `module-lattice 0.2.4`, `kem 0.3.0`,
  `hybrid-array 0.4.15`, `sha3 0.12.0`, `shake 0.1.0`, `rand_core 0.10.1`,
  `getrandom 0.4.3`, `ctutils 0.4.8`, `libc 0.2.191`.
  (Optional deps `pkcs8`/`der`/`spki`/`const-oid`/`base64ct`/`zeroize` appear in the
  lockfile's resolve graph and are downloaded, but are **not compiled** — the
  `pkcs8` feature is not enabled. See build logs.)
- **Correction found during testing (v1 program):** the first program asserted the
  decapsulation key serializes to 2400 bytes and failed at runtime
  (`run-a-trial-v1.txt`, exit 101) — the round-trip itself already passed
  (`shared_secrets_match: true`, ek 1184, ct 1088, ss 32). Root cause was my
  program's assumption, not the crate: per `ml-kem` 0.3.4
  `src/decapsulation_key.rs`, `DecapsulationKey::to_bytes()` serializes the
  **64-byte seed** (`d || z`), which is the crate's documented `KeyExport`
  behaviour. The FIPS 203 expanded 2400-byte form is available via the
  deprecated `ExpandedKeyEncoding::to_expanded_bytes()`. The final program
  asserts both: seed 64 bytes and expanded 2400 bytes. The deprecated-trait
  use produces one expected compiler warning (see build logs); it is not an error.

## 3. Test-program runtime results (final binaries, both runs)

Both binaries exit 0; outputs are byte-identical (`diff run-a.txt run-b.txt` → no diff).

```text
crate: ml-kem 0.3.4 (RustCrypto/KEMs, tag ml-kem/v0.3.4)
parameter set: ML-KEM-768 (FIPS 203)
encapsulation_key_bytes: 1184
decapsulation_key_seed_bytes: 64
decapsulation_key_expanded_bytes: 2400
ciphertext_bytes: 1088
shared_secret_bytes: 32
shared_secrets_match: true
expected: ek=1184 dk_seed=64 dk_expanded=2400 ct=1088 ss=32
RESULT: ML-KEM-768 round-trip OK
```

All sizes match FIPS 203 ML-KEM-768 (ek 1184, dk expanded 2400, ct 1088, ss 32);
the crate's seed-form dk serialization is 64 bytes, as documented in its source.

## 4. Deterministic build — YES (under stated conditions)

**Final pair (v4) — the verdict pair.** Identical build commands, identical
paths, `cargo build --release --locked`, `SOURCE_DATE_EPOCH=1791307646` (fixed
for both builds), `RUSTFLAGS="--remap-path-prefix <target-dir>=/build/rust-mlkem"`,
fresh `CARGO_HOME` (`cargo-home-repro`) and fresh `CARGO_TARGET_DIR`
(`target-repro`) for each build, wiped between builds; same source dir `src/`
and same `Cargo.lock`. Full logs: `build-a.log`, `build-b.log` (unedited, via `tee`).

| Build | Time (UTC) | Duration | Binary | Size | SHA-256 |
|---|---|---|---|---|---|
| A (final) | 2026-11-07 17:07:56–17:08:26 | 29.76 s | `binaries-final/rust-mlkem-verify-final-a` | 504,928 B | `98aec69a19785e0549cda63e443d2350cfd5b2fe64d79473919fa6cebceaf7b3` |
| B (final) | 2026-11-07 17:08:38–17:09:38 | 59.58 s | `binaries-final/rust-mlkem-verify-final-b` | 504,928 B | `98aec69a19785e0549cda63e443d2350cfd5b2fe64d79473919fa6cebceaf7b3` |

`cmp binaries-final/rust-mlkem-verify-final-a binaries-final/rust-mlkem-verify-final-b`
→ **BINARIES IDENTICAL**. Deterministic: **YES**.

Conditions the YES depends on (all recorded in the logs): same toolchain
(rustc/cargo 1.99.1, see §7), same source + `Cargo.lock`, same build-directory
paths (cleaned between builds), `--remap-path-prefix` to a fixed placeholder,
fixed `SOURCE_DATE_EPOCH`. Note on `SOURCE_DATE_EPOCH`: the value used,
`1791307646`, was intended to be the crates.io publish time
2026-10-31T22:07:26Z, whose true epoch is `1793484446` (verified with
`date -d`); the wrong value was used identically in both builds, so it cannot
explain a match or a difference, and rustc does not embed `SOURCE_DATE_EPOCH`
in the binary. A re-run should use `1793484446` for exactness.

## 5. Reproducibility investigation — measures tried, in order

1. **v1 — plain builds, separate `CARGO_HOME`/`CARGO_TARGET_DIR`, no remap, no
   `SOURCE_DATE_EPOCH`** (`build-a-trial-v1.log`, `build-b-trial-v1.log`;
   binaries in `binaries-trial/`):
   A `7fb78d576a103e1817ff519a8fb4400709eca9e5efb1d7c18d44f9182684bff7`,
   B `972c1dff6d168c14fcf0d2ed2de48b5528d1db4dcb3f8583acadff3688617e77`
   (both 505,528 B). **DIFFER.** Cause found by `strings`/`cmp`: the only
   string-level differences were 4 absolute registry paths
   (`…/cargo-home-a/registry/src/…/ml-kem-0.3.4/src/decapsulation_key.rs`,
   `algebra.rs`, `rand_core-0.10.1/src/unwrap_err.rs`,
   `hybrid-array-0.4.15/src/iter.rs` — panic-location file paths) plus derived
   `.llvm.<hash>` symbol suffixes that change when those paths change
   (39,249 differing bytes by `cmp -l`). No source/content difference.
2. **v2 — remap with a non-canonical prefix** (`--remap-path-prefix $PWD/..=…`,
   `build-a-v2-remap-broken.log`, `build-b-v2-remap-broken.log`):
   A `2cc189e892afe19d15579130e3c2b5374783678114ee524f74dca28becdcfebf`,
   B `f1a64dc9e77b1a59c6a7b620aed32d10cf427c52315d299385427ff6b7e93ab6`
   (both 505,240 B). **DIFFER — remap did not apply.** The prefix contained
   `/..`, which rustc matches literally, so it never matched the canonicalized
   paths; absolute `/home/hatch/…/cargo-home-fa|fb/…` paths were still embedded.
   Lesson recorded: the remap prefix must be canonical (no `..`).
3. **v3 — remap with canonical prefix, but still separate `cargo-home-ra` /
   `cargo-home-rb`** (`build-a-v3-remap.log`, `build-b-v3-remap.log`; binaries
   in `binaries-v3/`):
   A `69d7728973a62ea66bab01098c0f722a3921bfeea6388064102f3df688dd81e8`,
   B `5c394d6099b9da0b06666c2f5e9fcc3bf4c4db53b9aae6f690884b563bf4ee41`
   (both 504,904 B). **DIFFER.** Remap worked (paths now
   `/build/rust-mlkem/cargo-home-ra|rb/…`, zero `/home/hatch` strings), but the
   differing directory names `cargo-home-ra` vs `cargo-home-rb` still leak into
   the embedded paths, and the `.llvm.<hash>` suffixes follow them (37,375
   differing bytes). String-level diff proved these were the *only* differences.
4. **v4 — canonical remap + identical build paths, cleaned between builds**
   (the verdict pair in §4): **IDENTICAL** (`98aec69a…` both).

Conclusion: the `ml-kem` 0.3.4 build is deterministic **iff the build paths are
identical** (or fully remapped to identical placeholders). Plain builds in
differently-named directories are not bit-for-bit reproducible, purely because
rustc embeds absolute registry source paths (panic locations) and path-derived
LLVM symbol hashes. This is a property of the Rust toolchain/build setup, not
of the `ml-kem` source.

## 6. Traceability

- **`.crate` checksum (published package):** downloaded
  `https://crates.io/api/v1/crates/ml-kem/0.3.4/download` → `ml-kem-0.3.4.crate`
  (48,011 B, gzip), SHA-256
  `84ca78b66f46050d49fa21693ae8adab2081d8101b65d8067316b6b70b64a0d1`
  (saved in `ml-kem-0.3.4.crate.sha256`).
  `Cargo.lock` records `checksum = "84ca78b66f46050d49fa21693ae8adab2081d8101b65d8067316b6b70b64a0d1"`
  for `ml-kem 0.3.4` — **exact match**. Cargo verified this checksum on every
  build (`--locked` builds succeeded against fresh `CARGO_HOME`s).
  Note: the sparse-index direct fetch was **not** usable here — both
  `https://index.crates.io/ml/-/k-/ml-kem` and `…/ml/ke/ml-kem` returned 404
  `NoSuchKey` (saved as `index-ml-kem*.txt`); the crates.io API and Cargo itself
  were used instead. The `dl` endpoint in the index config is
  `https://static.crates.io/crates`.
- **`.crate` source vs repo:** extracted `ml-kem-0.3.4.crate`; `diff -r` of its
  `src/` against the cloned tag tree `repo-ml-kem-v0.3.4/ml-kem/src` →
  **identical** (no differences). (The `.crate` excludes the test-vector files
  listed in `ml-kem/Cargo.toml`'s `exclude`, as expected.)
- **Release tags:** tags exist and are verified via API + `git ls-remote` +
  local fetch (`ml-kem/v0.3.4`, plus the full tag list in `github-tags.json`:
  67 tags, including `ml-kem/v0.3.4`, `v0.3.3`, `v0.3.2`, `v0.3.1`, `v0.3.0`
  and pre-releases).
- **Signatures — UNVERIFIED / not applicable:** `ml-kem/v0.3.4` is a
  **lightweight tag** (`git cat-file -t refs/tags/ml-kem/v0.3.4` → `commit`;
  `git verify-tag` → "cannot verify a non-tag object of type commit").
  There is no annotated/signed tag object and therefore no GPG signature to
  verify. The GitHub Releases list page
  (`https://github.com/RustCrypto/KEMs/releases`, saved as
  `github-releases-page.html`, HTTP 200) contains **zero** release entries —
  the repo publishes via tags only, with no GitHub Release objects. The GitHub
  Releases API was rate-limited for unauthenticated requests at check time
  (`403 API rate limit exceeded`, saved in `github-releases.json`), so the
  "no releases" finding rests on the HTML page, not the API.
- **docs.rs:** `https://docs.rs/ml-kem/latest/ml_kem/` returned HTTP 200.

## 7. Toolchain and environment (see also `env-details.txt`)

- `cargo 1.99.1 (5f94df478 2026-08-27)`, `rustc 1.99.1 (58cf8f9c3 2026-10-13)`,
  host `x86_64-unknown-linux-gnu`, LLVM 23.1.1. Crate MSRV is 1.87; toolchain
  exceeds it.
- `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`, `git 2.43.0`,
  `python3 3.12.3`, Ubuntu 24.04.5 LTS, kernel
  `Linux htch-runtime 7.0.0-43-generic x86_64`.
- No `CARGO_*`/`RUST_*`/`SOURCE_DATE_EPOCH` variables set in the base
  environment; `RUSTFLAGS`/`SOURCE_DATE_EPOCH`/`CARGO_HOME`/`CARGO_TARGET_DIR`
  were set per-build as recorded in §4–§5 and in the build logs.
- Nothing installed system-wide; no secrets/keys involved; nothing pushed,
  no repo created, no browser work (plain `curl` fetches of public pages only).

## 8. Limitations

- Determinism was demonstrated on this one machine/toolchain (rustc 1.99.1,
  x86_64 Linux). Reproducibility on another machine requires the same
  toolchain, the same pinned `Cargo.lock`, and the same (or fully remapped)
  build paths.
- The verification covers ML-KEM-768 only (the task's target parameter set),
  not ML-KEM-512/1024, and covers the round-trip + sizes, not the NIST
  known-answer test vectors in the crate's own test suite (those were not run;
  the crate's `tests/` are excluded from the published `.crate`).
- The `getrandom` feature (OS RNG) is required for key generation; the program
  therefore depends on OS randomness at runtime, which is expected and does
  not affect build determinism.
- GitHub API unauthenticated rate limiting was hit twice during research
  (releases + one commit fetch); all findings that depended on those calls
  were re-established via `git ls-remote` / `git fetch` / HTML fetches instead,
  and the rate-limit responses are preserved (`github-releases.json`,
  `github-commit-6855.json`).

## 9. Files in this directory

- `RESULT.md` — this file.
- `src/Cargo.toml`, `src/src/main.rs`, `src/Cargo.lock` — fixed test program.
- `build-a.log`, `build-b.log` — final (v4) build logs, unedited.
- `build-a-trial-v1.log`, `build-b-trial-v1.log` — v1 plain-build logs.
- `build-a-v2-remap-broken.log`, `build-b-v2-remap-broken.log` — v2 logs.
- `build-a-v3-remap.log`, `build-b-v3-remap.log` — v3 logs.
- `run-a.txt`, `run-b.txt` — final binary outputs (identical).
- `run-a-trial-v1.txt`, `run-a-v2-remap-broken.txt`, `run-b-v2-remap-broken.txt`,
  `run-a-v3.txt`, `run-b-v3.txt` — earlier run outputs.
- `sha256-a.txt`, `sha256-b.txt` — final binary hashes;
  `sha256-*-trial-v1.txt`, `sha256-*-v2-remap-broken.txt`,
  `sha256-*-v3-remap.txt` — earlier hashes; `sha256sums.txt` — consolidated
  hashes (final binaries, `.crate`, `Cargo.lock`, `Cargo.toml`, `main.rs`).
- `binaries-final/` — the two identical final binaries.
- `binaries-trial/`, `binaries-v3/` — earlier binaries (differing pairs, kept as evidence).
- `env-details.txt`, `lockfile-generate.log` — environment and lockfile generation.
- `ml-kem-0.3.4.crate`, `ml-kem-0.3.4.crate.sha256` — published package + its hash.
- `repo-ml-kem-v0.3.4/` — shallow clone of RustCrypto/KEMs at tag `ml-kem/v0.3.4`.
- `crates-api.json`, `github-repo.json`, `github-tags.json`,
  `github-tag-ref.json`, `github-commit-c53f.json`, `github-releases-page.html`,
  `ml-kem-Cargo.toml.txt`, `ml-kem-README.md.txt`, `ml-kem-lib.rs.txt`,
  `ml-kem-encapsulation_key.rs.txt`, `ml-kem-decapsulation_key.rs.txt`,
  `ml-kem-param.rs.txt` — primary-source research artifacts.
  (`index-ml-kem*.txt`, `index2.txt`, `github-releases.json`,
  `github-commit-6855.json`, `github-tag-obj.json` record the failed/rate-limited
  lookups described in §6/§8.)
- `tmp/` — scratch (string-diff working files).
