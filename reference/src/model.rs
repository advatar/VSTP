use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Bundle {
    pub profile: String,
    pub keys: Vec<Key>,
    pub disclosed_states: Vec<DisclosedState>,
    pub authority: Authority,
    pub transition: Transition,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Key {
    pub principal: String,
    pub public_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct DisclosedState {
    pub resource: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Authority {
    pub root_principal: String,
    pub root_scope: Vec<Permission>,
    pub delegations: Vec<Delegation>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Permission {
    pub resource: String,
    pub structural_class: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Delegation {
    pub delegator: String,
    pub delegate: String,
    pub scope: Vec<Permission>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Transition {
    pub id: String,
    pub parents: Vec<String>,
    pub prior_states: Vec<Commitment>,
    pub resulting_states: Vec<Commitment>,
    pub actor: String,
    pub recorder: String,
    pub sequence: u64,
    pub structural_class: String,
    pub signature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Commitment {
    pub resource: String,
    pub representation_profile: String,
    pub representation_version: u64,
    pub algorithm: String,
    pub digest: String,
}

#[derive(Debug, Serialize)]
pub struct UnsignedTransition<'a> {
    pub parents: &'a [String],
    pub prior_states: &'a [Commitment],
    pub resulting_states: &'a [Commitment],
    pub actor: &'a str,
    pub recorder: &'a str,
    pub sequence: u64,
    pub structural_class: &'a str,
}

impl Transition {
    pub fn unsigned(&self) -> UnsignedTransition<'_> {
        UnsignedTransition {
            parents: &self.parents,
            prior_states: &self.prior_states,
            resulting_states: &self.resulting_states,
            actor: &self.actor,
            recorder: &self.recorder,
            sequence: self.sequence,
            structural_class: &self.structural_class,
        }
    }
}

#[derive(Debug, Serialize, PartialEq, Eq)]
pub struct AssuranceVector {
    pub record_integrity: &'static str,
    pub attribution: &'static str,
    pub authority: &'static str,
    pub graph_continuity: &'static str,
    pub disclosure_completeness: &'static str,
}

#[derive(Debug, Serialize, PartialEq, Eq)]
pub struct VerificationReport {
    pub valid: bool,
    pub transition_id: String,
    pub assurance: AssuranceVector,
    pub findings: Vec<String>,
}
