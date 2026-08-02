use std::{fs, path::PathBuf};
use vstp_reference::{crypto, model::*, verify};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let output = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../vectors/example-00");
    fs::create_dir_all(&output)?;

    let content = "VSTP post-quantum example\n";
    let resource = "urn:example:vstp:resource:document-1";
    let principal = "urn:example:vstp:principal:alice-ml-dsa-65";
    let commitment = Commitment {
        resource: resource.into(),
        representation_profile: "utf8-text".into(),
        representation_version: 1,
        algorithm: "sha-384".into(),
        digest: crypto::domain_digest("state:utf8-text:v1", content.as_bytes()),
    };
    let mut bundle = Bundle {
        profile: verify::PROFILE.into(),
        keys: vec![],
        disclosed_states: vec![DisclosedState {
            resource: resource.into(),
            content: content.into(),
        }],
        authority: Authority {
            root_principal: principal.into(),
            root_scope: vec![Permission {
                resource: resource.into(),
                structural_class: "genesis".into(),
            }],
            delegations: vec![],
        },
        transition: Transition {
            id: String::new(),
            parents: vec![],
            prior_states: vec![],
            resulting_states: vec![commitment],
            actor: principal.into(),
            recorder: principal.into(),
            sequence: 0,
            structural_class: "genesis".into(),
            signature: String::new(),
        },
    };
    bundle.transition.id = verify::transition_id(&bundle)?;
    let (public_key, signature) = crypto::sign_id(&[0x42; 32], &bundle.transition.id)?;
    bundle.keys.push(Key {
        principal: principal.into(),
        public_key,
    });
    bundle.transition.signature = signature;

    write_case(&output, "valid-genesis", &bundle)?;

    let mut bad_signature = bundle.clone();
    bad_signature.transition.signature.replace_range(0..2, "00");
    write_case(&output, "invalid-signature", &bad_signature)?;

    let mut exceeded = bundle.clone();
    exceeded.authority.root_scope.clear();
    write_case(&output, "authority-scope-exceeded", &exceeded)?;
    Ok(())
}

fn write_case(
    output: &std::path::Path,
    name: &str,
    bundle: &Bundle,
) -> Result<(), Box<dyn std::error::Error>> {
    fs::write(
        output.join(format!("{name}.json")),
        format!("{}\n", serde_json::to_string_pretty(bundle)?),
    )?;
    fs::write(
        output.join(format!("{name}.expected.json")),
        format!(
            "{}\n",
            serde_json::to_string_pretty(&verify::verify(bundle))?
        ),
    )?;
    Ok(())
}
