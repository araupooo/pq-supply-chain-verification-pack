// Command pqcheck exercises the Go standard library post-quantum packages
// crypto/mlkem (ML-KEM-768, NIST FIPS 203) and crypto/mldsa (ML-DSA-65,
// NIST FIPS 204) as shipped with Go 1.27.3.
//
// It prints only fixed sizes and boolean success values — never key,
// ciphertext, signature, or shared-secret bytes — so its stdout is fully
// deterministic across runs despite random key generation.
package main

import (
	"bytes"
	"crypto/mldsa"
	"crypto/mlkem"
	"fmt"
	"os"
)

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "FAIL: "+format+"\n", args...)
	os.Exit(1)
}

func main() {
	fmt.Println("go-stdlib pqcheck (crypto/mlkem ML-KEM-768, crypto/mldsa ML-DSA-65)")

	// --- ML-KEM-768 ---
	dk, err := mlkem.GenerateKey768()
	if err != nil {
		fail("mlkem.GenerateKey768: %v", err)
	}
	ekBytes := dk.EncapsulationKey().Bytes()
	fmt.Printf("mlkem-768 encapsulation_key_bytes=%d (const EncapsulationKeySize768=%d)\n",
		len(ekBytes), mlkem.EncapsulationKeySize768)
	fmt.Printf("mlkem-768 decapsulation_key_bytes=%d\n", len(dk.Bytes()))

	ek, err := mlkem.NewEncapsulationKey768(ekBytes)
	if err != nil {
		fail("mlkem.NewEncapsulationKey768: %v", err)
	}
	sharedKey, ciphertext := ek.Encapsulate()
	fmt.Printf("mlkem-768 shared_key_bytes=%d (const SharedKeySize=%d)\n",
		len(sharedKey), mlkem.SharedKeySize)
	fmt.Printf("mlkem-768 ciphertext_bytes=%d (const CiphertextSize768=%d)\n",
		len(ciphertext), mlkem.CiphertextSize768)

	decapped, err := dk.Decapsulate(ciphertext)
	if err != nil {
		fail("mlkem.Decapsulate: %v", err)
	}
	fmt.Printf("mlkem-768 decapsulate_ok=%v shared_key_match=%v\n",
		err == nil, bytes.Equal(sharedKey, decapped))

	// --- ML-DSA-65 ---
	params := mldsa.MLDSA65()
	fmt.Printf("mldsa-65 params=%s public_key_size=%d signature_size=%d\n",
		params.String(), params.PublicKeySize(), params.SignatureSize())

	sk, err := mldsa.GenerateKey(params)
	if err != nil {
		fail("mldsa.GenerateKey(MLDSA65): %v", err)
	}
	pkBytes := sk.PublicKey().Bytes()
	fmt.Printf("mldsa-65 public_key_bytes=%d private_key_bytes=%d\n",
		len(pkBytes), len(sk.Bytes()))

	msg := []byte("post-quantum supply-chain verification pack")
	opts := &mldsa.Options{Context: "pqcheck"}
	sig, err := sk.Sign(nil, msg, opts)
	if err != nil {
		fail("mldsa.Sign: %v", err)
	}
	fmt.Printf("mldsa-65 signature_bytes=%d\n", len(sig))

	pk, err := mldsa.NewPublicKey(params, pkBytes)
	if err != nil {
		fail("mldsa.NewPublicKey: %v", err)
	}
	verifyErr := mldsa.Verify(pk, msg, sig, opts)
	fmt.Printf("mldsa-65 verify_ok=%v\n", verifyErr == nil)
	if verifyErr != nil {
		fail("mldsa.Verify: %v", verifyErr)
	}
	// Negative check: tampered message must NOT verify.
	tampered := []byte("post-quantum supply-chain verification pock")
	fmt.Printf("mldsa-65 verify_tampered_rejected=%v\n",
		mldsa.Verify(pk, tampered, sig, opts) != nil)

	// --- Size assertions (FIPS 203 / FIPS 204 parameter-set sizes) ---
	if len(ekBytes) != mlkem.EncapsulationKeySize768 || len(ciphertext) != mlkem.CiphertextSize768 || len(sharedKey) != mlkem.SharedKeySize {
		fail("mlkem-768 size mismatch")
	}
	if len(pkBytes) != params.PublicKeySize() || len(sig) != params.SignatureSize() {
		fail("mldsa-65 size mismatch")
	}
	fmt.Println("ALL CHECKS PASSED")
}
