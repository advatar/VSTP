# VSTP reference implementation

This is a deliberately small, non-production verifier for
[`profiles/example-00.md`](../profiles/example-00.md). It exists to make the
core specification's verification rules executable and to reproduce the
checked-in vectors. It is not an implementation of every core extension.

Example Profile 00 is post-quantum only: ML-DSA-65 signatures (FIPS 204) and
SHA-384 commitments. There is no classical or hybrid fallback.

```sh
cargo test --manifest-path reference/Cargo.toml
cargo run --manifest-path reference/Cargo.toml -- \
  verify vectors/example-00/valid-genesis.json
```

Exit status is `0` for a valid bundle, `1` for a completed verification with
negative findings, and `2` for malformed input or operational failure.

The RustCrypto `ml-dsa` crate used here describes itself as unaudited. This
repository is a protocol demonstrator, not a production cryptographic module.
