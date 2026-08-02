# ActiveChain ↔ VSTP bridge (first-pass v1)

This is a practical bridge so ActiveChain/Actum artifacts can be projected into a VSTP transition bundle.

This first-pass does three things:

- gives ActiveChain a stable profile identity in VSTP terms,
- defines the required field mapping from Actum consensus and policy evidence into VSTP,
- ships an example converter script.

The mapping does not replace ActiveChain consensus verification. It creates an
interoperable record surface where an external verifier can independently inspect
state transitions, authority chains, and assurance boundaries.

## 1) Profile registration

Create a profile document entry:

- Profile name: **ActiveChain Actum Profile v1**
- Profile identifier: `urn:vstp:actum:v1`
- Cryptography policy: post-quantum only (no classical-only fallback)
- Hashing policy: SHA-384 for state commitments and transition identifier inputs
- State representation profiles:
  - `actum-state:v1`
  - `actum-action:v1`
- Structural classes:
  - `actum.action`
  - `actum.discontinuity`

## 2) Mapping contract

The bridge maps one ActiveChain finalized transition bundle into one VSTP transition.

| VSTP field | ActiveChain source | Notes |
|---|---|---|
| `context_id` | chain ID + genesis commitment + protocol revision | Bound by verifier policy in profile metadata |
| `transition.id` | VSTP canonical transition hash | Deterministic from canonical transition payload |
| `transition.parents` | Finalized parent transition IDs (or checkpoints) | At least one parent for non-genesis |
| `transition.prior_states` | Actum pre-state commitments | Ordered by acted resource |
| `transition.resulting_states` | Actum post-state commitments | Ordered by acted resource |
| `transition.actor` | Action actor principal | Principal URI/identifier used in ActiveChain records |
| `transition.recorder` | Wallet/agent/service principal that exported the bundle | Not the consensus key; the recorder is the exporting actor |
| `transition.sequence` | Finalized height or monotonically increasing local sequence | Must preserve total order inside the chosen context |
| `transition.structural_class` | ActiveChain domain class (`actum.action`/`actum.discontinuity`) | Domain-specific class namespace |
| `authority.root_principal` | Chain root governance principal | Must be stable within the chain context |
| `authority.root_scope` | Scope tuples `{resource, structural_class}` derived from policy registry | Must match action resource scope |
| `authority.delegations` | Capability chain + delegation attestations | Evaluated offline where possible |
| `disclosed_states` | Optional state snapshots for audit/derivation proofs | Content commitments are required, disclosure optional |
| `signature` | ML-DSA signature over VSTP transition canonical bytes | Must bind to `transition.id` payload |

### Evidence mapping

- `Authorization decision` → bind to `policy_decision_reference` metadata plus policy
  digest (`policy_commitment`) and decision hash.
- `Human approval / device confirmation` → preserve in `approvals` vector and map to
  assurance tags.
- `Finality / receipts / checkpoints` → emit as external evidence references in
  transition-attached metadata; these evidence inputs support the VSTP
  assurance dimension for effects and ordering.

### Assurance intent

ActiveChain evidence that should normally map into the following VSTP assurance
channels:

- `integrity` / `attribution`: signature chain + deterministic canonicalization
- `authority`: capability chain + policy decision reproduction
- `graph-continuity`: parent IDs + continuity checks + discontinuity transitions
- `effect-confirmation`: finality certificate / receipt references
- `completeness`: recorder mode declarations (`observational`, `native`, `mediated`)

## 3) Export workflow

1. ActiveChain produces a finalized action record plus:
   - capability/authorization material,
   - policy decision material,
   - any receipt and finality evidence needed for effect confirmation.
2. Exporter normalizes those into `interoperability/activechain/actum-action-export.json`.
3. Converter derives VSTP commitments:
   - normalize payloads to deterministic JSON,
   - compute state commitments where needed,
   - compute transition canonical input and id,
   - include recorder keyring for offline verification by external tooling,
   - emit VSTP bundle.
4. Bundle passes through the VSTP verifier as an independent artifact, separate from
   the ActiveChain node or account state.

## 4) Included artifacts

- `actum-to-vstp` conversion script:
  `interoperability/activechain/actum_to_vstp.py`
- Input example:
  `interoperability/activechain/actum-action-export.json`
- Output example:
  `interoperability/activechain/example-vstp-transition.json`

## 5) Minimal command

```bash
python3 interoperability/activechain/actum_to_vstp.py \
  --input interoperability/activechain/actum-action-export.json \
  --keys interoperability/activechain/actum-keyring.json \
  --output interoperability/activechain/example-vstp-transition.json
```

This produces a profile-specific VSTP bundle you can hand to the VSTP reference
stack for independent verification.
