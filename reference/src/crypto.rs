use ml_dsa::{
    KeyExport, Keypair, MlDsa65, Signature, SignatureEncoding, Signer, SigningKey, Verifier,
    VerifyingKey,
};
use sha2::{Digest, Sha384};

/// SHA-384 retains a 192-bit generic preimage security margin against Grover's
/// algorithm and is the only digest algorithm in Example Profile 00.
pub fn sha384(bytes: &[u8]) -> String {
    hex::encode(Sha384::digest(bytes))
}

pub fn domain_digest(domain: &str, bytes: &[u8]) -> String {
    let mut hash = Sha384::new();
    hash.update(b"VSTP-EXAMPLE-00\0");
    hash.update(domain.as_bytes());
    hash.update(b"\0");
    hash.update(bytes);
    hex::encode(hash.finalize())
}

pub fn sign_id(secret: &[u8; 32], id: &str) -> Result<(String, String), String> {
    let message = hex::decode(id).map_err(|e| format!("invalid identifier: {e}"))?;
    let key = SigningKey::<MlDsa65>::from_seed(&(*secret).into());
    let signature: Signature<MlDsa65> = key.sign(&message);
    Ok((
        hex::encode(key.verifying_key().to_bytes()),
        hex::encode(signature.to_bytes()),
    ))
}

pub fn verify_id(public_key: &str, id: &str, signature: &str) -> Result<(), String> {
    let pk = hex::decode(public_key).map_err(|_| "signature-invalid")?;
    let sig = hex::decode(signature).map_err(|_| "signature-invalid")?;
    let message = hex::decode(id).map_err(|_| "signature-invalid")?;
    let encoded_key = pk.as_slice().try_into().map_err(|_| "signature-invalid")?;
    let key = VerifyingKey::<MlDsa65>::decode(&encoded_key);
    let signature =
        Signature::<MlDsa65>::try_from(sig.as_slice()).map_err(|_| "signature-invalid")?;
    key.verify(&message, &signature)
        .map_err(|_| "signature-invalid".into())
}
