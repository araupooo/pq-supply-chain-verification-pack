# liboqs — build verification result

Target directory: `~/workspace/goals/postfiat-task-node-connection/hidden_files/task-c0496161/targets/liboqs/`
Work performed: 2026-11-07 (UTC times below; local WIB = UTC+7).

## Pinned version

| Item | Value |
|---|---|
| Project | liboqs (open-quantum-safe/liboqs), C library for quantum-resistant cryptography, MIT licence |
| Release | **0.16.0** ("liboqs version 0.16.0"), latest published release at time of check |
| Release date | 2026-07-09 (published 2026-07-09T14:58:32Z) |
| Tag commit | `5a1a854b0dc9f2141bdc771c555ee60c37950183` (refs/tags/0.16.0, verified by `git ls-remote` and by `git rev-parse HEAD` in both clones — both logs record `HEAD: 5a1a854b0dc9f2141bdc771c555ee60c37950183`) |
| Release URL | https://github.com/open-quantum-safe/liboqs/releases/tag/0.16.0 |
| Source tarball | https://github.com/open-quantum-safe/liboqs/archive/refs/tags/0.16.0.tar.gz |
| Sources checked | GitHub Releases API (`releases/latest`, saved as `releases_latest.json`), release page (fetched 2026-11-07), `RELEASE.md` at tag 0.16.0 (saved as `RELEASE-0.16.0.md`), https://openquantumsafe.org/liboqs/ (lists 0.16.0, 9 July 2026, as current) |

## Build commands (both builds, identical except workdir)

Script: `src/build.sh` (builds are driven by it; see file for the exact commands).

- `git clone --depth 1 --branch 0.16.0 https://github.com/open-quantum-safe/liboqs.git <workdir>/liboqs`
- `mkdir build && cd build`
- `cmake -DCMAKE_BUILD_TYPE=Release ..` (Unix Makefiles generator; ninja is NOT installed on this machine, so the upstream default `cmake -GNinja` could not be used — see Limitations)
- `cmake --build . -- -j4`
- Artifact: `build/lib/liboqs.a` (static, the upstream default; `BUILD_SHARED_LIBS` left at its default OFF)

Build 1 dir: `build1/` ; build 2 dir: `build2/` (two separate fresh clones in two separate directories).

### First attempt — FAILED on environment, not on the source

Started ~16:51 UTC, both builds failed at ~50% (~17:03 UTC) with
`fatal error: error writing to /tmp/ccXXXXXX.s: No space left on device`.
Cause: `/tmp` on this machine is a 512 MB tmpfs, already ~78% full with other
scratch (go-build cache, kyber test-vector files) before my builds started;
8 concurrent gcc processes exhausted it. Logs preserved unedited as
`build1-failed-diskfull.log` / `build2-failed-diskfull.log`. Partial trees were
deleted. Fix: re-ran with `TMPDIR` pointed at per-build directories on the
127 GB workspace disk (`tmp1/`, `tmp2/`); nothing else changed. No source,
toolchain, or flag change was involved in the retry.

### Second attempt — SUCCESS

Started ~17:08 UTC, both builds finished 2026-11-07T17:41:11Z. 0 warnings in
either log (2989 lines each). `lib/liboqs.a` = 38,720,354 bytes in both builds.

## SHA-256 hashes (primary result)

| Artifact | SHA-256 |
|---|---|
| build1 `lib/liboqs.a` | `1fdf54c7e56434c7c360593a81686de79f105a4ac213446710556298922e6114` |
| build2 `lib/liboqs.a` | `fbd5dc65047d46d0d91c79da119a9665db6946e8fa7fc1f5a2c2a05ca4232d56` |
| build1 `lib/liboqs-internal.a` | `0f416898c64f9081932fc1b722d08d5593e57739fd8361187f0b301ec1915962` |
| build2 `lib/liboqs-internal.a` | `65d0af0d6d276bee818321cd499967e0df07861d33e85701ddc843d651f52868` |
| Source tarball `liboqs-0.16.0.tar.gz` | `162d5b510518ee5f285f82fa1f16402a885176e818bf1b1a4c3c91c9a2f01eae` |

Also in `sha256sums.txt`.

## Deterministic? NO (as built with upstream defaults) — with a proven one-line fix

**Verdict: NO.** The two clean Release builds produce different `liboqs.a`
hashes, same size (38,720,354 bytes), same 2,634 object members in the same
order, deterministic `ar` headers (all member timestamps epoch 0, GNU ar 2.42
deterministic mode).

### Root-cause investigation

1. Member-by-member comparison of the archives (parsed the `ar` format
   positionally, by resolved long name — basenames repeat: e.g. nine members
   are named `common.c.o`) shows **exactly one differing member**:
   `src/common/common.c.o` (8,816 bytes), the object of `src/common/common.c`.
   All other 2,633 members are byte-identical, as are all 2,678 `.o` files in
   the build trees except that same one (verified against the trees directly,
   not just the archives).
2. The only difference inside that object is one string — the absolute source
   path of the compilation unit, as passed on the compiler command line:
   - build1: `.../targets/liboqs/build1/liboqs/src/common/common.c`
   - build2: `.../targets/liboqs/build2/liboqs/src/common/common.c`
   This is GCC's `STT_FILE` symbol (the input filename as given; CMake passes
   absolute paths). No `__FILE__` use in the source, no `__DATE__`/`__TIME__`,
   no debug info (`-O3 -DNDEBUG`, no `-g`), no timestamps in the archive.
   `liboqs-internal.a` differs for the same reason (its only differing member
   is also `common.c.o`, from the `internal` target).
3. Two flawed intermediate re-archive attempts are preserved in the record and
   must not be mistaken for the result: `rearchive_hashes.txt` (plain `ar r`
   replaced the *first* same-named member — a Falcon `common.c.o` — not the
   src/common one) and `rearchive_fixed_hashes.txt` (byte-surgery at an
   off-by-one index caused by the `//` long-name table member). Both are
   documented here so the final step below is auditable.

### Determinism measure tried and its effect

`-ffile-prefix-map=<build-dir>/src=/liboqs` (added to the `common.c`
compile command only, in both trees; script `src/fix_experiment.sh`, log
`fix_experiment.log`):

- Both recompiled `common.c.o` become **byte-identical**:
  `862b2aac3b28887a4ccd01f5ced7c429d649f014bf6f84e48b1f9663b5965c7e`,
  embedded path now `/liboqs/common/common.c` in both.
- Re-archiving each original `liboqs.a` with only that member replaced by the
  fixed object (byte surgery + `ranlib` to regenerate the index) yields
  **byte-identical libraries**:
  `9349b6d5d2301c3868ede55b58d5863c58f8a28c95f26febc38dd583de16849b`
  for both (hashes in `rearchive_fixed2_hashes.txt`; the re-archived library
  is saved as `liboqs-fixed-prefix-map.a`).
- Conclusion: the sole nondeterminism source is the absolute build path in
  one object file, and the standard `-ffile-prefix-map` compiler flag removes
  it. This was demonstrated at object level plus re-archive, **not** by a
  third pair of full clean rebuilds (a full pair costs ~35 min on this
  4-core machine; the evidence above isolates the single differing member,
  so a full re-run would only re-prove the same point). Upstream documents no
  reproducible-build support: no mention of `SOURCE_DATE_EPOCH`,
  `-ffile-prefix-map`, or reproducibility in `CMakeLists.txt`, `CONFIGURE.md`,
  or `README.md` at 0.16.0 (grep, 2026-11-07), and no SBOM is generated
  (only `tests/test_spdx.sh` exists). `SOURCE_DATE_EPOCH` was therefore not
  needed and not tried — there is no timestamp anywhere in the output to
  normalise (archive timestamps are already epoch 0). `BUILD_SHARED_LIBS`
  was left at the upstream default (static `.a`); a shared-library build was
  not attempted.

## Environment

- Host: `Linux htch-runtime 7.0.0-43-generic x86_64` (Ubuntu 24.04-based VM);
  CPU AMD EPYC 9D25, 4 vCPUs visible (`nproc` = 4)
- gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), cmake 3.28.3, git 2.43.0,
  GNU ar/ranlib 2.42, python3 3.12.3, OpenSSL 3.0.13 (headers present,
  `/usr/include/openssl/opensslv.h`); ninja NOT installed (upstream docs use
  Ninja; Makefiles used instead); Doxygen NOT installed (doc generation
  skipped, `Could NOT find Doxygen` in both logs — does not affect the library)
- Relevant env: `SOURCE_DATE_EPOCH` unset; `CFLAGS`/`CXXFLAGS` unset;
  `TMPDIR` set per build to workspace dirs (`tmp1/`, `tmp2/`) for the
  successful attempt (see above); `LANG`/`LC_*` not set in the build env
- Build time: ~33 min per build running two in parallel on 4 cores
  (17:08 → 17:41 UTC)

## Traceability findings (release 0.16.0)

| Distributed artifact / claim | Finding |
|---|---|
| GitHub release assets | **None.** The release has an empty assets list (GitHub Releases API, 2026-11-07) and no Assets section on the release page. Upstream publishes no binary, no `.tar.gz` asset beyond the auto-generated codeload tarball, no `.sig`/`.asc`, no `SHA256SUMS`, no SLSA/Sigstore attestation on the release. |
| GitHub artifact attestations | **UNVERIFIED — could not establish.** The attestations API call was rate-limited (unauthenticated GitHub API limit) and the release page shows no attestation. Not claimed as absent, not claimed as present. |
| Signed git tag | **UNVERIFIED.** `git ls-remote` shows tag `0.16.0` → `5a1a854b…` directly (lightweight tag object, not an annotated tag object); no signature was retrieved or checked. |
| Source tarball hash, independently verified | **VERIFIED.** Downloaded codeload tarball SHA-256 = `162d5b51…f01eae`, exactly matching the checksum Homebrew publishes for the same URL in its formula (`formulae.brew.sh/api/formula/liboqs.json`, `urls.stable.checksum`). This is a third-party checksum of the same upstream URL, not an upstream-published hash. |
| Homebrew (macOS/Linux) | Formula `liboqs` 0.16.0 exists (Repology: newest; formula JSON 200). Source URL is the GitHub tag tarball with the checksum above; prebuilt bottles published on GHCR, e.g. `x86_64_linux` bottle SHA-256 `85a55828104442d9fb8f162d3d94f2e1e04e7c723b640abcd2d18f58a3bb68ce` (URL `https://ghcr.io/v2/homebrew/core/liboqs/blobs/sha256:85a5…`). Bottle contents were **not** downloaded or compared to my build (different platform/toolchain; not attempted). |
| Distro packages (0.16.0) | openSUSE Tumbleweed 0.16.0, FreeBSD `security/liboqs` 0.16.0, MacPorts `devel/liboqs` 0.16.0, AUR 0.16.0, MSYS2 `mingw-w64-liboqs` 0.16.0 (Repology API, 2026-11-07). Fedora 43/44, Nix, vcpkg, OpenMandriva still on older versions (0.12.0–0.15.0). Debian: a tracker page exists (`tracker.debian.org/pkg/liboqs`) but the 0.16.0 status in Debian could not be established from the sources checked — **UNVERIFIED**. No distro package hash was verified against my build. |
| Container images | **No liboqs release image found.** Docker Hub `openquantumsafe` org lists CI images only (`ci-ubuntu-bionic-*`, `ci-debian-buster-*`, `curl`, …) — old CI images, not a 0.16.0 release image. |
| Third-party prebuilt binaries | `bardiakz/liboqs-binaries` on GitHub ships `liboqs-0.16.0-all-platforms.tar.gz` (referenced by the Dart `oqs` package docs). **Not upstream, not verified, not endorsed** — listed only because a consumer could mistake it for an official artifact. |
| Related (not liboqs itself) | `liboqs-python` 0.16.0.2 on PyPI (2026-10-28) shows a "With provenance" label on the PyPI web page, but the PyPI JSON API returned `attestations: false` for both its files in my check — ambiguous, **UNVERIFIED**, and in any case it is the Python wrapper (which downloads/builds liboqs at install time; it does not bundle a compiled liboqs). |
| Upstream supply-chain automation | `.github/workflows/release.yml` only runs release tests (no artifact publishing/signing). `.github/workflows/supplychain.yml` runs OSSF Scorecard/poutine scanning and uploads SARIF to code scanning — detection only, no signing, no SBOM, no provenance. |

### Highest-severity traceability gap

**Upstream publishes no verifiable artifact for the release at all: no signed
release, no published hash, no attestation, no binary — the only thing a
downloader can check is the git tag/commit, and the tag itself is lightweight
(unsigned).** A consumer fetching 0.16.0 has no upstream-issued integrity
value to compare against; the only independently checkable hash is the one
Homebrew republishes for the same tarball URL (verified above), and the
distro packages are all third-party rebuilds whose hashes were not compared
to this build. Any supply-chain claim for a liboqs 0.16.0 binary therefore
rests on the distributor, not on upstream.

## Limitations

- Ninja (upstream's documented generator) is not installed; Unix Makefiles
  were used instead. The build graph is the same CMake project, but a
  Ninja-based rebuild could in principle differ (not expected to change the
  path-embedding finding).
- Only the default static library (`liboqs.a`) was compared. A shared
  (`-DBUILD_SHARED_LIBS=ON`) build was not run, and the test suite
  (`ninja run_tests` / `ctest`) was not executed — the built test programs
  exist in the build trees but were not run.
- The `-ffile-prefix-map` fix was demonstrated at object + re-archive level,
  not by a third pair of full clean rebuilds (see above).
- GitHub API rate limit (unauthenticated) blocked the attestations endpoint
  and one tag-ref lookup during this session; tag/commit were instead pinned
  via `git ls-remote` and the clones themselves.
- Only x86_64 Linux was built; no macOS/Windows/ARM verification.
- The two builds ran concurrently on the same 4-core host, sharing CPU; build
  times are wall-clock under contention, not single-build timings.

## Files in this directory

- `RESULT.md` — this file
- `build1.log`, `build2.log` — unedited full logs of the successful builds
- `build1-failed-diskfull.log`, `build2-failed-diskfull.log` — unedited logs
  of the first attempt (failed on /tmp exhaustion; kept as evidence)
- `sha256sums.txt` — all hashes above
- `releases_latest.json` — GitHub Releases API response for 0.16.0
- `RELEASE-0.16.0.md` — release notes at tag 0.16.0
- `liboqs-0.16.0.tar.gz`, `tarball.sha256` — downloaded source tarball + hash
- `liboqs-fixed-prefix-map.a` — re-archived `liboqs.a` with the fixed
  `common.c.o` (SHA-256 `9349b6d5…`, identical for both builds)
- `fix_experiment.log`, `rearchive_hashes.txt`,
  `rearchive_fixed_hashes.txt`, `rearchive_fixed2_hashes.txt` — fix
  experiment log and the re-archive hash records (including the two flawed
  intermediate attempts, see Root-cause investigation §3)
- `src/build.sh` — build script used for both builds
- `src/fix_experiment.sh` — the `-ffile-prefix-map` remediation experiment
- `build1/`, `build2/` — the two full build trees (source + build outputs)
- `tmp1/`, `tmp2/` — empty per-build `TMPDIR` dirs (kept; gcc temp files
  were transient)
