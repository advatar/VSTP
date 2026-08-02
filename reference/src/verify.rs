use crate::model::{AssuranceVector, Bundle, VerificationReport};
use crate::{authority, canonical, crypto};

pub const PROFILE: &str = "vstp-example-00";

pub fn transition_id(bundle: &Bundle) -> Result<String, String> {
    Ok(crypto::domain_digest(
        "transition:v1",
        &canonical::to_vec(&bundle.transition.unsigned())?,
    ))
}

pub fn verify(bundle: &Bundle) -> VerificationReport {
    let mut findings = Vec::new();
    let computed_id = transition_id(bundle).unwrap_or_default();

    if bundle.profile != PROFILE {
        findings.push("profile-unsupported".into());
    }
    if computed_id != bundle.transition.id {
        findings.push("identifier-mismatch".into());
    }

    let key = bundle
        .keys
        .iter()
        .find(|key| key.principal == bundle.transition.actor);
    match key {
        Some(key) => {
            if let Err(finding) = crypto::verify_id(
                &key.public_key,
                &bundle.transition.id,
                &bundle.transition.signature,
            ) {
                findings.push(finding);
            }
        }
        None => findings.push("actor-key-missing".into()),
    }

    for commitment in bundle
        .transition
        .prior_states
        .iter()
        .chain(&bundle.transition.resulting_states)
    {
        if commitment.representation_profile != "utf8-text"
            || commitment.representation_version != 1
            || commitment.algorithm != "sha-384"
        {
            findings.push("representation-unsupported".into());
            continue;
        }
        match bundle
            .disclosed_states
            .iter()
            .find(|state| state.resource == commitment.resource)
        {
            Some(state)
                if crypto::domain_digest("state:utf8-text:v1", state.content.as_bytes())
                    != commitment.digest =>
            {
                findings.push("state-digest-mismatch".into())
            }
            None => findings.push("state-not-disclosed".into()),
            _ => {}
        }
    }

    match authority::effective_scope(&bundle.authority, &bundle.transition.actor) {
        Err(finding) => findings.push(finding),
        Ok(scope) => {
            for state in bundle
                .transition
                .prior_states
                .iter()
                .chain(&bundle.transition.resulting_states)
            {
                if !authority::covers(&scope, &state.resource, &bundle.transition.structural_class)
                {
                    findings.push("authority-scope-exceeded".into());
                }
            }
        }
    }

    findings.sort();
    findings.dedup();
    let valid = findings.is_empty();
    let profile_supported = !findings.iter().any(|f| f == "profile-unsupported");
    let integrity_contradicted = findings.iter().any(|f| {
        matches!(
            f.as_str(),
            "identifier-mismatch"
                | "representation-unsupported"
                | "state-digest-mismatch"
                | "state-not-disclosed"
        )
    });
    let attribution_contradicted = findings
        .iter()
        .any(|f| matches!(f.as_str(), "signature-invalid" | "actor-key-missing"));
    let authority_contradicted = findings.iter().any(|f| f.starts_with("authority-"));
    VerificationReport {
        valid,
        transition_id: computed_id,
        assurance: AssuranceVector {
            record_integrity: if !profile_supported {
                "not-established"
            } else if integrity_contradicted {
                "contradicted"
            } else {
                "verified"
            },
            attribution: if !profile_supported {
                "not-established"
            } else if attribution_contradicted {
                "contradicted"
            } else {
                "verified"
            },
            authority: if !profile_supported {
                "not-established"
            } else if authority_contradicted {
                "contradicted"
            } else {
                "verified"
            },
            graph_continuity: if bundle.transition.parents.is_empty() {
                "not-established"
            } else {
                "declared"
            },
            disclosure_completeness: "declared",
        },
        findings,
    }
}
