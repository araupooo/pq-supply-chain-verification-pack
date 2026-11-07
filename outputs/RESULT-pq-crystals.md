# pq-crystals reference implementations — build verification result

Target: **pq-crystals/kyber** AND **pq-crystals/dilithium** (reference implementations only,
`ref/` directory). Work performed 2026-11-07, 16:50–17:47 UTC (23:50–00:47 WIB).
All commands, logs and hashes are preserved unedited in this directory.

## Verdict

| Repo | Deterministic rebuild (r1 vs r2) | Tests pass |
|---|---|---|
| kyber | **YES** — all 16 artifacts byte-identical, no determinism flags needed | **YES** — 12/12 runs exit 0, stdout hashes identical across runs |
| dilithium | **YES** — all 16 artifacts byte-identical after one environment remediation (see §5), no determinism flags needed | **YES** — 12/12 runs exit 0, stdout hashes identical across runs |

No `SOURCE_DATE_EPOCH`, fixed `CFLAGS`, or any other determinism measure was tried or
needed: the plain upstream-documented build is already bit-reproducible on this machine.
No outputs were massaged. No `__DATE__`/`__TIME__` macros exist in either `ref/` tree
(verified by grep).

## 1. Pinned sources (research first, primary sources only)

### kyber — https://github.com/pq-crystals/kyber
- HEAD built: `3edd5af5991927164edd4aacebfcbee00b8064e7`
- Commit date: 2026-08-02T10:40:20+02:00 — "Fix suggested by Philipp Klaus Krause (issue #109)
  for systems with integers that have less than 32 bits"
- Default branch: `main` (308 commits). Clone URL used: `https://github.com/pq-crystals/kyber.git`
- Only tag: `v3.0` → `8e9308bd0f25fa698e4f37aba216249261f8b352` (2021-02-09) — **not** HEAD.
- GitHub API (checked 2026-11-07): `archived: false`, `disabled: false`, created 2017-06-08,
  pushed 2026-08-02. **Not archived/read-only**, but the README states:
  "We no longer actively maintain this software, at least not to the extent that would be
  necessary to recommend it for production use", and points users to
  [mlkem-native](https://github.com/pq-code-package/mlkem-native) (PQCA/PQ Code Package).
- **Releases: NONE.** GitHub releases page (`https://github.com/pq-crystals/kyber/releases`,
  fetched 2026-11-07 16:51 UTC) reads verbatim: "There aren't any releases here".
  The unauthenticated GitHub REST API was rate-limited at check time, so the releases-page
  fetch is the recorded evidence.

### dilithium — https://github.com/pq-crystals/dilithium
- HEAD built: `d35ba3fe5449bee3e6d43e1f296c3ca818bd36be`
- Commit date: 2026-06-03T22:03:07+02:00 — "Fix for issue #113: Added stricter infinity norm
  check as required by spec."
- Default branch: `master` (187 commits). Clone URL used:
  `https://github.com/pq-crystals/dilithium.git`
- Only tag: `v3.1` → `9dddb2a0537734e749ec2c8d4f952cb90cd9e67b` (2021-02-23) — **not** HEAD.
- GitHub API (checked 2026-11-07): `archived: false`, `disabled: false`, created 2017-11-25,
  pushed 2026-06-03. **Not archived/read-only.** The README carries no maintenance-status
  notice (unlike kyber), but the last commit is 2026-06-03 and the scheme is standardized
  as FIPS 204 (README).
- **Releases: NONE.** GitHub releases page (`https://github.com/pq-crystals/dilithium/releases`,
  fetched 2026-11-07 16:51 UTC) reads verbatim: "There aren't any releases here".

### What "no releases" means for traceability
There is no versioned, signed, or checksummed artifact published by the project for either
repo. The only stable identifiers are git commit hashes (above) and the single stale 2021
tags, which do **not** point at current HEAD. Anyone verifying a build must pin the commit
hash; there is no upstream-published hash to compare against — reproducibility can only be
demonstrated by independent rebuild (which this report does), never by matching a vendor
checksum. See §6 for the packaging gap.

## 2. Build method

Documented build path from each repo's README: `cd ref/ && make`.
- kyber `make` (default target `all`) builds test + speed + shared libs + nistkat KAT binaries.
- dilithium `make` (default target `all`) builds **test binaries only**, so
  `make speed shared nistkat` was additionally run to get a comparable artifact set.
- Each run was a **fresh clone** into a separate directory (`kyber-r1`, `kyber-r2`,
  `dilithium-r1`, `dilithium-r2`), `make clean` first, then the documented build.
  Build script: `src/build.sh` (hashing: `src/hash.sh`, test runs: `src/test.sh`,
  re-run with workspace capture: `src/retest.sh`).
- No system-wide installs; nothing was pushed anywhere; no GitHub repo created.

Build timeline (UTC 2026-11-07): kyber r1 16:52–16:55; kyber r2 + dilithium r1 + dilithium r2
16:56–17:03; dilithium r1 nistkat remediation 17:04; first test runs 17:04–17:31;
clean re-run of all test binaries 17:35–17:47. Each full build took ~3–4 min (slow VM CPU).

## 3. Environment

- OS/kernel: `Linux htch-runtime 7.0.0-43-generic #1 SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux`
- Compiler: `cc` / `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0` (Makefile default `CC ?= /usr/bin/cc`)
- cmake 3.28.3 (installed but unused — these repos build with plain Makefiles)
- git 2.43.0; python3 3.12.3; Go 1.27.3 (`/usr/local/go/bin/go`); rustc 1.99.1
- OpenSSL dev headers present (`/usr/include/openssl/evp.h`, `libcrypto.so.3`) — required by
  the nistkat KAT binaries (`-lcrypto`).
- Env vars: no `CC`, `CFLAGS`, `NISTFLAGS`, `LDFLAGS`, `SOURCE_DATE_EPOCH`, or `TZ` set;
  Makefiles' own flags apply (`-O3 -fomit-frame-pointer`, plus `-z noexecstack` for kyber).
- Constraint found during the work: `/tmp` is a 512 MiB tmpfs shared with other tasks; it hit
  100% full during testing (see §5). The root filesystem has 7.0 GiB free.

## 4. Artifact hashes (SHA-256, r1 = r2 for every artifact)

Full per-run lists: `sha256sums-kyber-r1.txt`, `sha256sums-kyber-r2.txt`,
`sha256sums-dilithium-r1.txt`, `sha256sums-dilithium-r2.txt`, combined in `sha256sums.txt`.
`diff` of r1 vs r2 is empty for both repos.

### kyber — 16 artifacts, identical in both runs
| Artifact | SHA-256 |
|---|---|
| `ref/lib/libpqcrystals_fips202_ref.so` | `509b98e21095f0b13eb2a1185baca86b5879ef0a5c271e5c335d5b3afa43cffe` |
| `ref/lib/libpqcrystals_kyber512_ref.so` | `ff6764f76d4da97829ef9a4ee901f53f129238f396624d48c964dfb23247775a` |
| `ref/lib/libpqcrystals_kyber768_ref.so` | `cda2d8798eba2037f505d9091e0805859fe6bbc2db4b25350f73b6760141335e` |
| `ref/lib/libpqcrystals_kyber1024_ref.so` | `cb2898fddd52542694d6d6e8e3618255413aa16dc1aafee8e1b5b73cccc47233` |
| `ref/nistkat/PQCgenKAT_kem512` | `83a59e1b83000ea8e194424561ac0a606f9a08807d9b128e2bf15ffc9594a2bf` |
| `ref/nistkat/PQCgenKAT_kem768` | `7f41a1f2fbad065a6a5e729305d3f4fade1b50473a1389ebda231b4935c7fead` |
| `ref/nistkat/PQCgenKAT_kem1024` | `cb0b81c4d0415382f9a3c9db955a762ab5f56da754e9328f5dc7f592ca389266` |
| `ref/test/test_kyber512` | `0dddaf013fe872b87544e32a14669c04130c6077d8ca9d9d94d775fb4a28cfad` |
| `ref/test/test_kyber768` | `849cf0d4cc627ba65195225f49276cfdf886c9096e8393a174146c81a07f58c0` |
| `ref/test/test_kyber1024` | `44967fda91f5eaaabbe8b269a136151d4a18822762471e99836b1667c7c8677f` |
| `ref/test/test_speed512` | `799d15571553454e6ea85e40d186bdbbe45d5303decc8ed525bd217eb288f049` |
| `ref/test/test_speed768` | `b944300aa83a213291ed777b8e4de80bda0ca0d1776f52628e2a9dac396dc9aa` |
| `ref/test/test_speed1024` | `0bb59010a9e34ba6bf77b06023de33d2225afae4049bf3bc7fde0ff4aef32e0f` |
| `ref/test/test_vectors512` | `dd91f6941cedb2c3ae69235f3395556298c2c9b980b81f0590b7dfb71582bab4` |
| `ref/test/test_vectors768` | `2cc4e762f0f186296108bc3276fb45676004b74d2ef5a307bf07ae303b97500c` |
| `ref/test/test_vectors1024` | `ebc681971e482688691c884ec80f8f838c7b1fc1c5655922967daa7765b2779f` |

### dilithium — 16 artifacts, identical in both runs (after §5 remediation)
| Artifact | SHA-256 |
|---|---|
| `ref/libpqcrystals_dilithium2_ref.so` | `7920c3ae8ed9a3a5e3511ad4faea82cf830b712346a7c3fceb6c52b6f80aa540` |
| `ref/libpqcrystals_dilithium3_ref.so` | `29d80601a191f3134154f3cc7315bad4b892c271cedf1a55365fe08b59214396` |
| `ref/libpqcrystals_dilithium5_ref.so` | `f895099171d7d7090e8f8aee271e017d9c55614bab2de07dfe72129665e45183` |
| `ref/libpqcrystals_fips202_ref.so` | `78e0d0dae7815fe8d58f288cf5ba7173391ea9b52c17378cf02f38c8097aed9c` |
| `ref/nistkat/PQCgenKAT_sign2` | `6827d2f6861ff6fbe7e9176f5db2a264ec35095749dd294d66da6c0d47684f38` |
| `ref/nistkat/PQCgenKAT_sign3` | `c409ebf0027edd2af664729f8c55d4c9bb6f258540dabab917d95bb11a8948f4` |
| `ref/nistkat/PQCgenKAT_sign5` | `8993d672d42f23afad18694189643ca13ec0b022479b06c5dd5b8e67fa87a45e` |
| `ref/test/test_dilithium2` | `e1187499d2fd9d157d92ed8e9b07ebddd2e3c0ec74c5f908d23499f13543e287` |
| `ref/test/test_dilithium3` | `a36e2675e51d915a9076d225aded064ef195481dc496df4b7c7161bc998486a2` |
| `ref/test/test_dilithium5` | `3ab58fd9335a923e5188ff0b450d0f0ab0e5ae6627192d1104d7f1dc122e5c69` |
| `ref/test/test_mul` | `ed92e5626510e74a12cb18e161475f5648e74dbad977bd0d9518256ad3659ae5` |
| `ref/test/test_speed2` | `07260916621ae3df34ac8ac5a967075cff3c32cc2e212df6f5c0904718be4dff` |
| `ref/test/test_speed3` | `b6219f607d9b6af667e37a4be1f5dcead7072a4e58ea01f70bee9ff5eac20e9f` |
| `ref/test/test_speed5` | `5d0085710e82f08235fc82a2d413c2643a267b501e21e3dd553641df4e8b3a58` |
| `ref/test/test_vectors2` | `35f83136fb0b86009de2fbf1a902b0a51832424b915d08ba1f69dd936a22335a` |
| `ref/test/test_vectors3` | `dd1c2a747618c0b32c4ec9f192dad5d1ed9ed213d65c472aad2572d3c1b8eff7` |
| `ref/test/test_vectors5` | `b30e10b684e41b2c1c5e60fa2256055768ec0e6e5648abe088ff276e76b1c47f` |

## 5. Incidents (recorded, not hidden) and remediation

**Incident A — dilithium r1 nistkat build failed on disk space (environment, not the code).**
During dilithium r1, `make speed shared nistkat` failed compiling `nistkat/PQCgenKAT_sign3`:
`fatal error: error writing to /tmp/ccSpvYKy.s: No space left on device`, make exit 2.
Cause: `/tmp` is a 512 MiB tmpfs shared with other tasks on this VM (70% full at the time from
other tasks' files — a 276 MiB Go verification dir and a 68 MiB Go tarball, not mine).
The main `make` (test binaries) had already succeeded (exit 0), so r1 was only missing
`PQCgenKAT_sign3`/`sign5`. Remediation (log `logs/dilithium-r1-nistkat-rebuild.log`):
re-ran `make nistkat` in `dilithium-r1/ref` with `TMPDIR` pointed at a workspace directory
(7.0 GiB free); exit 0. The rebuilt binaries hash-identically to r2's
(`sign3 c409ebf0…`, `sign5 8993d672…`). No other task's files were touched or deleted.

**Incident B — first test runs lost stdout to the same full /tmp (evidence gap, fixed by re-run).**
The first test pass (`src/test.sh`, logs `logs/*-test.log`) redirected program stdout to
`/tmp`. While it ran, `/tmp` filled to 100%: kyber `test_vectors` output alone is
~67–129 MB per parameter set (10,000 deterministic vectors) and dilithium `test_vectors`
output is ~0.85–2.25 GB per set. Several captured outputs were truncated or 0 bytes
(e.g. all kyber-r2 captures empty) even though every program exited 0 — these programs do
not check `printf` errors, so exit 0 alone did not prove the output was captured.
Nothing was re-run to "fix" a failure: the binaries themselves were fine (a direct rerun of
`kyber-r2/ref/test/test_kyber512` printed correctly), only the *capture* was lost.
Remediation: deleted only my own stale `/tmp` captures, then re-ran **all** test binaries
with stdout captured to the workspace (`src/retest.sh`, logs `logs/*-retest.log`).
Bulky raw captures were hashed and then deleted; head/tail excerpts + sha256 + line/byte
counts are in the retest logs. The first-run logs are kept as-is for the record; the retest
logs are the authoritative test evidence. The KAT `.rsp` files were never affected (written
to the workspace, not `/tmp`) and match across runs (see §6).

## 6. Test outcomes (clean re-run, authoritative)

All 24 test-binary runs (6 per repo per checkout) exited 0, with empty stderr.
`test_speed*` and `test_mul` were built but **not executed** (benchmarks, not pass/fail tests).

### kyber (retest 2026-11-07 17:35 UTC)
- `test_kyber512/768/1024`: exit 0; print the expected size lines
  (512: sk 1632 / pk 800 / ct 768; 768: 2400 / 1184 / 1088; 1024: 3168 / 1568 / 1568)
  after 100 keygen/encaps/decaps iterations each. Stdout sha256 identical r1 vs r2:
  512 `880e1fe9…`, 768 `2b32e7f5…`, 1024 `87da552c…`.
- `test_vectors512/768/1024`: exit 0; 60,000 lines each (10,000 deterministic vectors;
  `test_vectors.c` uses a fixed-seed deterministic `randombytes`, so output must match).
  Stdout sha256 identical r1 vs r2: 512 `4d349942…`, 768 `b59ac4d2…`, 1024 `3f577090…`.
- KAT: `PQCgenKAT_kem512` exit 0 in both runs, produced `PQCkemKAT_1632.rsp` (660,402 bytes),
  sha256 `a30184edee53b3b009356e1e31d7f9e93ce82550e3c622d7192e387b0cc84f2e` — identical
  in r1 and r2, including identical first vectors (count 0 seed `06155023…`, same pk/sk/ct/ss).

### dilithium (retest 2026-11-07 17:35–17:47 UTC)
- `test_dilithium2/3/5`: exit 0; 10,000 keygen/sign/verify iterations each plus tampered-
  signature rejection checks (any failure would print to stderr and return -1).
  Final size lines: mode 2 pk 1312 / sk 2560 / sig 2420; mode 3 pk 1952 / sk 4032 / sig 3309;
  mode 5 pk 2592 / sk 4896 / sig 4627. Stdout sha256 identical r1 vs r2:
  2 `79a138b7…`, 3 `4c3edf32…`, 5 `87ef2718…`.
- `test_vectors2/3/5`: exit 0; deterministic vectors (fixed-seed `randombytes` in
  `test_vectors.c`). Line counts 360,000 / 480,000 / 620,000; sizes ~0.85 / 1.38 / 2.25 GB.
  Stdout sha256 identical r1 vs r2: 2 `5f0d135c…`, 3 `14bf8491…`, 5 `759a3ba3…`.
- KAT: `PQCgenKAT_sign2` exit 0 in both runs, produced `PQCsignKAT_Dilithium2.rsp`
  (1,941,571 bytes), sha256 `1d29c3b4ec68e3455f87f49b3386a2a6fc5e167c76e476c4770317ffbb97d242` —
  identical in r1 and r2, including identical count-0 seed/msg/pk/sk/signature.

## 7. Traceability / packaging gap (researched)

- **No distributed binaries or packages of these reference implementations exist from the
  project itself**: zero GitHub releases (both repos), no release artifacts, no published
  checksums, no install target in either Makefile (only test/bench/shared-lib/KAT outputs).
- Repology has **no project entry** for `pq-crystals-kyber` (API returns `[]`); i.e. no
  distro tracks the reference repo itself. (A Debian package search returned no parseable
  result — recorded as inconclusive, not as evidence either way.)
- What *does* exist downstream is **vendored copies inside other projects**, not the reference
  repo as a package:
  - liboqs (Open Quantum Safe) used to vendor `pq-crystals/kyber@441c051` (an older commit)
    and Dilithium Round-3 code; liboqs 0.15.0 **removed** Dilithium and notes 0.12.0 was the
    last release to include Kyber Round 3, directing users to ML-KEM (FIPS 203) instead.
    liboqs is packaged in some distros (e.g. openSUSE `liboqs9` 0.15.0), but that ships
    liboqs's own build of (now-removed) vendored code, not pq-crystals binaries.
  - Language ports exist (e.g. Rust `safe_pqc_kyber`, JS `@noble/post-quantum`, Dart
    `pqcrypto`), but they are independent re-implementations/ports, not distributions of
    this C reference code.
- **The gap, stated plainly**: a verifier cannot download an official pq-crystals Kyber or
  Dilithium binary/package and check a signature or checksum. Trust must rest on (a) the
  pinned commit hash, (b) independent rebuild reproducibility — demonstrated here on one
  machine/toolchain — and (c) the deterministic KAT vectors, which are part of the repo.
  The upstream README's own maintenance notice for kyber (recommending mlkem-native for
  production use) reinforces that this code is a research reference, not a distributed product.

## 8. Limitations

- Single machine, single toolchain (gcc 13.3.0, x86_64, Ubuntu 24.04). Reproducibility on
  other compilers/architectures was not tested.
- Only `ref/` was built; the `avx2/` implementations were not built or verified.
- `test_speed*`/`test_mul` were built but not run (benchmarks, no pass/fail criterion).
- KAT verification here is self-consistency (r1 output == r2 output, deterministic vectors),
  not a comparison against NIST-published KAT files.
- No upstream-published hashes exist to cross-check against (see §7) — "deterministic"
  means "two independent clean rebuilds agree", not "matches a vendor checksum".
- Build logs record compiler invocations verbatim; the `tee`'d logs are unedited.
- The first test pass's stdout capture was lost to the full `/tmp` (Incident B); the retest
  logs supersede it for test evidence, and the first logs are retained for transparency.

## 9. File inventory (this directory)

- `RESULT.md` — this file.
- `sha256sums.txt` — combined artifact hashes (all four runs).
- `sha256sums-kyber-r1.txt`, `sha256sums-kyber-r2.txt`, `sha256sums-dilithium-r1.txt`,
  `sha256sums-dilithium-r2.txt` — per-run artifact hashes.
- `src/build.sh`, `src/hash.sh`, `src/test.sh`, `src/retest.sh` — scripts used.
- `logs/kyber-r1-build.log`, `logs/kyber-r2-build.log`, `logs/dilithium-r1-build.log`,
  `logs/dilithium-r2-build.log` — unedited build logs.
- `logs/dilithium-r1-nistkat-rebuild.log` — remediation build log (Incident A).
- `logs/kyber-r1-test.log`, `logs/kyber-r2-test.log`, `logs/dilithium-r1-test.log`,
  `logs/dilithium-r2-test.log` — first test pass (partial stdout loss, see Incident B).
- `logs/kyber-r1-retest.log`, `logs/kyber-r2-retest.log`, `logs/dilithium-r1-retest.log`,
  `logs/dilithium-r2-retest.log` — authoritative clean test re-run.
- `kyber-r1/`, `kyber-r2/`, `dilithium-r1/`, `dilithium-r2/` — fresh clones at the pinned
  commits, with built artifacts and KAT `.rsp` files in `ref/`.
- `testout-kyber-r1/`, `testout-kyber-r2/`, `testout-dilithium-r1/`, `testout-dilithium-r2/` —
  retained small stdout/stderr captures (3-line self-test outputs); bulky `test_vectors`
  captures were hashed and deleted (hashes + head/tail in the retest logs).
- No secrets or keys are included anywhere in this directory.
