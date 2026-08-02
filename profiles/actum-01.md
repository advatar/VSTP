# ActiveChain Actum Profile (Actum-01)

Status: informative draft, interop-first.

This profile is the first practical bridge between ActiveChain/Actum records and VSTP.
It is not a production ActiveChain normative draft; it is an interoperability
profile for standardized exported artifacts.

## Profile identity

- Profile identifier: `urn:vstp:actum:v1`
- Draft identifier: `actum-01`
- Version: `1`

## Scope

This profile covers finalized Actum transitions that already have:

- actor/initiator identity material,
- authorization chain (delegation or capability),
- policy decision context,
- finality or inclusion evidence.

It is intentionally scoped to **actum action transitions** and does not define
new consensus rules.

## Core choices

- Signature algorithm: ML-DSA (post-quantum only).
- Transition identifier digest: SHA-384 with domain separator.
- State commitment:
  - profile: `actum-state:v1`,
  - algorithm: `sha-384`,
  - representation version: `1`.
- State and transition JSON handling: deterministic UTF-8 JSON, no trailing
  members, stable key order.
- Encoding:
  - canonical bundle encoding for hash inputs,
  - explicit unknown-field rejection on import.

## Principals

The profile uses principal identifiers carried by ActiveChain records.
A verifier resolves keys from an explicit keyring carried in the bundle for offline
verification.

- `actor`: principal that caused the act.
- `recorder`: recorder/exporter principal.
- `authority root`: principal responsible for top-level delegation root.

## Authority

- Authority statements must include at least:
  - root principal,
  - explicit scope (resource + structural class),
  - chain of delegations.
- Delegation scope checks require subset-like attenuation.
- The final effective holder must be the same actor that executes the transition.

## Completeness and assurance intent

- `completeness: asserted` by default.
- `completeness: observed` if the recorder can show observation coverage.
- `mediated` only where recorder mediation can be demonstrated in export evidence.
- `effect-confirmation` is `attested` only when finality evidence is bound to this
  transition by a stable chain identity.

## Evidence fields carried in exported bundle

The bridge bundle carries `actum_evidence` with:

- policy decision commitments,
- decision reproducibility material,
- approvals (human/approval device events),
- finality / receipt / checkpoint references.

The field names are intentionally explicit and namespace-prefixed:
`actum_evidence.policy_decision`, `actum_evidence.approvals`,
`actum_evidence.finality`.

## Mapping boundaries

- VSTP transition continuity checks apply to action ordering within the bridge context.
- ActiveChain consensus ordering and liveness properties remain available as
  external evidence; they do not replace VSTP's own continuity checks.
- Receipts and proofs are transported as independent evidence references and
  mapped to assurance dimensions; they are not interpreted as total truth.

## Interoperability artifacts

Use:

- `interoperability/activechain/actum_to_vstp.py`
- `interoperability/activechain/actum-action-export.json` (template)
- `interoperability/activechain/actum-keyring.json` (template)
- `interoperability/activechain/bridge.md`

## Conformance gate for adoption

Profile adoption is blocked until the following are true in one release:

1. Deterministic export test vectors for at least one action transition type.
2. Negative vectors for missing authority attenuation and malformed policy inputs.
3. One documented continuity incident response policy for replay/rollback attempts.

