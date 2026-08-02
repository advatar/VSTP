# Writing a VSTP Profile

Informative. This document is a checklist and template for authoring a domain
profile. Normative requirements are in §10 of
`draft-sellstrom-vstp-core-00.md`; where this document and the specification
disagree, the specification governs.

VSTP core is not usable alone. It defines invariant structure and verifier
obligations; a profile supplies everything domain-specific. A core object
without a profile cannot be encoded, its principals cannot be resolved, and its
state commitments cannot be computed.

---

## Why the profile boundary sits where it does

Everything the core omits — identity, policy language, serialization,
representation rules, transport, ledger — is omitted because it is a choice
with a shorter expected lifetime than the protocol, or because deployments have
already made that choice differently and correctly for their domain.

The consequence is that profile authors carry real obligations. A weak profile
produces records that verify successfully and establish very little. The
checklist below exists to make that outcome visible before deployment rather
than during a dispute.

---

## Checklist

A conforming profile must specify all fourteen requirements in core §13.1.
Items marked **⚠** are the ones
most often skipped and most consequential.

### Identity and keys

- [ ] Which identity system supplies principals for each role: `actor`,
      `instrument`, `agent`, `device`, `recorder`, `approver`, receipt
      `issuer`.
- [ ] How a verifier resolves a principal to a key **offline**. If resolution
      requires an online service, say so; it caps several dimensions.
- [ ] Key rotation, revocation, and recovery, and how records signed under a
      superseded key are evaluated.
- [ ] **⚠** Whether principal identifiers are correlatable across contexts. For
      natural persons, prefer context-scoped pairwise identifiers.

### Encoding and cryptography

- [ ] Encoding profile identifier, satisfying determinism, injectivity, domain
      separation, and bounds (core §4.1.1).
- [ ] **⚠** A post-quantum signature algorithm standardized by a recognized
      standards body. Classical-only modes are non-conforming. If a hybrid is
      used, acceptance must require its post-quantum component over the complete
      signed input (core §4.1.5).
- [ ] Digest algorithm(s), and the acceptability policy verifiers should apply.
      They must retain at least 128 bits of security against known generic
      quantum collision and preimage attacks.
- [ ] Accumulator construction for checkpoints, and whether it supports
      non-inclusion proofs.
- [ ] Commitment construction where hiding commitments are used.

### Representation

- [ ] **⚠** Every representation profile used, with normalization rules
      complete enough that two independent implementations produce **identical
      octets** for the same state. This is the most common source of
      cross-implementation continuity failures. Ambiguity here is not a
      documentation gap; it is a correctness bug that surfaces as spurious
      `state-discontinuity` findings.
- [ ] Whether multiple representation profiles may describe the same resource,
      and if so, that they are never compared for equality.

### Resources and operations

- [ ] Resource types and how identifiers are assigned at genesis.
- [ ] Which mutable properties appear in `labels` — and confirmation that none
      of them are used for identity.
- [ ] Operation profiles and their semantics.
- [ ] Which structural classes the profile uses, and any it forbids.
- [ ] Whether the profile composes with others — whether its transitions may
      reference or contain transitions governed by another profile — and how a
      verifier evaluates a graph spanning both. A profile covering an
      end-to-end process will typically subordinate a narrower one covering the
      artifacts it touches.
- [ ] **⚠** Before defining any new object type: confirm the structure is not
      already representable as a transition chain (core §3.4). Intent
      transformations, approvals, releases, derivations, and revocations all
      are. New object types break uniform graph traversal, which is the
      property the single-primitive model exists to preserve.

### Authority

- [ ] **⚠** The authority model, satisfying every requirement of core §5.2:
      decidable scope containment, non-amplification, scope over resources and
      structural classes, defined revocation timing semantics, offline
      evaluability.
- [ ] The policy language or evaluation model.
- [ ] **⚠** Whether decisions are reproducible (core §5.4). If not, state that
      `policy-reproduction` is permanently `not-attempted` and that decisions
      are typed as `declaration`. Do not leave this implicit.
- [ ] Where approvals are used: how `presentation_commitment` is computed, and
      how `presence_method` values are established.

### Completeness

- [ ] **⚠** The mediation level achievable, and the evidence supporting it.
      `mediated` and `enforced` require evidence independent of the recorder's
      own assertion; without it, verifiers downgrade to `asserted`.
- [ ] **⚠** The `boundary`, `observation_method`, `bypass_paths`, and
      `limitations` a conforming recorder must declare (core §7.2). Enumerating
      bypass paths honestly is the single most useful thing a profile does for
      the people who will eventually rely on its records. An empty
      `bypass_paths` below `enforced` is a claim, and it will be read as one.
- [ ] The observation interval or checkpoint cadence, since it bounds the
      undetectability window for out-of-band modification.
- [ ] Whether and how the profile emits `discontinuity` transitions.

### Privacy and retention

- [ ] For every element the profile defines: whether it may carry personal
      data, and which commitment construction applies. Note that a bare digest
      of a low-entropy value is not anonymous.
- [ ] The disclosure policy structure (core §9.1): public, selectively
      disclosable, commitment-only, and encrypted elements; retention class;
      erasure model; unlinkability mode; supersession policy.
- [ ] **⚠** The retention and erasure model. "Immutable" is a legal position;
      state it as one. If erasure obligations apply, specify erasure-tolerant
      construction (core §9.4). State separately which of the three cases the
      profile can offer per element: erasure of controlled data, invalidation
      of a claim, or neither because the evidence is already distributed.
- [ ] **⚠** A metadata leakage statement (core §9.5): what an observer holding
      only commitments learns from transition count, cadence, principal
      recurrence, branching structure, and committed sizes.

### Evidence and assurance

- [ ] Receipt types required or accepted, and the dimensions each contributes
      to.
- [ ] **⚠** For acts with effects in external systems: what evidence raises
      `effect-confirmation` above `declared`, and the threshold required (core
      §8.5). A finality receipt alone caps it at `attested` — confirming that
      the external system holds the *declared* state needs an independent
      observation under a comparable representation profile.
- [ ] External evidence bindings, and the dimensions each contributes to —
      never more.
- [ ] Any additional assurance dimensions the profile defines.
- [ ] Any dimension the profile declares permanently `not-established`.
- [ ] **⚠** At least one named, versioned **assurance policy**: the
      per-dimension thresholds for acceptance in this domain (core §8.5). This
      is what lets an implementation say "accepted under
      `<profile>/<policy>@<version>`" instead of "verified". Without it, every
      implementer invents a private threshold and the assurance vector's
      honesty is lost at the last step.

### Robustness and interoperability

- [ ] Bounds on every variable-length element, object size, graph size, parent
      cardinality, and traversal depth.
- [ ] Test vectors: valid objects, boundary cases, and **malformed-input
      rejection cases**. A profile without rejection vectors has not specified
      its security posture.

---

## Template

```
# <Profile Name> Profile for VSTP
Profile identifier: <registered identifier>
Version:            <version>
Status:             <draft | stable>
Core reference:     draft-sellstrom-vstp-core-XX

1. Scope and applicability
   What this profile covers. What it explicitly does not.

2. Principals and key resolution
   Per role. Offline resolution procedure. Rotation and revocation.
   Correlation properties of identifiers.

3. Encoding and cryptography
   Encoding profile. Digest algorithms. Accumulator. Commitments.

4. Resources
   Types. Identifier assignment. Labels, and the statement that labels are
   never identity.

5. Representation profiles
   One subsection per profile. Complete normalization rules.

6. Structural classes and operations
   Classes used and forbidden. Operation profiles and semantics.

7. Authority
   Model, and a point-by-point demonstration against core §5.2.
   Policy language. Reproducibility statement.

8. Approvals
   Presentation commitment computation. Presence methods.
   proposal_origin determination.

9. Mediation
   Achievable level. Supporting evidence. Observation cadence.
   Discontinuity handling.

10. Evidence and assurance
    Receipt types. External bindings and their dimensions.
    Additional and permanently-unestablished dimensions.

11. Privacy and retention
    Per-element personal data statement. Retention and erasure model.
    Metadata leakage statement.

12. Bounds

13. Test vectors
    Valid, boundary, and rejection cases.

14. Security considerations specific to this domain
```

---

## Failure modes to check for before publishing

A profile that passes the checklist can still be weak. Read the draft against
these:

**The profile records authority but nothing checks it.** If the authority model
has no decidable containment relation, verifiers cannot check delegation and
`authority` never rises above `asserted`. The mandatory authority element is
then paperwork.

**Reproducibility is claimed but inputs are incomplete.** If the policy
consults anything not covered by `inputs_commitment` — wall-clock time, an
external lookup, evaluator-local configuration — the decision is not
reproducible, and marking it so will produce `policy-contradicted` findings at
some later verifier. Under-claiming here costs nothing; over-claiming produces
a strong negative finding against your own records.

**Mediation is claimed above what the deployment supports.** The downgrade rule
means an unsupported claim of `mediated` becomes `asserted` plus a
`mediation-unsupported` finding — visibly worse than having claimed
`observational` honestly.

**Representation rules are described rather than specified.** "The canonical
form of the document" is not a normalization rule. If a second implementer
cannot reproduce your octets from your text, the profile is not finished.

**The leakage statement is omitted because payloads are withheld.** Withholding
payloads is exactly the case where structural leakage dominates. The statement
is most needed precisely when it feels least necessary.

**Erasure is deferred.** Erasure-tolerant construction cannot be retrofitted
without re-committing history. If there is any prospect the profile will touch
personal data, design it in now.
