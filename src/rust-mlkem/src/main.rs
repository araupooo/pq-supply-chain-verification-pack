//! Fixed verification program for the RustCrypto `ml-kem` crate (v0.3.4).
//!
//! ML-KEM-768 (FIPS 203, security category 3):
//!   keygen -> encapsulate -> decapsulate, asserting the two shared
//!   secrets are equal. Prints only sizes and the match result —
//!   never key, ciphertext, or shared-secret material.
//!
//! API as documented in ml-kem 0.3.4 `src/lib.rs` (tag ml-kem/v0.3.4):
//!   `MlKem768::generate_keypair()` (requires the `getrandom` feature),
//!   `ek.encapsulate()` -> `(ct, k_send)`,
//!   `dk.decapsulate(&ct)` -> `k_recv`, `assert_eq!(k_send, k_recv)`.
//!
//! Size notes (verified against ml-kem 0.3.4 `src/decapsulation_key.rs`):
//!   * `DecapsulationKey::to_bytes()` serializes the 64-byte SEED (d || z),
//!     not the expanded key — that is the crate's documented `KeyExport`
//!     behaviour ("Serialize the Seed value: 64-bytes which can be used
//!     to reconstruct the [key]").
//!   * The FIPS 203 expanded decapsulation key (2400 bytes for ML-KEM-768)
//!     is available via the deprecated `ExpandedKeyEncoding::
//!     to_expanded_bytes()`.
//!   * FIPS 203 ML-KEM-768 sizes: ek 1184, dk (expanded) 2400, ct 1088,
//!     shared secret 32.

use ml_kem::{
    ExpandedKeyEncoding, MlKem768,
    kem::{Decapsulate, Encapsulate, Kem, KeyExport},
};

fn main() {
    println!("crate: ml-kem 0.3.4 (RustCrypto/KEMs, tag ml-kem/v0.3.4)");
    println!("parameter set: ML-KEM-768 (FIPS 203)");

    // Key generation.
    let (dk, ek) = MlKem768::generate_keypair();

    // Encapsulate a fresh shared secret to the encapsulation key.
    let (ct, k_send) = ek.encapsulate();

    // Decapsulate with the decapsulation key.
    let k_recv = dk.decapsulate(&ct);

    // The round-trip assertion: the two shared secrets must match.
    assert_eq!(k_send, k_recv, "shared secrets differ after decapsulation");
    let shared_secrets_match = k_send == k_recv;

    // Sizes only.
    let ek_bytes = ek.to_bytes();
    let dk_seed_bytes = dk.to_bytes();
    #[allow(deprecated)]
    let dk_expanded_bytes = dk.to_expanded_bytes();
    println!("encapsulation_key_bytes: {}", ek_bytes.len());
    println!("decapsulation_key_seed_bytes: {}", dk_seed_bytes.len());
    println!("decapsulation_key_expanded_bytes: {}", dk_expanded_bytes.len());
    println!("ciphertext_bytes: {}", ct.len());
    println!("shared_secret_bytes: {}", k_send.len());
    println!("shared_secrets_match: {}", shared_secrets_match);
    println!("expected: ek=1184 dk_seed=64 dk_expanded=2400 ct=1088 ss=32");
    assert_eq!(ek_bytes.len(), 1184, "unexpected encapsulation key size");
    assert_eq!(
        dk_seed_bytes.len(),
        64,
        "unexpected decapsulation key seed size"
    );
    assert_eq!(
        dk_expanded_bytes.len(),
        2400,
        "unexpected expanded decapsulation key size"
    );
    assert_eq!(ct.len(), 1088, "unexpected ciphertext size");
    assert_eq!(k_send.len(), 32, "unexpected shared secret size");
    assert!(shared_secrets_match, "shared secrets do not match");
    println!("RESULT: ML-KEM-768 round-trip OK");
}
