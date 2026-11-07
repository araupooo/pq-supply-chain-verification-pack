# RESULT — Go standard library crypto/mlkem and crypto/mldsa

Target: Go standard library `crypto/mlkem` (ML-KEM-768) and `crypto/mldsa` (ML-DSA-65).
Work directory: `~/workspace/goals/postfiat-task-node-connection/hidden_files/task-c0496161/targets/go-stdlib/`
Date of work: 2026-11-07 (builds 16:52–16:54 UTC / 23:52–23:54 WIB; stdlib rebuilds 16:54–~17:02 UTC).
Author: build-verification worker (subagent). No secrets, keys, or key material are
included anywhere in this pack; the test program prints sizes and booleans only.

## Verdict

- **Deterministic: YES.** Two independent clean builds of the fixed test program
  produced byte-identical binaries (SHA-256 identical, `cmp` clean).
- **Test program runtime: PASS on both builds.** ML-KEM-768 keygen/encapsulate/
  decapsulate (shared keys match) and ML-DSA-65 keygen/sign/verify (tampered
  message rejected) all succeed; all sizes match the FIPS 203 / FIPS 204
  parameter-set sizes.
- **Toolchain checksum: VERIFIED.** The downloaded go1.27.3 linux/amd64 tarball
  matches the published SHA-256, and the installed tree is byte-identical to
  the extracted verified tarball (`diff -r` exit 0).
- **Stdlib rebuild (`go build -a std`): reproducible in content.** 2,618 of
  2,619 cache entries byte-identical after normalizing embedded cache write
  timestamps; the sole exception is `trim.txt`, a bare cache-trim timestamp,
  not a compiled artifact.
- **Toolchain PGP signature: UNVERIFIED** — the `.asc` file was fetched, but no
  trusted copy of the Go release public key could be obtained in this
  environment (keyserver fetches failed); see Traceability.

## 1. Go version pinned

- `go version go1.27.3 linux/amd64` (installed toolchain at `/usr/local/go/bin/go`)
- `GOROOT=/usr/local/go`; `/usr/local/go/VERSION` contains `go1.27.3` /
  `time 2026-10-19T22:20:36Z`
- `GOOS=linux`, `GOARCH=amd64`, `GOAMD64=v1`
- Host: `Linux htch-runtime 7.0.0-43-generic #1 SMP PREEMPT_DYNAMIC Fri Oct 23 11:56:57 UTC 2026 x86_64`
- Tools present (no system-wide installs made): gcc 13.3.0, git 2.43.0, python3 3.12.3

## 2. Research first — primary sources only

All pages fetched 2026-11-07 ~16:50–16:51 UTC with curl; raw copies kept in `research/`.

| Source | URL | What it establishes |
|---|---|---|
| Go 1.27 release notes | https://go.dev/doc/go1.27 | `crypto/mldsa` is **new in Go 1.27**: "implements the post-quantum ML-DSA signature scheme specified in FIPS 204"; `crypto/x509` and `crypto/tls` now support ML-DSA (MLDSA44/65/87). ML-KEM-1024 key exchange now supported in TLS. |
| crypto/mlkem package docs | https://pkg.go.dev/crypto/mlkem | Version go1.27.3, published Oct 20, 2026, BSD-3-Clause. "Package mlkem implements the quantum-resistant key encapsulation method ML-KEM (formerly known as Kyber), as specified in NIST FIPS 203." "Most applications should use the ML-KEM-768 parameter set." API used: `GenerateKey768()`, `NewEncapsulationKey768()`, `Encapsulate()`, `Decapsulate()`. |
| crypto/mldsa package docs | https://pkg.go.dev/crypto/mldsa | Version go1.27.3, published Oct 20, 2026, BSD-3-Clause. "Package mldsa implements the post-quantum ML-DSA signature scheme specified in FIPS 204." API used: `GenerateKey(MLDSA65())`, `NewPublicKey()`, `Sign()`, `Verify()`, `Parameters.PublicKeySize()` / `SignatureSize()`. |
| Go downloads (JSON index) | https://go.dev/dl/?mode=json | go1.27.3, stable, `go1.27.3.linux-amd64.tar.gz`: SHA-256 `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40`, size 70588678. Also `go1.27.3.src.tar.gz` SHA-256 `6e7749035cf360f06b2575d162ea79df9fda8ef671889e5c375f8e50777f26bb`. |
| Go downloads page | https://go.dev/dl/ | Fetched (3,152,911 bytes) as the human-readable listing behind the JSON index. |
| Published checksum file | https://dl.google.com/go/go1.27.3.linux-amd64.tar.gz.sha256 | Contains exactly `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40` (64 bytes) — agrees with the JSON index. Note: the same filename under `https://go.dev/dl/` returns an HTML redirect page, not the checksum, so the dl.google.com copy and the JSON index are the usable sources. |
| Detached signature | https://go.dev/dl/go1.27.3.linux-amd64.tar.gz.asc | Fetched, 833 bytes, valid PGP signature packet (see §5). |

Local stdlib source confirms the docs: `/usr/local/go/src/crypto/mlkem/mlkem.go`
("as specified in [NIST FIPS 203]", https://doi.org/10.6028/NIST.FIPS.203) and
`/usr/local/go/src/crypto/mldsa/mldsa.go` (FIPS 204). Constants used:
`SharedKeySize=32`, `EncapsulationKeySize768=1184`, `CiphertextSize768=1088`;
ML-DSA-65 `PublicKeySize()=1952`, `SignatureSize()=3309`.

## 3. Rebuild definition (explicit)

The Go standard library ships with the toolchain, so there is no upstream
source tarball to "rebuild" in the usual sense. For this target, **"rebuild"
means**:

1. **Primary check (this verdict):** build a FIXED test program that imports
   `crypto/mlkem` (ML-KEM-768) and `crypto/mldsa` (ML-DSA-65) — generate a
   keypair, encapsulate/decapsulate, sign/verify, print key/ciphertext/
   signature sizes — TWICE from clean state (separate build directories,
   separate GOCACHE/GOMODCACHE/GOPATH, `-trimpath`, `CGO_ENABLED=0`), and
   compare the SHA-256 of the two produced binaries. The program source is
   fixed and identical in both builds (verified by SHA-256 before building).
2. **Additional check:** rebuild the stdlib packages themselves with
   `go build -a std` in a clean GOCACHE, twice, and compare the resulting
   build-cache manifests (sorted relative path + SHA-256 per file). See §6.

## 4. The two independent clean builds

Test program: `src/main.go` (SHA-256 `9d5ee30bb00204f62a32da902487cc72521ecd6478b451bb45a3963805234cd0`),
`src/go.mod` (`module pqcheck`, `go 1.27`; SHA-256
`12178a05283d57a41286c2bafd062e2fd124cd8f9be9b2f94002e41f2cb2d5fb`).
Byte-identical copies were placed in `build1/` and `build2/` (verified with
`sha256sum`/`cmp` before building). No third-party dependencies: stdlib only,
`GOPROXY=off`, `GOSUMDB=off`.

Build command (identical for both; `$B` = `build1` / `build2`), run by
`run_build.sh`, unedited logs in `build1.log` / `build2.log`:

```
cd $B && env CGO_ENABLED=0 GOFLAGS='-trimpath -buildvcs=false' GOPROXY=off \
  GOSUMDB=off GOTOOLCHAIN=local GOCACHE=$PWD/gocache \
  GOMODCACHE=$PWD/gomodcache GOPATH=$PWD/gopath \
  /usr/local/go/bin/go build -trimpath -buildvcs=false -o pqcheck .
```

Fixed environment per build: `CGO_ENABLED=0`, `GOFLAGS=-trimpath -buildvcs=false`,
`-trimpath -buildvcs=false` also on the command line, `GOPROXY=off`,
`GOSUMDB=off`, `GOTOOLCHAIN=local`, separate `GOCACHE`/`GOMODCACHE`/`GOPATH`
under each build directory. (Note: the `go env` block printed in the build
logs shows the *default* environment because it was run without the build
overrides; the build itself used the variables listed in the log header and
in the command line above.)

| | Build 1 | Build 2 |
|---|---|---|
| Started (UTC) | 2026-11-07 16:52:27 | 2026-11-07 16:53:36 |
| Ended (UTC) | 2026-11-07 16:53:29 | 2026-11-07 16:54:33 |
| Build exit code | 0 | 0 |
| Binary size | 2,968,564 bytes | 2,968,564 bytes |
| SHA-256 | `d81e1efa546db902d66b25fbee72e45827b493b0400a4f80f447ffcb20abab22` | `d81e1efa546db902d66b25fbee72e45827b493b0400a4f80f447ffcb20abab22` |
| `cmp` | byte-identical | byte-identical |

`go version -m` on both binaries (identical): `go1.27.3`, `path pqcheck`,
`mod pqcheck (devel)`, `-buildmode=exe`, `-compiler=gc`, `-trimpath=true`,
`CGO_ENABLED=0`, `GOARCH=amd64`, `GOOS=linux`, `GOAMD64=v1`. No build paths
are embedded (different GOCACHE paths per build did not leak into the binary).

**Deterministic: YES** — same SHA-256 from two independent clean builds; no
hash-massaging was needed or done, and no extra measures (beyond the
already-applied `-trimpath` / `-buildvcs=false` / `CGO_ENABLED=0`) were required.

### Test-program runtime output (both binaries, identical)

Both binaries were run and their full outputs are preserved in `build1.log`
and `build2.log` (run exit code 0 both times). The program prints sizes and
booleans only — key material is random by design and is never printed, so the
outputs are expected to be identical across runs:

```
go-stdlib pqcheck (crypto/mlkem ML-KEM-768, crypto/mldsa ML-DSA-65)
mlkem-768 encapsulation_key_bytes=1184 (const EncapsulationKeySize768=1184)
mlkem-768 decapsulation_key_bytes=64
mlkem-768 shared_key_bytes=32 (const SharedKeySize=32)
mlkem-768 ciphertext_bytes=1088 (const CiphertextSize768=1088)
mlkem-768 decapsulate_ok=true shared_key_match=true
mldsa-65 params=ML-DSA-65 public_key_size=1952 signature_size=3309
mldsa-65 public_key_bytes=1952 private_key_bytes=32
mldsa-65 signature_bytes=3309
mldsa-65 verify_ok=true
mldsa-65 verify_tampered_rejected=true
ALL CHECKS PASSED
```

Size table vs. the FIPS parameter sets:

| Quantity | Observed | Expected (FIPS 203 / FIPS 204) |
|---|---|---|
| ML-KEM-768 encapsulation key | 1184 bytes | 1184 |
| ML-KEM-768 decapsulation key encoding (seed) | 64 bytes | 64 (seed encoding) |
| ML-KEM-768 shared key | 32 bytes | 32 |
| ML-KEM-768 ciphertext | 1088 bytes | 1088 |
| ML-DSA-65 public key | 1952 bytes | 1952 |
| ML-DSA-65 private key encoding (seed) | 32 bytes | 32 (seed encoding) |
| ML-DSA-65 signature | 3309 bytes | 3309 |

## 5. Traceability — toolchain distribution

- **Published SHA-256** (`go1.27.3.linux-amd64.tar.gz`): `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40`
  (from `https://go.dev/dl/?mode=json` and from
  `https://dl.google.com/go/go1.27.3.linux-amd64.tar.gz.sha256` — the two
  sources agree; size 70,588,678 bytes, also matching the JSON index).
- **Downloaded file** (`research/go1.27.3.linux-amd64.tar.gz`, fetched from
  `https://dl.google.com/go/go1.27.3.linux-amd64.tar.gz`, 70,588,678 bytes):
  SHA-256 `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40` —
  `sha256sum -c` **OK**. **Toolchain checksum: VERIFIED.**
- **Installed tree vs. published distribution:** the verified tarball was
  extracted to a scratch directory and compared with `diff -r` against the
  installed `/usr/local/go`: **exit 0, zero differences** (record saved as
  `research/toolchain-vs-installed.diff`, empty). The installed toolchain is
  therefore byte-identical to the published, checksum-verified distribution.
  Its `VERSION` file matches the extracted one (`go1.27.3`, `time 2026-10-19T22:20:36Z`).
- **Detached PGP signature** (`research/go1.27.3.linux-amd64.tar.gz.asc`,
  833 bytes, fetched from `https://go.dev/dl/go1.27.3.linux-amd64.tar.gz.asc`):
  `gpg --list-packets` shows a valid signature packet — signer key ID
  `FD533C07C264648F`, issuer fingerprint
  `0E225917414670F4442C250DFD533C07C264648F`, created 2026-10-20, digest algo
  SHA-256. **Verification: UNVERIFIED** — no trusted copy of the Go release
  public key could be obtained in this environment: `gpg --recv-keys
  FD533C07C264648F` failed against both `hkps://keyserver.ubuntu.com` and
  `hkps://keys.openpgp.org` ("keyserver receive failed: Server indicated a
  failure"), and the key is not present in any local keyring. The signature
  file itself is preserved for later verification. This does not affect the
  checksum result, which rests on two agreeing published sources plus the
  installed-tree diff.

## 6. Stdlib rebuild (`go build -a std`)

Command (identical per run; `run_stdbuild.sh`, unedited logs `stdbuild1.log` /
`stdbuild2.log`), with fresh `GOCACHE`/`GOPATH` per run:

```
env CGO_ENABLED=0 GOFLAGS='-trimpath -buildvcs=false' GOPROXY=off \
  GOSUMDB=off GOTOOLCHAIN=local GOCACHE=$PWD/<label>/gocache \
  GOPATH=$PWD/<label>/gopath /usr/local/go/bin/go build -a std
```

Comparison method: manifest of the whole build cache (sorted relative paths,
SHA-256 per file) — `stdbuild1-cache-manifest.txt`,
`stdbuild2-cache-manifest.txt`. **Important correction to the method:** the raw
manifests differ even for a reproducible build, because Go build-cache `-a`
entries embed the cache-entry write time as a trailing nanosecond timestamp
(e.g. `... 1234  1794070493563167225`). In the comparison against the first
(ENOSPC, incomplete) rebuild-2 attempt, all 1,450 differing files differed
*only* in those last ≤25 bytes; every other byte — including all large compiled
archives (largest 12.6 MB, 162 MB of identical content) — matched. The correct
comparison therefore normalizes that trailing timestamp field; the rerun
comparison below uses that method.

| | Stdlib rebuild 1 | Stdlib rebuild 2 |
|---|---|---|
| Started–ended (UTC) | 2026-11-07 16:54:43 – 16:58:02 | 2026-11-07 17:05:50 – 17:07:25 (rerun; see note) |
| Exit code | 0 | 0 |
| Cache files | 2,619 | 2,619 |
| Raw manifest SHA-256 | `b2bf60e9e052e3b8f0c45e3ca65022a6013ad3b2e3b8c63fc56bcbccab12d820` | `22707dc7b6723ebce9f1c043255db26e2c31a7b4555d6cb0babf96785ba938ce` |
| Raw manifests identical? | No — expected: 1,115 of 2,619 entries raw-identical; the rest differ only in embedded write-mtimes (see above); the normalized comparison is the meaningful one | — |
| Timestamp-normalized cache trees identical? | **YES, in content: 2,618 / 2,619 entries byte-identical.** Sole exception: `./trim.txt` — a bare 10-digit epoch timestamp (`1794070671` vs `1794070982`, i.e. cache trim times 2026-11-07T16:57:51Z vs 17:03:02Z), not a compiled artifact. Full record: `stdlib-normalized-comparison.txt`. | — |

Note on the first rebuild-2 attempt: it FAILED with exit 1 (`no space left on
device`) because `/tmp` is a 512 MB tmpfs and the 276 MB toolchain extraction
(`/tmp/go1273-verify`, used for the §5 diff) was still sitting in it, leaving
only ~158 MB free for the Go build work directory. That failed run is preserved
as `stdbuild2-enospc.log` / `stdbuild2-enospc-cache-manifest.txt` (2,535 files,
incomplete). The extraction was then deleted (its diff result was already saved
in `research/toolchain-vs-installed.diff`), freeing /tmp to 276 MB available,
and rebuild 2 was rerun cleanly (exit 0, 2,619 files). The failed attempt was
environmental (disk space), not a build nondeterminism signal — and its
incomplete cache already showed the same timestamp-only difference pattern on
every completed entry.

Note: the primary `pqcheck` builds already compile `crypto/mlkem`,
`crypto/mldsa` and their dependencies from source in clean caches, and their
binaries matched; this full-stdlib check is additional evidence, not the basis
of the verdict.

## 7. Limitations

- "Rebuild" is defined as in §3: the stdlib ships inside the toolchain, so the
  primary reproducibility evidence is the fixed test program built twice from
  clean state; the `go build -a std` cache comparison is a supporting check.
- PGP signature of the toolchain tarball is UNVERIFIED (no obtainable public
  key in this environment); the checksum verification is independent of it.
- The first `go build -a std` rebuild-2 attempt failed on disk space (`/tmp`
  is a 512 MB tmpfs); the clean rerun succeeded. Both the failed attempt's
  log/manifest and the rerun's are preserved.
- Raw build-cache manifests are NOT a valid byte-equality check for the stdlib
  rebuild: Go cache `-a` entries embed a write timestamp, so the comparison
  must normalize that trailing field (§6). The final linked binaries (the
  primary check) have no such issue — they matched byte-for-byte.
- `go build -a std` writes compiled packages into the build cache only; it
  does not produce installed `.a` files (that would require writing into
  GOROOT, which was not attempted).
- Only linux/amd64 was tested (the installed platform). No other OS/arch was
  checked.
- The test program exercises ML-KEM-768 and ML-DSA-65 only — the parameter
  sets named in the task — not ML-KEM-512/1024 or ML-DSA-44/87.
- Build-cache directories (`build1/gocache`, `build2/gocache`, ~37 MB each;
  `stdbuild1/gocache`, `stdbuild2/gocache`) are retained in the target
  directory for audit; the downloaded 70 MB tarball is retained in `research/`.

## 8. Files in this target directory

```
RESULT.md                      — this file
sha256sums.txt                 — SHA-256 sums (source, both binaries, toolchain tarball); all verify OK
src/main.go                    — fixed test program (ML-KEM-768 + ML-DSA-65)
src/go.mod                     — module pqcheck, go 1.27
run_build.sh                   — script used for both clean builds
run_stdbuild.sh                — script used for both stdlib rebuilds
build1.log / build2.log        — unedited build + run logs (env, hashes, runtime output)
build1/pqcheck                 — binary, SHA-256 d81e1efa…ab22
build2/pqcheck                 — binary, SHA-256 d81e1efa…ab22 (identical)
build1/ / build2/              — build dirs (source copies, gocache, gomodcache, gopath)
stdbuild1.log / stdbuild2.log  — unedited `go build -a std` logs
stdbuild2-enospc.log         — the first rebuild-2 attempt (failed: /tmp full)
stdbuild1-cache-manifest.txt / stdbuild2-cache-manifest.txt — sorted cache manifests
stdbuild2-enospc-cache-manifest.txt — manifest from the failed attempt (2,535 files)
stdlib-normalized-comparison.txt — timestamp-normalized stdlib cache comparison (2,618/2,619 identical; trim.txt only)
stdbuild1/ / stdbuild2/        — stdlib rebuild dirs (gocache, gopath)
research/go1.27-release-notes.html
research/pkg-crypto-mlkem.html
research/pkg-crypto-mldsa.html
research/go-dl.html
research/go-dl.json
research/go1.27.3.linux-amd64.tar.gz.sha256         — HTML redirect page (see §2 note)
research/go1.27.3.linux-amd64.tar.gz.sha256.dlgoogle — published checksum (64 bytes)
research/go1.27.3.linux-amd64.tar.gz.asc            — detached PGP signature
research/go1.27.3.linux-amd64.tar.gz               — downloaded distribution (checksum VERIFIED)
research/toolchain-vs-installed.diff               — empty: installed tree == verified distribution
research/go-release-key-note.txt                   — go.dev/doc/install fetch (key not found on that page)
```
