use std::{fs, path::PathBuf};
use vstp_reference::{
    model::{Bundle, VerificationReport},
    verify,
};

#[test]
fn checked_in_vectors_match_expected_reports() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../vectors/example-00");
    for name in [
        "valid-genesis",
        "invalid-signature",
        "authority-scope-exceeded",
    ] {
        let bundle: Bundle =
            serde_json::from_slice(&fs::read(root.join(format!("{name}.json"))).unwrap()).unwrap();
        let actual = serde_json::to_value(verify::verify(&bundle)).unwrap();
        let expected: serde_json::Value =
            serde_json::from_slice(&fs::read(root.join(format!("{name}.expected.json"))).unwrap())
                .unwrap();
        assert_eq!(actual, expected, "vector {name}");
    }
}

#[test]
fn valid_vector_is_valid_and_negative_vectors_are_not() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../vectors/example-00");
    let load = |name: &str| -> VerificationReport {
        let bundle: Bundle =
            serde_json::from_slice(&fs::read(root.join(format!("{name}.json"))).unwrap()).unwrap();
        verify::verify(&bundle)
    };
    assert!(load("valid-genesis").valid);
    assert!(!load("invalid-signature").valid);
    assert!(!load("authority-scope-exceeded").valid);
}
