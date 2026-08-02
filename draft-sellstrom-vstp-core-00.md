---
title: "Verifiable State Transition Protocol (VSTP): Core Specification"
abbrev: "VSTP Core"
category: std
docname: draft-sellstrom-vstp-core-00
submissiontype: IETF
number:
date:
consensus: true
v: 3
area: "Security"
keyword:
 - provenance
 - state transition
 - authorization
 - transparency
 - evidence
author:
 -
    fullname: "Johan Sellström"
    organization: "Independent"
    email: "johan@sellstrom.me"

informative:
  FIPS204:
    title: "Module-Lattice-Based Digital Signature Standard"
    target: "https://doi.org/10.6028/NIST.FIPS.204"
    seriesinfo:
      FIPS: "204"
      DOI: "10.6028/NIST.FIPS.204"
    author:
      - org: "National Institute of Standards and Technology"
    date: 2024-08
  RFC3161:
    title: "Internet X.509 Public Key Infrastructure Time-Stamp Protocol (TSP)"
    target: "https://www.rfc-editor.org/info/rfc3161"
    seriesinfo:
      RFC: "3161"
      DOI: "10.17487/RFC3161"
    author:
      - ins: C. Adams
        name: Carlisle Adams
      - ins: P. Cain
        name: Pat Cain
      - ins: D. Pinkas
        name: Denis Pinkas
      - ins: R. Zuccherato
        name: Robert Zuccherato
    date: 2001-08
  RFC6920:
    title: "Naming Things with Hashes"
    target: "https://www.rfc-editor.org/info/rfc6920"
    seriesinfo:
      RFC: "6920"
      DOI: "10.17487/RFC6920"
    author:
      - ins: S. Farrell
        name: Stephen Farrell
      - ins: D. Kutscher
        name: Dirk Kutscher
      - ins: C. Dannewitz
        name: Christian Dannewitz
      - ins: B. Ohlman
        name: Boerje Ohlman
      - ins: A. Keranen
        name: Ari Keranen
      - ins: P. Hallam-Baker
        name: Phillip Hallam-Baker
    date: 2013-04
  RFC8785:
    title: "JSON Canonicalization Scheme (JCS)"
    target: "https://www.rfc-editor.org/info/rfc8785"
    seriesinfo:
      RFC: "8785"
      DOI: "10.17487/RFC8785"
    author:
      - ins: A. Rundgren
        name: Anders Rundgren
      - ins: B. Jordan
        name: Bret Jordan
      - ins: S. Erdtman
        name: Samuel Erdtman
    date: 2020-06
  RFC8949:
    title: "Concise Binary Object Representation (CBOR)"
    target: "https://www.rfc-editor.org/info/rfc8949"
    seriesinfo:
      STD: "94"
      RFC: "8949"
      DOI: "10.17487/RFC8949"
    author:
      - ins: C. Bormann
        name: Carsten Bormann
      - ins: P. Hoffman
        name: Paul Hoffman
    date: 2020-12
  RFC9162:
    title: "Certificate Transparency Version 2.0"
    target: "https://www.rfc-editor.org/info/rfc9162"
    seriesinfo:
      RFC: "9162"
      DOI: "10.17487/RFC9162"
    author:
      - ins: B. Laurie
        name: Ben Laurie
      - ins: E. Messeri
        name: Eran Messeri
      - ins: R. Stradling
        name: Rob Stradling
    date: 2021-12
  SCITT-ARCH:
    title: "An Architecture for Trustworthy and Transparent Digital Supply Chains"
    target: "https://datatracker.ietf.org/doc/draft-ietf-scitt-architecture/"
    author:
      - org: "IETF SCITT Working Group"
    date: 2025
  PROV-DM:
    title: "PROV-DM: The PROV Data Model"
    target: "https://www.w3.org/TR/prov-dm/"
    author:
      - org: "W3C"
    date: 2013
  VC-DM:
    title: "Verifiable Credentials Data Model"
    target: "https://www.w3.org/TR/vc-data-model-2.0/"
    author:
      - org: "W3C"
    date: 2025
  C2PA:
    title: "C2PA Technical Specification"
    target: "https://c2pa.org/specifications/"
    author:
      - org: "Coalition for Content Provenance and Authenticity"
    date: 2025
  IN-TOTO:
    title: "in-toto Specification"
    target: "https://github.com/in-toto/specification"
    author:
      - org: "in-toto"
    date: 2024
  SLSA:
    title: "Supply-chain Levels for Software Artifacts"
    target: "https://slsa.dev/spec/"
    author:
      - org: "OpenSSF"
    date: 2024

--- abstract

This document specifies the Verifiable State Transition Protocol (VSTP), an
implementation-independent protocol for recording, exchanging, and
independently verifying claims about transitions between committed states of
identified resources.

A VSTP record binds a prior state commitment and a resulting state commitment
to the principals that caused the transition, the authority under which they
were permitted to cause it, and the evidence supporting each of those claims.
Recorded transitions form a content-addressed causal graph rather than a linear
log. Provenance, audit trails, and change histories are derived views over that
graph rather than distinct constructs.

VSTP is deliberately incomplete: it defines neither an identity system, a
policy language, a serialization, a transport, nor a ledger. It defines the
minimal invariant structure such systems must produce so that a verifier with
no relationship to the recorder can reach — and justify — a conclusion about
what a recorded history does and does not establish.

VSTP makes one limitation normative rather than implicit. Integrity of a set of
records is independent of the completeness of that set. Every VSTP context
therefore declares the degree to which state-changing paths were mediated by
the recorder, and no conforming verifier may report a stronger completeness
conclusion than the accompanying evidence supports.

--- middle

# Introduction {#introduction}

## Problem Statement {#problem}

Systems that need to explain how a resource came to be in its present state
generally implement one of two things: a version control system, which records
content lineage but treats authorship as unverified metadata; or an audit log,
which records assertions about actions but does not bind them to the states
those actions produced.

Neither answers the question that matters in regulated processes, delegated
workflows, and autonomous execution:

> Why is this resource in this state, who was permitted to put it there, under
> what authority and policy, and can a third party re-derive that answer
> without trusting the party that recorded it?

Answering this requires binding, in a single verifiable structure, five claims
that are usually kept apart and are frequently conflated:

1. **State integrity** — that a specific prior state was transformed into a
   specific resulting state.
2. **Causal continuity** — that the transition occupies a specific position in
   a history that has not been rewritten, truncated, or silently reordered.
3. **Attribution** — which principals issued the claim, and in what roles.
4. **Authority** — why those principals were permitted to cause the
   transition, and under which policy that permission was decided.
5. **Existence and ordering** — that the record existed at a point in time and
   that its issuer did not present a conflicting history to someone else.

These are independent. A record can satisfy any subset. A protocol that reports
a single verification verdict necessarily discards this structure, and in doing
so overstates what was established.

## Scope {#scope}

This document specifies:

- an information model of six objects ({{data-model}});
- the requirements an authority model must satisfy to be usable with VSTP,
  and the conditions under which an authorization decision may be represented
  as reproducible ({{authority}});
- the epistemic typing of assertions ({{epistemic}});
- a mandatory declaration of recording mediation, and the verifier obligations
  that follow from it ({{completeness}});
- a verification procedure producing a structured assurance vector rather than
  a verdict ({{verification}});
- disclosure, redaction, and erasure requirements ({{disclosure}});
- the profile mechanism by which VSTP is bound to concrete domains
  ({{profiles}}).

This document does not specify:

- an identity, key distribution, or credential system;
- a policy language or evaluation engine;
- a serialization format or canonicalization algorithm;
- a transport, synchronization, or discovery mechanism;
- a consensus system, ledger, or timestamping authority;
- a diff, patch, or change-description format;
- an ontology of human or machine actions.

Each of these is supplied by a profile ({{profiles}}) or by a referenced
external specification. VSTP constrains how such components are bound into a
record and what a verifier may conclude from them; it does not select among
them. Every exclusion above is deliberate: a core that selects an identity
system, a policy language, or a serialization inherits that choice's lifetime,
its governance, and its failure modes, and becomes unusable in every deployment
that has already made a different choice.

## Relationship to Existing Work {#related}

VSTP does not replace and is not a competitor to the following. Where a
deployment already uses them, the intent is that they be carried as VSTP
evidence rather than reimplemented.

{{PROV-DM}} provides a general provenance data model. It is not cryptographic:
it describes derivation and attribution but does not commit to states or bind
claims to keys. VSTP's causal graph is compatible with a PROV interpretation
and can be projected into it.

{{C2PA}} binds provenance assertions to media assets with a strong ingestion
and rendering story. It is media-specific and does not model the authority
under which an edit was permitted. C2PA manifests are usable as VSTP
transformation evidence.

{{IN-TOTO}} and {{SLSA}} constrain build and supply-chain pipelines, including
a layout that functions as domain-specific authority. Their scope is
intentionally the software build graph. Attestations are usable as VSTP
evidence for transitions in that domain.

{{SCITT-ARCH}} defines a transparency architecture in which signed statements
are registered on an append-only service that returns receipts. SCITT
establishes that a statement was registered and is discoverable; it is
deliberately agnostic to the statement's content. SCITT receipts are a natural
VSTP receipt type ({{receipt}}), and a SCITT transparency service is a natural
substrate for VSTP checkpoints.

{{VC-DM}} provides issuer-signed claims about subjects, including identity
assurance. Credentials are usable as VSTP evidence for the attribution and
principal-identity assurance dimensions.

The distinguishing requirement of VSTP relative to all of the above is stated
once, here:

> VSTP requires every recorded transition to carry the authority under which it
> was permitted and a commitment to the authorization decision, in a form that
> permits an independent verifier to re-derive that decision. It is not
> sufficient to record that an act occurred and was registered; a conforming
> record must permit a third party to determine whether the acting principal
> was entitled to cause it.

Systems that record *what happened* and systems that record *what was
published* both leave this question to out-of-band trust. VSTP moves it inside
the verifiable structure.

## Requirements Language {#reqs}

{::boilerplate bcp14-tagged}


# Terminology {#terminology}

Resource:
: A logically identified thing whose state changes over time. A resource has an
  identity that is stable across changes to its state, and is not identified by
  any mutable property such as a name, path, location, or handle.

State:
: The condition of a resource at a point in its history. VSTP never handles
  states directly; it handles commitments to representations of states.

Representation:
: A determinate encoding of a resource's state under a stated interpretation. A
  resource may have several valid representations of the same state (for
  example, raw octets and a normalized structural form), and these are not
  interchangeable for commitment purposes.

State commitment:
: A binding, hiding-optional cryptographic commitment to a representation of a
  state, qualified by the representation profile under which it was computed.

Transition:
: A signed claim that identified principals, under stated authority,
  transformed one or more prior state commitments into one or more resulting
  state commitments.

Context:
: A named boundary within which resources are identified, transitions are
  recorded, sequence is meaningful, and an authority policy applies.

Recorder:
: A principal that issues transitions within a context.

Instrument:
: The software, service, or agent through which an actor acted. Distinct from
  the actor and from the recorder.

Principal:
: An entity that can hold keys and be attributed a claim. VSTP distinguishes
  principal *roles* (actor, instrument, agent, device, recorder, approver,
  issuer, witness) and does not treat them as interchangeable.

Authority:
: The basis on which a principal was permitted to cause a transition,
  consisting of a delegation chain, a policy commitment, and an authorization
  decision.

Evidence:
: An object referenced by a transition or checkpoint that supports, but is not
  itself, the claim being made.

Receipt:
: Evidence issued by a party other than the recorder concerning the existence,
  ordering, inclusion, or finalization of a checkpoint or transition.

Assurance vector:
: The structured, per-dimension output of verification.

Mediation:
: The degree to which the recorder was positioned to observe or intercept every
  state-changing path affecting a resource.

Bundle:
: A self-contained collection of VSTP objects and supporting evidence
  sufficient for offline verification of a stated set of transitions.


# Architectural Model {#architecture}

## The Primitive {#primitive}

The protocol has one primitive:

~~~
   S_prior  --[ T ]-->  S_result
~~~

where `S_prior` and `S_result` are state commitments and `T` is a signed claim
about the act that caused the transition, carrying attribution, authority, and
evidence.

Everything else in this specification is either a qualification of that
primitive, a means of aggregating it, or a constraint on what may be concluded
from it.

An act, in VSTP terms, is defined as:

> a verifiable transition between committed states, performed by an identified
> principal under specified authority.

This definition is deliberately free of any notion of file, document, message,
transaction, block, or commit. Where those concepts appear in a deployment,
they are bindings supplied by a profile.

## Graph, Not Log {#graph}

Recorded transitions form a directed acyclic graph. Each transition references
its parent transitions by identifier; identifiers are derived from content
({{object-ids}}); therefore a transition cannot reference a successor, and
acyclicity follows from collision resistance of the digest algorithm rather
than from any enforcement mechanism.

A linear log is one projection of this graph, useful operationally and
insufficient structurally. The graph is required because real histories
include:

- concurrent modification by independent recorders;
- offline work reconciled later;
- divergence that is never reconciled;
- convergence from multiple prior states;
- derivation of new resources from existing ones;
- partial synchronization, where a verifier holds a subgraph.

A convergence MUST be represented as a transition declaring all converged
parents and all corresponding prior state commitments. It MUST NOT be
represented in a way that discards a parent. Where a convergence leaves
disagreement unresolved, the disagreement is itself recorded as
evidence-bearing structure rather than silently resolved ({{merge-conflict}}).

## Separation of Assertion, Evidence, and Assurance {#separation}

VSTP maintains a strict three-way separation, and conflating any two of these
is the most common failure of systems in this space:

Assertion:
: What an object claims. Assertions are produced by recorders and carry an
  epistemic type ({{epistemic}}).

Evidence:
: What supports an assertion. Evidence is produced by parties with their own
  identities and interests — issuers, witnesses, transparency services,
  timestamping authorities, attesters, execution environments.

Assurance:
: What a verifier concludes, per dimension, from assertions and evidence
  together, under a stated verification policy.

A signature is evidence of authorship. It is not evidence of truth. A
transparency receipt is evidence of registration. It is not evidence that the
registered statement is correct. A finality receipt from a settlement system is
evidence that a commitment reached a terminal state in that system. It is not
evidence that the claims inside the commitment are true.

Conforming verifier output MUST preserve this separation ({{output}}).

## Constructions Over the Primitive {#constructions}

Several structures that other designs treat as distinct object types are
representable as ordinary transition chains. This is the practical payoff of
collapsing the model to one primitive, and profile authors should reach for it
before defining new objects.

The most important is the **intent transformation chain**. What a principal
expressed, what software interpreted it to mean, what was authorized, and what
executed are four different things, and a signature on the last of them proves
authorization while explaining nothing about whether the interpretation was
faithful. Each stage is a resource; each transformation is a transition:

~~~
expressed request        --[derive]-->   interpreted action
interpreted action       --[derive]-->   authorized action
authorized action        --[approve]-->  approval
authorized action        --[update]-->   external effect
~~~

Each stage carries its own state commitment, so the transformation between
stages is preserved and independently inspectable rather than collapsed. A
verifier can then report what was expressed, how it was interpreted, what was
presented for approval, what was authorized, and what executed — as five
distinct findings.

This is what makes `intent-fidelity` ({{dimensions}}) something a profile can
raise above `not-established`: not by proving what a person meant, which the
protocol cannot do, but by preserving each transformation so that a
misinterpretation is visible as a discontinuity between the expressed and
interpreted stages rather than invisible inside a single signed action.

Profiles SHOULD represent such chains as transitions rather than defining new
object types, and MUST NOT collapse stages whose divergence would be the
finding of interest.

## What VSTP Does Not Establish {#not-established}

The following are outside what any VSTP record can establish, regardless of the
strength of its evidence, and conforming implementations MUST NOT present
verification results that state or imply otherwise:

- that a signing principal was honest;
- that a declared semantic description of an operation is accurate;
- that a human understood or intended the consequences of an act they approved;
- that the content of a resource is correct, lawful, or fit for any purpose;
- that no unrecorded transition occurred, except to the degree established
  under {{completeness}};
- that the represented history is the only history of the resource.

The protocol establishes what was claimed, by whom, under what authority, with
what supporting evidence, and with what internal consistency. It is a structure
for making the boundary of a claim explicit, not for eliminating it.


# Data Model {#data-model}

The six objects are: Context ({{context}}), Resource ({{resource}}), State
Commitment ({{state-commitment}}), Transition ({{transition}}), Checkpoint
({{checkpoint}}), and Receipt ({{receipt}}).

Element names below name elements of an information model. They are not wire
names; an encoding profile ({{encoding}}) determines wire representation.

## Common Conventions {#conventions}

### Encoding {#encoding}

VSTP does not define a serialization. It defines requirements on any encoding
profile used with it. An encoding profile MUST:

1. be **deterministic**: a given information-model instance MUST have exactly
   one octet representation;
2. be **injective**: distinct instances MUST have distinct representations,
   with no ambiguity arising from field ordering, absent-versus-empty
   distinctions, numeric representation, string normalization, or nesting
   boundaries;
3. define **explicit domain separation** for every digest computation defined
   in this document, such that a digest computed over one object type cannot
   equal a digest computed over another;
4. define **bounds** on every variable-length element, and on total object and
   graph size;
5. carry a **registered encoding profile identifier**.

A context MUST declare exactly one encoding profile ({{context}}). All objects
bound to that context MUST use it. A verifier encountering an object encoded
under a profile other than the one declared by its context MUST reject the
object with `encoding-mismatch`.

> Rationale: content addressing is only meaningful if all parties agree
> bit-exactly on the encoding. Permitting multiple encodings within one context
> reintroduces the canonicalization ambiguity that content addressing exists to
> remove. {{RFC8785}} and the deterministic profile of {{RFC8949}} are examples
> of encodings that can satisfy these requirements; this document endorses
> neither.

### Extensibility {#extensibility}

Core objects use **must-understand** semantics. A verifier that encounters an
element it does not recognize in a core object MUST reject the object with
`unknown-element`, and MUST NOT ignore it and proceed.

Extension is available only at designated extension points, which are:
`operation`, `evidence`, `authority.model_data`, and profile-designated
elements. Extension content at these points MUST be identified by a registered
identifier and MUST be treated as opaque by a verifier that does not recognize
it, contributing nothing to any assurance dimension.

> Rationale: permissive extension is incompatible with content-addressed
> identifiers. If two implementations disagree about which elements are
> significant, they disagree about identity.

### Identifiers {#object-ids}

Object identifiers are derived from content:

~~~
object_id = H( DS(object_type)
               || canonical_encoding(object minus signature) )
~~~

where `H` is the digest algorithm declared by the context and `DS` is the
encoding profile's domain separation for the object type.

Signatures are computed over `object_id`, not included in it. This permits an
object to carry multiple independent signatures — countersignature, notarial
attestation, multi-party recording — without changing its identity.

Identifiers MUST be self-describing with respect to the digest algorithm used
({{RFC6920}} provides one such convention). A verifier MUST recompute every
identifier it relies on and MUST report `identifier-mismatch` on discrepancy.

Resource identifiers ({{resource}}) are the sole exception: a resource
identifier is stable across the resource's entire history and is therefore
assigned at creation rather than derived from mutable content.

### Digest Agility {#agility}

Every commitment and identifier MUST carry an explicit algorithm identifier. A
verifier MUST evaluate algorithm acceptability against its own policy and MUST
report `weak-algorithm` for commitments computed under an algorithm its policy
deprecates, without necessarily rejecting the object.

Deployments intended for long-lived records SHOULD periodically re-anchor
existing checkpoints under a stronger algorithm and record the re-anchoring as
a transition of structural class `import` ({{structural}}), so that the
migration is itself part of the verifiable history rather than an unrecorded
substitution.

### Post-Quantum Cryptography {#post-quantum}

VSTP records are intended to remain verifiable beyond the useful lifetime of
classical public-key cryptography. Every conforming profile therefore MUST use
a post-quantum digital signature algorithm standardized by a recognized
standards body. A profile MUST NOT define a classical-only conformance mode.
ML-DSA as standardized in {{FIPS204}} is one qualifying family.

A profile MAY use a hybrid signature construction only when its post-quantum
component independently authenticates the complete signed input and successful
verification requires that component. Failure of the classical component MUST
NOT reduce the security of the post-quantum component or enable acceptance
without it.

Digest algorithms used for identifiers, commitments, and accumulators MUST
target at least 128 bits of security against known generic quantum collision
and preimage attacks. Algorithm agility MUST NOT permit a verifier to silently
downgrade below this floor. A verifier MUST reject an object that relies on a
classical-only signature or a digest below this floor and report
`non-post-quantum-algorithm`; reporting `weak-algorithm` without rejection is
insufficient in this case.

### Time {#time}

Any time value asserted by a recorder is an epistemic `declaration`
({{epistemic}}) and MUST be treated as such. A verifier MUST NOT report the
`existence-time` assurance dimension above `not-established` on the basis of a
recorder-declared time alone.

Evidence of existence time comes only from receipts ({{receipt}}) issued by
parties distinct from the recorder — for example timestamping under
{{RFC3161}}, inclusion in a transparency log ({{RFC9162}}, {{SCITT-ARCH}}), or
finality in an external settlement system.

## Context {#context}

A context is the boundary within which resource identity is unique, recorder
sequence is meaningful, and an authority policy applies.

| Element | Req. | Description |
|---|---|---|
| `protocol_version` | MUST | Version of this specification. |
| `context_id` | MUST | Derived identifier ({{object-ids}}). |
| `controller` | MUST | Principal responsible for the context. |
| `scope` | MUST | Declarative statement of what the context covers. |
| `recorder_principals` | MUST | Principals permitted to issue transitions. MAY be open-ended, in which case this is stated explicitly. |
| `encoding_profile` | MUST | Registered encoding profile identifier ({{encoding}}). |
| `digest_algorithm` | MUST | Algorithm for identifiers and commitments. |
| `authority_model` | MUST | Registered identifier of the authority model in force ({{authority}}). |
| `authority_policy_commitment` | MUST | Commitment to the policy governing the context. |
| `mediation` | MUST | Mediation declaration ({{completeness}}). |
| `disclosure_policy` | MUST | Declared disclosure and erasure model ({{disclosure}}). |
| `genesis_nonce` | MUST | Unpredictable value binding the context, preventing replay of transitions into another context. |
| `created` | MUST | Declared creation time (a `declaration`). |
| `domain_profiles` | MAY | Registered profile identifiers in use. |
| `signature` | MUST | Signature by `controller`. |

Every other object MUST bind to exactly one `context_id`. A verifier MUST
report `context-mismatch` where an object references a context whose declared
constraints it violates, and `context-unavailable` where the referenced context
object is not present in the bundle.

A context is immutable. Changing any element requires a new context; continuity
between contexts is expressed by an `import` transition ({{structural}}) that
commits to the prior context and its final checkpoint.

## Resource {#resource}

A resource descriptor establishes a stable logical identity.

| Element | Req. | Description |
|---|---|---|
| `resource_id` | MUST | Stable identifier, unique within the context. |
| `context_id` | MUST | Owning context. |
| `resource_type` | MUST | Registered or profile-defined type identifier. |
| `genesis_transition` | MUST | Identifier of the transition that created the resource, or an `import` transition where the resource predates the context. |
| `labels` | MAY | Mutable, non-identifying names. Explicitly not identity. |
| `signature` | MUST | Signature by the issuing recorder. |

A resource identifier MUST NOT be derived from, or required to correspond to,
any mutable property of the resource: not a filesystem path, URL, database key,
display name, storage location, or content digest. Such properties MAY appear
in `labels`, and a verifier MUST NOT use `labels` in any identity comparison.

> Rationale: identity derived from location breaks under the ordinary
> operations these systems exist to record — rename, move, copy, export,
> migration. Identity derived from content makes every modification a new
> resource, which discards exactly the continuity being recorded.

## State Commitment {#state-commitment}

A state commitment binds a representation of a resource's state.

| Element | Req. | Description |
|---|---|---|
| `resource_id` | MUST | The resource whose state is committed. |
| `representation_profile` | MUST | Registered identifier of the interpretation under which the digest was computed. |
| `profile_version` | MUST | Version of that representation profile. |
| `algorithm` | MUST | Digest or commitment algorithm. |
| `digest` | MUST | The commitment value. |
| `canonicalization_parameters` | MUST where the profile is parameterized | The parameter values used, so the computation is reproducible. |
| `salt_commitment` | MAY | Present where the commitment is hiding ({{erasure}}). |
| `byte_length` | MAY | Length of the committed representation. |
| `media_type` | MAY | Advisory type of the representation. |
| `external_references` | MAY | Locators for the committed representation. Advisory only; never identity. |

`representation_profile` is normative and load-bearing. A digest of raw octets
and a digest of a normalized structural form of the same state are different
claims about different things, and neither implies the other. Examples of
distinct profiles include raw octet sequences, Merkle roots over chunked
content, canonicalized structural document models, directory or collection
trees, database state roots, and manifest roots over composite works.

A verifier MUST NOT compare two state commitments for equality unless their
`representation_profile`, `profile_version`, `algorithm`, and
`canonicalization_parameters` are all identical, and MUST report
`representation-mismatch` where a continuity check ({{continuity}}) requires
comparing commitments that differ in any of them.

This specification does not define any representation profile. Profiles are
registered ({{iana}}) and MUST specify their normalization rules completely
enough that two independent implementations produce identical commitments for
the same state.

## Transition {#transition}

The transition is the central object.

| Element | Req. | Description |
|---|---|---|
| `protocol_version` | MUST | Version of this specification. |
| `context_id` | MUST | Owning context. |
| `transition_id` | MUST | Derived identifier ({{object-ids}}). |
| `structural_class` | MUST | Registered structural class ({{structural}}). |
| `parents` | MUST | Identifiers of parent transitions. Empty only for `genesis` and `import`. |
| `prior_states` | MUST | State commitments before the transition. Empty only for `genesis`. |
| `resulting_states` | MUST | State commitments after the transition. Empty only for `terminate` and `revoke`. |
| `actor` | MUST | Principal on whose behalf the transition occurred. MAY be the recorder. |
| `instrument` | MUST | Principal identifying the software or service through which the act occurred. |
| `agent` | MAY | Autonomous agent principal, where the act was performed by one. |
| `device` | MAY | Device or execution environment principal. |
| `recorder` | MUST | Principal issuing this record. |
| `authority` | MUST | Authority element ({{authority}}). |
| `operation` | MAY | Semantic operation element ({{operation}}). |
| `approval` | MUST for class `approve` | Approval element ({{approval}}). |
| `sequence` | MUST | Monotonic counter scoped to (`context_id`, `recorder`). |
| `declared_time` | MAY | Recorder's asserted time (a `declaration`). |
| `evidence` | MAY | References to supporting evidence objects. |
| `signature` | MUST | At least one signature; at minimum by `recorder`. |

`actor`, `instrument`, `agent`, `device`, and `recorder` are distinct roles and
MUST NOT be collapsed. A human, an application, an autonomous agent, an
execution environment, and the party recording the claim are different
entities, may be under different control, and warrant different assurance
treatment. A single principal MAY occupy several roles; where it does, that
fact is itself information a verifier reports rather than hides.

The signature establishes who issued the claim. It establishes nothing about
the identity of `actor` beyond the recorder's assertion. Binding a principal to
a real-world identity requires credential evidence and is reported on a
separate assurance dimension ({{dimensions}}).

### Structural Classes {#structural}

The structural class determines how a verifier interprets the transition's
place in the graph. It is distinct from, and orthogonal to, the semantic
`operation` ({{operation}}). Structural classes are a closed registry with a
high change bar ({{iana}}); semantic operations are open.

| Class | Meaning | Constraints |
|---|---|---|
| `genesis` | Creates a resource. | `parents` empty; `prior_states` empty. |
| `update` | Transforms a resource's state. | Exactly one resource in both `prior_states` and `resulting_states`. |
| `derive` | Produces a new resource from one or more sources. | `resulting_states` contains at least one resource absent from `prior_states`. |
| `merge` | Converges two or more parents. | `parents` has cardinality ≥ 2; `prior_states` covers each parent's resulting state for the affected resources. |
| `fork` | Declares intentional divergence. | Sibling transitions sharing a parent are permitted without this class; `fork` records that the divergence is deliberate. |
| `approve` | Records approval of a referenced or proposed transition. | `approval` element required. |
| `supersede` | Declares that a prior transition's semantics are replaced. | Does not remove the superseded transition. |
| `revoke` | Withdraws a previously issued claim. | Does not erase; see {{erasure}}. |
| `discontinuity` | Declares an observed state change the recorder did not record as a transition. | See {{continuity}}. |
| `import` | Introduces a state commitment or history attested by a system outside this context. | Evidence element required. |
| `terminate` | Declares the end of recording for a resource in this context. | `resulting_states` empty for that resource. |

VSTP deliberately does not define separate top-level object types for
approvals, derivations, releases, or revocations. These are transitions over
resources, differing in structural class and operation profile. A release is an
`update` or `derive` under a release operation profile; an approval is an
`approve` transition over the proposal it approves. Collapsing them into one
object is what makes the graph uniformly traversable.

### Semantic Operation {#operation}

The `operation` element carries domain semantics. It is optional, and the
protocol's core guarantees do not depend on it.

| Element | Req. | Description |
|---|---|---|
| `profile` | MUST | Registered operation profile identifier. |
| `commitment` | MUST | Commitment to the operation description. |
| `disclosure` | MAY | The operation description itself, where disclosed. |

An operation description MAY be fully disclosed, selectively disclosed,
encrypted, committed and withheld, or omitted entirely. The core proof —
binding prior state to resulting state under attributed authority — remains
valid in every case.

VSTP does not define a diff, patch, or change-description format, and MUST NOT
be extended to require one. The same octet-level change may constitute entirely
different acts — a substantive revision, a metadata update, an automatic save,
a re-render, a regeneration — and no universal representation distinguishes
them. Distinguishing them is the business of a domain profile that understands
the domain.

Where an operation description is disclosed, a verifier MUST verify it against
`commitment` and MUST report `operation-mismatch` on discrepancy. A verifier
MUST NOT treat a disclosed operation description as established fact: it
remains a `declaration` by the recorder about the meaning of a change, and
contributes only to the `semantic-fidelity` dimension, which this protocol
cannot raise above `declared` on its own.

### Approval {#approval}

Where `structural_class` is `approve`, the `approval` element is required.

| Element | Req. | Description |
|---|---|---|
| `subject` | MUST | Identifier of the approved transition, or a commitment to a proposed transition not yet issued. |
| `approver` | MUST | Principal granting approval. |
| `presentation_commitment` | MUST | Commitment to the exact rendering presented to the approver. |
| `material_terms` | MUST | Commitment to the consequential parameters of the subject act. |
| `policy_version` | MUST | The policy under which approval was solicited. |
| `presence_method` | MUST | How approver presence was established. |
| `proposal_origin` | MUST | One of `human`, `machine`, `machine_assisted`. |
| `requested_time` | MAY | Declared. |
| `approved_time` | MAY | Declared. |
| `expiry` | MAY | After which approval is void. |
| `conditions` | MAY | Conditions attached to the approval. |

`presentation_commitment` is required because approval of a proposal is
meaningless without a record of what was actually shown. An approval that binds
only the canonical proposal, not its rendering, cannot distinguish a correct
approval from one obtained by displaying something else.

The following five states MUST remain distinguishable in a conforming record
and MUST NOT be reported as equivalent:

1. a proposal was generated (possibly by a machine);
2. a proposal was presented to a human;
3. a human approved the exact presented proposal;
4. policy authorized the proposal;
5. the transition took effect.

`proposal_origin` is mandatory because the accountability question "did a person
originate this, or ratify something a machine originated?" is not recoverable
after the fact and is precisely the question asked in review.

## Checkpoint {#checkpoint}

A checkpoint commits to a set of transitions, permitting efficient anchoring
and receipt acquisition without disclosing individual transitions.

| Element | Req. | Description |
|---|---|---|
| `context_id` | MUST | Owning context. |
| `checkpoint_id` | MUST | Derived identifier. |
| `previous_checkpoint` | MUST | Identifier of the prior checkpoint, or explicit null for the first. |
| `transition_set_root` | MUST | Accumulator root over the committed transitions. |
| `state_root` | MUST | Accumulator root over current state commitments per resource. |
| `sequence_range` | MUST | Range of recorder sequences covered. |
| `recorder` | MUST | Issuing principal. |
| `mediation` | MUST | Mediation declaration in force over this range ({{completeness}}). |
| `signature` | MUST | Signature by `recorder`. |

The accumulator construction is not specified here; an encoding profile
determines it. It MUST support inclusion proofs for individual transitions
without disclosure of others, and MUST support proofs of non-inclusion or be
declared as not supporting them.

Checkpoints chain: omitting an intermediate checkpoint from a published chain
is detectable, and a verifier MUST report `checkpoint-chain-gap` where
`previous_checkpoint` references an absent checkpoint that the bundle claims to
be complete over.

## Receipt {#receipt}

A receipt carries evidence issued by a party other than the recorder.

| Element | Req. | Description |
|---|---|---|
| `subject` | MUST | Identifier of the checkpoint or transition concerned. |
| `receipt_type` | MUST | Registered receipt type. |
| `issuer` | MUST | Issuing principal, which MUST NOT be the recorder of the subject. |
| `observed_time` | MAY | Time asserted by the issuer. |
| `proof` | MUST | Inclusion, timestamp, or finality proof as required by the type. |
| `signature` | MUST | Signature by `issuer`. |

Initial receipt types ({{iana}}): `witness-observation`, `transparency-inclusion`,
`timestamp`, `finality`, `monotonic-counter`, `deletion`.

A `deletion` receipt attests that an identified repository destroyed data it
controlled. It attests nothing about copies outside that repository's control
({{erasure}}).

Each receipt type contributes to specific assurance dimensions and to no
others. A transparency inclusion receipt contributes to `existence-time` and
`ordering`; it does not contribute to `authority`, `record-integrity` beyond
the registered digest, or `semantic-fidelity`. A verifier MUST NOT propagate a
receipt's assurance beyond its registered dimensions.

Where `issuer` equals the recorder of the subject, the object is not a receipt;
a verifier MUST reject it with `self-issued-receipt`. Independence of the
issuer is the entire content of the evidence.


# Authority {#authority}

This section carries the requirement that distinguishes VSTP from provenance
and transparency protocols generally. A transition that records who acted but
not why they were permitted to act records half of what an auditor, regulator,
or counterparty needs.

## The Authority Element {#authority-element}

| Element | Req. | Description |
|---|---|---|
| `model` | MUST | Registered authority model identifier. |
| `chain_commitment` | MUST | Commitment to the delegation chain relied upon. |
| `chain_disclosure` | MAY | The chain itself, where disclosed. |
| `policy_commitment` | MUST | Commitment to the policy body evaluated. |
| `policy_disclosure` | MAY | The policy body, where disclosed. |
| `decision` | MUST | Decision element ({{decision}}). |
| `model_data` | MAY | Model-specific extension content. |

Where a transition occurred without any authority evaluation — which is a valid
and common situation, for example a recorder observing changes in a system it
does not control — `decision.result` MUST be `not-evaluated` and `model` MUST
be the registered null authority model. Recording the absence of an
authorization decision is required; omitting the element is not permitted.

> Rationale: an optional authority element becomes an absent authority element,
> and a protocol in which authority is usually absent provides no basis for a
> verifier to distinguish "not authorized" from "authorization not recorded".
> The mandatory null model makes the absence explicit and machine-checkable.

## Requirements on Authority Models {#authority-models}

VSTP does not define a capability format, delegation syntax, or policy
language. Any authority model registered for use with VSTP MUST satisfy the
following, and a registration that does not is not conforming:

1. **Decidable scope containment.** The model MUST define a total, decidable
   relation determining whether one authority scope is contained within
   another. Without this, a verifier cannot check delegation.

2. **Non-amplification.** The model MUST NOT permit a delegation step to convey
   authority the delegator did not hold. Every step MUST be attenuating or
   scope-preserving. A verifier MUST check each step and report
   `authority-amplification` on violation.

3. **Explicit scope over resources and structural classes.** An authority scope
   MUST be expressible over the resources affected and the structural classes
   permitted, so that a verifier can check that the authority relied upon
   actually covers the transition presented.

4. **Revocation semantics.** The model MUST define whether authority is
   evaluated as of the time of the transition or the time of verification, and
   MUST define how revocation of an intermediate delegation affects transitions
   already recorded under it. A verifier MUST report the applicable semantics
   in its output rather than choosing one.

5. **Independent evaluability.** Given the disclosed chain and the policy body
   matching `policy_commitment`, an independent verifier MUST be able to
   evaluate the model without access to the recorder, the issuer, or any online
   service. Models requiring an online authorization service MAY be registered
   but MUST declare themselves non-independently-evaluable, which caps the
   `authority` assurance dimension at `asserted`.

## The Decision Element {#decision}

| Element | Req. | Description |
|---|---|---|
| `result` | MUST | One of `permit`, `deny`, `not-evaluated`. |
| `evaluator` | MUST for `permit`/`deny` | Principal that performed the evaluation. |
| `inputs_commitment` | MUST for `permit`/`deny` | Commitment to the complete input set to the evaluation. |
| `decision_commitment` | MUST for `permit`/`deny` | Commitment to the full decision output. |
| `reproducible` | MUST | Boolean: whether the evaluator asserts the decision is deterministically reproducible from `policy_commitment` and `inputs_commitment`. |

## Reproducibility {#reproducibility}

This is the sharp requirement.

A decision MAY be marked `reproducible` only if all of the following hold:

1. the policy identified by `policy_commitment` is a deterministic function of
   its inputs;
2. `inputs_commitment` commits to the complete input set — every value the
   evaluation consulted, including time, external inputs, and credential
   states, with no implicit dependence on evaluator-local state;
3. re-evaluating the policy over those inputs yields exactly the value
   committed in `decision_commitment`.

A verifier that possesses the policy body and the inputs MUST attempt
re-evaluation and MUST report the `policy-reproduction` dimension as
`reproduced`, `contradicted`, or `not-attempted`. A `contradicted` result is a
strong negative finding: it establishes that the recorded decision is not the
decision the stated policy produces, and a verifier MUST NOT treat it as a
minor inconsistency.

A decision not marked `reproducible` is an epistemic `declaration`, not a
`decision` ({{epistemic}}), and a verifier MUST type it accordingly. This is
the mechanism by which VSTP prevents a system from claiming policy-based
authorization while retaining the ability to have decided anything at all.

Where the policy body is not disclosed, a deployment MAY supply a proof that
the committed decision is the correct evaluation of the committed policy over
the committed inputs, without disclosing the policy. Such a proof is carried as
evidence; its verification permits `policy-reproduction` to be reported as
`proved` rather than `not-attempted`. This specification does not mandate or
define any proof system.


# Epistemic Typing {#epistemic}

Every assertion carried in a VSTP graph has an epistemic type. Types are
assigned by the verifier from the structure and evidence, not chosen freely by
the recorder, and MUST NOT be silently upgraded.

| Type | Meaning |
|---|---|
| `fact` | Directly verified by the protocol from the object itself — for example that a signature is valid over a given identifier. |
| `attestation` | Asserted and signed by a named issuer distinct from the subject. |
| `observation` | Reported by a device, service, witness, or external monitor about something it perceived. |
| `declaration` | Claimed by a principal about itself or its own acts. |
| `inference` | Derived by software or a model from other data. |
| `decision` | Output of an identified policy, reproducible under {{reproducibility}}. |
| `effect` | A state transition that reached a terminal state in an external system, evidenced by a finality receipt. |

The rules that give this typing force:

- A verifier MUST assign the *weakest* type consistent with available evidence.
- A verifier MUST NOT upgrade a type on the basis of the assertion's own claim
  about its type.
- A recorder-declared time is a `declaration` regardless of precision.
- A watcher-derived transition — one inferred from observed state differences
  rather than declared by the acting instrument — is an `observation`, and
  where the operation semantics were reconstructed rather than reported, those
  semantics are an `inference`.
- An instrument-declared transition — one emitted by the acting software about
  its own act — is a `declaration`, upgraded to `attestation` for the
  instrument's identity only where publisher attestation evidence is present.

The practical consequence, which implementations frequently resist: a system
that watches for changes and records them produces observations and inferences,
not declarations, and its records are weaker in a specific, reportable way than
records emitted by the software that performed the act. Both are valid. Only
one may be represented as the actor's own account of what it did.


# Recording Completeness {#completeness}

## The Asymmetry {#asymmetry}

The central limitation of every hash-chained history, stated normatively
because it is otherwise stated nowhere and assumed away everywhere:

> A chain of committed transitions proves that recorded transitions were not
> altered after recording. It does not, by itself, prove that no unrecorded
> transition occurred.

Integrity and completeness are independent properties. A perfectly intact
record set may be arbitrarily incomplete. Systems in this space routinely
present integrity evidence in language that implies completeness, and users
reasonably read "verified history" as "the history".

VSTP addresses this in three ways: a mandatory mediation declaration
({{mediation}}), a mandatory continuity check that detects many completeness
violations ({{continuity}}), and a verifier prohibition on overstating either
({{completeness-verifier}}).

## Mediation Declaration {#mediation}

Every context and every checkpoint MUST carry a mediation declaration. The
declaration is structured rather than a bare level, because the level alone
tells a verifier what the recorder claims but not where the claim stops
holding.

| Element | Req. | Description |
|---|---|---|
| `level` | MUST | Registered mediation level, below. |
| `boundary` | MUST | The boundary within which the level is claimed, expressed over resources and paths. |
| `observation_method` | MUST | How the recorder learned of state changes. |
| `bypass_paths` | MUST | Enumerated ways a state change could occur without producing a transition. MAY be empty only where `level` is `enforced`. |
| `limitations` | MUST | Known weaknesses of the recording, such as coalesced ordering or unobserved intermediate states. MAY be empty. |
| `enforcement_evidence` | MUST for `mediated` and `enforced` | Evidence, independent of the recorder's own assertion, supporting the claimed level. |

`bypass_paths` and `limitations` are mandatory and MUST be enumerated to the
best of the recorder's knowledge. A declaration listing no bypass paths at a
level below `enforced` is a claim that none exist, and a verifier SHOULD treat
an empty `bypass_paths` at `observational` or `asserted` as an unsupported
completeness assertion.

> Rationale: a verifier that reports `observational` has told the reader
> almost nothing. A verifier that reports `observational`, observed via a
> named change-notification mechanism, bypassable by changes occurring before
> recorder startup, by state held only in application memory, and by storage
> paths the mechanism does not report, with ordering subject to coalescing,
> has told the reader exactly what the record does and does not cover. The
> second is the output this protocol exists to produce.

| Level | Meaning |
|---|---|
| `unknown` | No claim is made about completeness. |
| `observational` | The recorder observed state changes after they occurred. Unrecorded transitions are possible and may be undetectable. |
| `asserted` | The acting instrument asserts it emitted a transition for every state change, without independent evidence of that property. |
| `mediated` | Every state-changing path verifiably passed through the recorder, evidenced independently of the recorder's own assertion. |
| `enforced` | Mediation is enforced by a mechanism that attests to its own enforcement, such that circumvention is detectable by the verifier. |

A verifier MUST downgrade a claimed level to `asserted` where `mediated` or
`enforced` is claimed without accompanying evidence, and MUST report
`mediation-unsupported`.

Mediation levels are not a maturity ladder to be climbed silently. A deployment
operating at `observational` is a legitimate deployment; what is not legitimate
is presenting its output as though it were `mediated`.

## State Continuity {#continuity}

Continuity checking is the mechanism by which VSTP detects, rather than merely
disclaims, a class of unrecorded transitions.

For each resource, along each path in the graph, a verifier MUST check that a
transition's `prior_states` entry for that resource equals the `resulting_states`
entry for that resource in the parent transition, compared under identical
`representation_profile` and `algorithm`.

Where this equality fails, a state change occurred that the recorder did not
record as a transition. The verifier MUST report `state-discontinuity`,
identifying the resource and the two transitions between which the unrecorded
change occurred.

This is a positive capability and is worth stating plainly: an `observational`
recorder cannot prove completeness, but wherever it re-observes a resource it
*detects* out-of-band modification. The window of undetectability is bounded by
the observation interval, not unbounded.

A recorder that becomes aware of an unrecorded change SHOULD record it honestly
using structural class `discontinuity`, declaring the prior and resulting state
commitments it observed and asserting nothing about what occurred between them.
A declared discontinuity is not a verification failure; it is the recorder
correctly reporting the limit of its knowledge. A verifier MUST distinguish a
declared discontinuity from an undeclared one, and MUST report the latter more
severely.

## Verifier Obligations {#completeness-verifier}

A conforming verifier:

- MUST include a `recording-mediation` dimension in every assurance vector;
- MUST report `unknown` where no supported mediation claim is present;
- MUST NOT use the terms "complete", "full", "entire", or equivalent
  formulations about a history unless the mediation level is `mediated` or
  `enforced` over the relevant scope and is supported by evidence;
- MUST report the observation interval or checkpoint cadence, where derivable,
  since it bounds the undetectability window;
- MUST report `disclosure-completeness` separately ({{dimensions}}), because a
  fully mediated history may still be only partially disclosed to this
  verifier.


# Verification {#verification}

## Procedure {#procedure}

A conforming verifier, given a bundle and a verification policy, MUST perform
the following. Steps are ordered; a step that produces a fatal finding MAY
terminate processing of the affected object but MUST NOT suppress findings
already produced.

1. **Syntactic validation.** Decode under the context's declared encoding
   profile. Enforce bounds. Reject unknown elements in core objects
   ({{extensibility}}).
2. **Re-encoding check.** Re-encode each object and confirm octet equality with
   the received form. Failure indicates encoding non-determinism or
   manipulation; report `non-canonical-encoding`.
3. **Identifier recomputation.** Recompute every identifier ({{object-ids}}).
4. **Signature verification.** Verify every signature against its declared
   principal. Report `unresolved-principal` where a key cannot be resolved
   under the verification policy — this is distinct from an invalid signature
   and MUST NOT be reported as one.
5. **Context binding.** Confirm every object binds to a context present in the
   bundle and satisfies its declared constraints.
6. **Graph construction.** Resolve parent references. Distinguish three cases
   and report them distinctly: parent present; parent *withheld* under a
   declared disclosure policy; parent *missing* without declaration.
7. **Structural validation.** Enforce the constraints of each transition's
   structural class ({{structural}}).
8. **Continuity checking.** Perform the checks of {{continuity}}.
9. **Sequence and equivocation checking.** {{equivocation}}.
10. **Authority evaluation.** Check scope containment and non-amplification
    across each delegation chain; attempt policy reproduction
    ({{reproducibility}}).
11. **Evidence evaluation.** Verify receipts, confirm issuer independence, and
    attribute each to its registered dimensions only.
12. **Epistemic typing.** Assign types under {{epistemic}}.
13. **Assurance vector construction.** {{dimensions}}.

## Equivocation {#equivocation}

Two transitions bearing the same `context_id`, `recorder`, and `sequence` but
differing `transition_id`, each validly signed, constitute equivocation by that
recorder.

A verifier presented with both MUST report `equivocation`, MUST identify the
conflicting transitions, and MUST NOT select between them. Equivocation is a
finding about the recorder, not about the transitions, and it degrades every
assurance dimension that depends on that recorder.

Signatures alone cannot prevent equivocation, because a signer can sign two
conflicting histories and present each to a different party. Detection requires
that the parties compare, which requires evidence from a shared external
observer: a witness, transparency log, or settlement system. This is the
principal reason receipts ({{receipt}}) exist in this protocol, and a
deployment without any receipt source cannot detect equivocation at all. A
verifier MUST report `equivocation-detection: unavailable` in that case rather
than reporting that no equivocation was found.

## Merge and Preserved Conflict {#merge-conflict}

A `merge` transition MUST declare all converged parents and the prior state
commitments corresponding to each. Where the merge does not fully reconcile the
converged states, the residual disagreement MUST be recorded — as unreconciled
resources retaining divergent state commitments, or via an operation profile
that represents the conflict explicitly.

A verifier MUST NOT treat a merge as evidence that the merged parties agreed. A
merge records that a party declared a convergence under its own authority.
Where parents originate from different recorders under different authority, a
verifier MUST report the merge's authority basis for each parent separately.

## Assurance Vector {#dimensions}

Verification output is a vector of per-dimension conclusions. It is not a
boolean and MUST NOT be reduced to one except under {{summarization}}.

Initial dimensions ({{iana}}):

| Dimension | Establishes |
|---|---|
| `record-integrity` | Objects are internally consistent and unmodified since signing. |
| `graph-continuity` | State commitments chain without undeclared discontinuity. |
| `attribution` | Which principals signed which claims. |
| `principal-identity` | Binding of a principal to an externally asserted identity. |
| `instrument-identity` | Binding of the acting software or agent to an attested identity. |
| `authority` | The acting principal held authority covering this transition. |
| `policy-reproduction` | The recorded decision is the decision the stated policy yields. |
| `human-approval` | A human approved the exact presented proposal. |
| `existence-time` | The record existed no later than an externally evidenced time. |
| `ordering` | The relative order of records is externally evidenced. |
| `finality` | A commitment reached a terminal state in an external system. |
| `effect-confirmation` | The declared resulting state corresponds to the state an external system actually holds ({{effects}}). |
| `recording-mediation` | The degree to which unrecorded transitions are excluded ({{completeness}}). |
| `disclosure-completeness` | How much of the relevant graph was disclosed to this verifier. |
| `semantic-fidelity` | Whether declared operation semantics correspond to the actual change. |
| `intent-fidelity` | Whether an executed act corresponds to what a principal expressed. |

Each dimension carries a conclusion drawn from a common scale —
`not-established`, `declared`, `observed`, `attested`, `verified`,
`contradicted` — together with the evidence identifiers that support it.

Three dimensions warrant specific note. `semantic-fidelity` cannot exceed
`declared` on the basis of VSTP structure alone; raising it requires
domain-specific evidence supplied by a profile. `intent-fidelity` is
`not-established` by default: the protocol can establish what was expressed,
how software interpreted it, what was presented, what was authorized, and what
executed, and it cannot establish that these corresponded to a person's
internal intention. A profile that preserves the intent transformation chain
({{constructions}}) MAY raise it, on the basis that each transformation is
separately committed and inspectable — never on the basis that a person's
meaning was captured. Implementations MUST NOT report `intent-fidelity` above
`declared` without evidence registered for that purpose.

## Declared and Confirmed Effects {#effects}

A transition's `resulting_states` are commitments asserted by the recorder.
Where the act had an effect in a system outside the recorder's control — a
payment, a deployment, a write to a system of record, a message dispatched —
the assertion that the external system now holds that state is a
`declaration` until something independent says otherwise.

Three situations are routinely conflated and MUST be reported distinctly:

| Situation | Evidence | Reported as |
|---|---|---|
| The recorder declares the resulting state. | none | `declared` |
| The act was accepted for execution by the external system. | acknowledgement from that system | `observed` |
| A commitment reached a terminal state in the external system. | `finality` receipt | `attested` |
| An independent party observed the external system and its state commitment matches `resulting_states`. | receipt or attestation over the observed state, under an identical representation profile | `verified` |

The distinction between the third and fourth rows is the one most often lost. A
finality receipt establishes that *a commitment* reached a terminal state in a
system. It does not establish that the state the recorder declared is the state
that system now holds, unless the receipt commits to that state under a
representation profile the verifier can compare against ({{state-commitment}}).

A verifier MUST NOT raise `effect-confirmation` above `attested` on the basis
of a finality receipt alone, and MUST report `effect-confirmation: declared`
where a transition asserts an external effect with no supporting evidence.
Profiles covering acts with external effects SHOULD require confirmation
evidence and SHOULD state the threshold in their assurance policy
({{summarization}}).

## Summarization {#summarization}

An assurance vector is correct and, presented raw, frequently unusable. Human
reviewers need a decision. The resolution is not to suppress the vector but to
make the threshold attributable.

A conforming implementation:

- MUST make the complete assurance vector available in its output;
- MAY additionally emit a single summary conclusion **only** when that summary
  is computed by a named, versioned, published assurance policy;
- MUST include the assurance policy's identifier and publisher alongside any
  summary;
- MUST attribute the summary to that publisher and MUST NOT present it as a
  conclusion of this protocol;
- MUST NOT present any summary using an unqualified term such as "verified",
  "authentic", or "trusted" without the dimension qualification or policy
  attribution that produced it.

A domain profile ({{profiles}}) is the natural publisher of an assurance
policy, since the profile already establishes what its domain requires. A
profile SHOULD define at least one assurance policy stating the per-dimension
thresholds for acceptance in that domain — for example requiring authority
established, policy reproduced, approval bound to the exact presented proposal,
and mediation at or above a stated level.

The effect is that the question "what is good enough?" is answered by an
identifiable party who can be held to that answer, rather than by an
implementation detail of a verifier. A conforming implementation therefore
reports *accepted under a named policy*, never *trustworthy*.

## Output {#output}

Verifier output MUST be structured and language-neutral, comprising: the
assurance vector; the findings, each carrying a registered failure or
observation code ({{iana}}); the identifiers of objects and evidence relied
upon; the verification policy identifier; and the verifier's own version.

Output MUST be expressible without reference to any originating application,
service, or account. A bundle that can only be interpreted by the system that
produced it is not a portable record.

Output MUST NOT assert the truth of claims inside a verified structure. The
correct form is of the shape: *this bundle existed in this form, signed by these
principals, containing these attestations, under this authority, with these
dimensions established and these not.*


# Disclosure, Redaction, and Erasure {#disclosure}

## Disclosure Policy {#disclosure-policy}

Every context declares a disclosure policy. It is a structured element, because
a verifier must be able to distinguish a deliberately withheld element from a
missing one without consulting the recorder.

| Element | Req. | Description |
|---|---|---|
| `public_elements` | MUST | Elements disclosed to any holder of the bundle. |
| `selectively_disclosable_elements` | MUST | Elements openable individually against the same commitment. MAY be empty. |
| `commitment_only_elements` | MUST | Elements committed and never opened. MAY be empty. |
| `encrypted_elements` | MUST | Elements carried encrypted, with the key management model stated. MAY be empty. |
| `retention_class` | MUST | Declared retention obligation and duration. |
| `erasure_model` | MUST | Which construction of {{erasure}} applies to which elements, or an explicit declaration that no erasure is supported. |
| `unlinkability_mode` | MUST | Whether principal identifiers are global, context-scoped, or pairwise ({{leakage}}). |
| `supersession_policy` | MUST | How `revoke` and `supersede` transitions are to be interpreted by consumers. |

A verifier MUST use the disclosure policy to classify absent elements, and MUST
report `withheld` rather than `missing` for elements the policy declares as
`commitment_only_elements` or `encrypted_elements`.

## Commitment-Only References {#commitment-only}

VSTP core objects MUST NOT require the plaintext of resource content. All
resource content is referenced by commitment. A bundle may therefore be
verified for integrity, continuity, attribution, and authority while disclosing
no content at all.

A verifier MUST distinguish `withheld` from `missing` and MUST NOT report
withheld content as a defect. A declared disclosure policy that withholds a
subgraph reduces `disclosure-completeness`; it does not reduce
`record-integrity`.

## Selective Disclosure {#selective}

Deployments requiring partial disclosure SHOULD structure commitments so that
individual elements can be opened independently. Where this is done, opened
elements MUST be verifiable against the same commitment relied upon by parties
who received nothing.

The protocol does not mandate a selective disclosure construction. It requires
that any construction used be declared in the context's `disclosure_policy` and
be verifiable offline.

## Erasure {#erasure}

Revocation and erasure are different operations with different legal
consequences, and conflating them is a design error with regulatory
consequences.

A `revoke` transition withdraws a claim. It does not remove data. Where records
are published to append-only or widely replicated media, a `revoke` transition
provides no erasure whatsoever.

Deployments subject to erasure obligations MUST use **erasure-tolerant
construction** for any element that may require erasure:

1. the element MUST be committed using a hiding commitment with an
   independently stored opening (for example, a high-entropy salt);
2. the opening MUST be stored separately from the commitment, under a retention
   policy permitting its destruction;
3. destruction of the opening MUST render the element unrecoverable while
   leaving every commitment, identifier, signature, and graph relationship
   intact and verifiable.

A verifier encountering a commitment whose opening is unavailable MUST report
the element as `erased` or `withheld` — the distinction being whether erasure
was declared — and MUST NOT report the containing object as invalid.

Personal data, and data subject to any erasure obligation, MUST NOT be placed
in elements that are inputs to identifiers or to commitments that are published
without erasure-tolerant construction. A profile MUST state, for every element
it defines, whether that element may carry personal data and which construction
applies.

Every profile MUST declare its retention and erasure model explicitly.
"Immutable" is a design choice with legal consequences and MUST be stated as
such rather than assumed.

## Metadata Leakage {#leakage}

A graph whose payloads are entirely withheld still discloses substantial
information: the number of transitions, their timing and cadence, the identity
and recurrence of principals, the branching and convergence structure of
collaboration, the sizes of committed representations, and the correlation of
activity across resources.

For many deployments this structural metadata is more sensitive than the
content. A collaboration graph reveals who worked with whom, when, and how
intensively, and it does so through the very mechanism that provides integrity.

Deployments SHOULD mitigate by publishing checkpoints rather than transitions,
increasing checkpoint aggregation, decoupling and rotating principal
identifiers across contexts, using context-scoped pairwise identifiers for
natural persons, padding or bucketing committed lengths, and delaying anchoring
to decorrelate activity from publication time.

Every profile MUST include a statement of what its structure leaks to an
observer who receives only the commitments. A profile that does not state this
is not conforming.


# Profiles {#profiles}

VSTP is not usable alone. A profile binds it to a domain.

## Requirements {#profile-reqs}

A conforming profile MUST specify:

1. the identity, key resolution, and credential systems used for each principal
   role, and how a verifier resolves a principal to a key offline;
2. the encoding profile, digest algorithm, signature algorithm, and accumulator
   construction, all satisfying {{post-quantum}};
3. every representation profile used, with normalization rules complete enough
   for independent implementations to agree bit-exactly;
4. the authority model, meeting all requirements of {{authority-models}};
5. the policy language or evaluation model, and whether decisions are
   reproducible under {{reproducibility}};
6. the resource types and their identity assignment rules;
7. the operation profiles and their semantics;
8. the mediation level achievable and the evidence supporting it;
9. the retention, erasure, and disclosure model ({{disclosure}});
10. the metadata leakage statement ({{leakage}});
11. bounds on every variable-length element;
12. the receipt types required or accepted and the assurance dimensions each
    contributes to;
13. any additional assurance dimensions, and any dimension the profile declares
    permanently `not-established`;
14. test vectors sufficient to establish interoperability, including
    malformed-input rejection cases.

A profile MUST NOT weaken any requirement of this document. A profile MAY
strengthen requirements and MAY declare elements mandatory that this document
makes optional.

## Interoperability Bindings {#interop}

A profile MAY define bindings that carry evidence from external specifications.
Where it does, it MUST state which assurance dimensions the evidence
contributes to and MUST NOT permit contribution beyond them. Indicative
bindings:

| External evidence | Contributes to |
|---|---|
| Issuer-signed credential ({{VC-DM}}) | `principal-identity` |
| Software publisher attestation | `instrument-identity` |
| Build provenance attestation ({{IN-TOTO}}, {{SLSA}}) | `instrument-identity`, `semantic-fidelity` within the build domain |
| Media provenance manifest ({{C2PA}}) | `semantic-fidelity` for transformations it covers |
| Transparency registration receipt ({{SCITT-ARCH}}, {{RFC9162}}) | `existence-time`, `ordering` |
| Trusted timestamp ({{RFC3161}}) | `existence-time` |
| Execution environment attestation | `instrument-identity`, and `recording-mediation` where the environment enforces mediation |

VSTP does not absorb these specifications and MUST NOT be extended to parse
their internals in its core. Their verification is the profile's obligation;
the core's obligation is to bind their results to dimensions without
overreaching.


# Security Considerations {#security}

**A signature is not truth.** Every guarantee in this protocol is conditional on
the honesty of some party. The protocol's contribution is making the identity
of that party, and the scope of the dependence, explicit and machine-readable.
Implementations that collapse this into a verdict discard the contribution.

**The recorder is trusted for what it did not record.** Under `observational`
and `asserted` mediation, a compromised or dishonest recorder can omit
transitions. Continuity checking ({{continuity}}) bounds this to the observation
interval for resources it re-observes, and bounds it not at all for resources it
never observes again. Deployments requiring stronger properties must obtain
`mediated` or `enforced` mediation, which requires mechanisms outside this
protocol.

**Equivocation requires external observers.** {{equivocation}}. A deployment
with no receipt source has no equivocation detection, and this must be reported
rather than silently omitted.

**Key compromise permits retroactive forgery.** An adversary holding a
recorder's key can construct an alternative history that verifies. Receipts
bound this: transitions covered by a receipt predating the compromise cannot be
retroactively replaced without also forging the receipt issuer. Deployments
SHOULD obtain receipts at a cadence matched to their exposure, and MUST record
key rotation and compromise as transitions in a context so that the boundary is
itself verifiable.

**Canonicalization ambiguity is an identity attack.** If two distinct
information-model instances can produce the same octets, or one instance can
produce two, an adversary can construct objects whose meaning differs from
their identifier. This is why {{encoding}} imposes determinism, injectivity, and
domain separation as normative requirements, and why {{procedure}} requires a
re-encoding check rather than trusting received octets.

**Must-understand semantics are a security requirement, not a strictness
preference.** A verifier that ignores an element it does not recognize can be
made to attribute a different meaning to an object than the signer intended,
while still computing a matching identifier if the element was included in the
digest — or a mismatching one if it was not. Neither outcome is acceptable.

**Policy substitution.** `policy_commitment` prevents a party from claiming
that a decision was produced by a policy other than the one actually evaluated.
Without it, "authorized by policy" is unfalsifiable. Verifiers MUST check the
disclosed policy against the commitment before attempting reproduction.

**Authority amplification and the confused deputy.** An instrument acting on
behalf of an actor must not be able to exercise authority the actor did not
delegate. {{authority-models}} requires non-amplification, and {{procedure}}
requires verifiers to check it at every delegation step. Deployments in which
an instrument holds ambient authority beyond the delegated capability are
outside what this protocol can meaningfully attest.

**Approval presentation attacks.** Where the approver's rendering is not bound,
an approval can be obtained by displaying something other than what is
approved. {{approval}} makes `presentation_commitment` mandatory for this
reason. It bounds the attack to compromise of the presenting instrument, which
is then attributable.

**State commitment time-of-check to time-of-use.** A commitment binds a
representation at the moment it was computed. Where a recorder computes a
commitment and a separate process later acts on the resource, the two may
disagree. Profiles MUST specify how commitments are obtained relative to the
acts they describe, and mediation level bounds the residual exposure.

**Cross-context replay.** `genesis_nonce` and mandatory context binding prevent
a transition recorded in one context from being presented as valid in another.
Verifiers MUST check context binding on every object.

**Resource exhaustion.** Graphs are adversary-influenced. Bounded element
sizes, bounded object sizes, bounded graph size, bounded parent cardinality,
and bounded traversal depth are required of encoding profiles ({{encoding}})
and profiles ({{profile-reqs}}). Verifiers MUST enforce them before traversal,
not during.

**Long-term digest agility.** Content-addressed identifiers are only as durable
as the digest algorithm. Compromise of a digest algorithm invalidates the
acyclicity argument of {{graph}} and permits substitution of objects with
matching identifiers. {{agility}} describes the migration path; deployments
with retention obligations measured in decades MUST plan for it explicitly.

**Receipt independence.** {{receipt}} requires the issuer to differ from the
recorder. Deployments SHOULD further consider whether the issuer is
independently controlled in fact, not merely in key material; a receipt from a
service operated by the recorder's own organization provides correspondingly
less evidence, and verification policy SHOULD reflect this.


# Privacy Considerations {#privacy}

**Structure leaks even when content does not.** {{leakage}} is a privacy
consideration first and is normative for profiles. The integrity mechanism and
the leakage mechanism are the same mechanism, and this trade-off cannot be
engineered away, only bounded and disclosed.

**Publication is irreversible.** Anchoring a commitment to widely replicated or
append-only media is publication. It cannot be undone by any subsequent
protocol action. Deployments MUST decide what is anchored on the assumption
that anchoring is permanent.

**A commitment may itself be personal data.** A digest is not automatically
anonymous. Where a commitment remains linkable to an identified person — by a
known source value, a small candidate space, or correlation with other
disclosed structure — it should be treated as personal data for regulatory
purposes. Hiding commitments with high-entropy openings ({{erasure}}) are the
mitigation; a bare digest of a low-entropy or guessable representation is not.

**Erasure obligations survive the protocol.** {{erasure}} is mandatory for
deployments subject to erasure rights. A `revoke` transition satisfies no
erasure obligation. Implementers should not assume that a legal distinction
between "removing a claim" and "removing data" will be accepted.

Three situations must be kept distinct, and a profile MUST state which of them
it can offer for each element: erasure of data held in a controlled repository;
invalidation of a previously issued claim; and the impossibility of erasing
evidence already disclosed to parties outside the deployment's control. Only
the first is erasure. A deployment that has published commitments to widely
replicated media has permanently entered the third case for those commitments,
and the `deletion` receipt type attests only to the first.

**Principal identifier correlation.** A stable principal identifier used across
contexts permits correlation of a natural person's activity across unrelated
domains. Profiles handling natural persons SHOULD require context-scoped
pairwise identifiers and MUST state the correlation properties of whatever
scheme they adopt.

**Approval records are behavioural records.** An approval binds an identified
human to a specific decision at a specific time with a specific presentation.
Aggregated, approval records constitute a detailed record of individual
judgement and working patterns. Profiles SHOULD restrict approval disclosure to
the parties with a demonstrable need and SHOULD support proving that a required
approval occurred without disclosing which individual gave it, where the domain
permits.

**Special categories of data.** Where resources concern health, biometric,
financial, or comparably sensitive matters, even the existence and cadence of
transitions may be sensitive. Such profiles SHOULD anchor only aggregated
checkpoints and SHOULD NOT publish per-transition structure.

**Agent and model manifests.** Where a profile records the operation of
autonomous agents, it SHOULD require commitments to model identity, tool
definitions, and input sets, and SHOULD NOT require disclosure of prompts or
intermediate reasoning. The objective is a reproducible accountability
boundary, not disclosure of everything an agent processed.


# IANA Considerations {#iana}

This document requests creation of the following registries under a common
"VSTP" grouping. Each registration MUST include: identifier, reference,
contact, and the assurance dimensions the item may contribute to, where
applicable.

| Registry | Policy | Initial contents |
|---|---|---|
| VSTP Structural Classes | Standards Action | {{structural}} |
| VSTP Epistemic Types | Standards Action | {{epistemic}} |
| VSTP Mediation Levels | Standards Action | {{mediation}} |
| VSTP Assurance Dimensions | Standards Action | {{dimensions}} |
| VSTP Assurance Values | Standards Action | {{dimensions}} |
| VSTP Encoding Profiles | Specification Required | none |
| VSTP Representation Profiles | Specification Required | none |
| VSTP Operation Profiles | Specification Required | none |
| VSTP Authority Models | Specification Required | `null` |
| VSTP Receipt Types | Specification Required | {{receipt}} |
| VSTP Resource Types | Specification Required | none |
| VSTP Finding Codes | Specification Required | {{findings}} |
| VSTP Domain Profiles | Specification Required | none |

Registration in VSTP Authority Models requires the designated expert to confirm
that the model satisfies every requirement of {{authority-models}}.

Registration in VSTP Representation Profiles requires normalization rules
sufficient for independent implementations to produce identical commitments.

## Initial Finding Codes {#findings}

`encoding-mismatch`, `non-canonical-encoding`, `unknown-element`,
`identifier-mismatch`, `invalid-signature`, `unresolved-principal`,
`context-mismatch`, `context-unavailable`, `structural-violation`,
`state-discontinuity`, `declared-discontinuity`, `representation-mismatch`,
`checkpoint-chain-gap`, `equivocation`, `equivocation-detection-unavailable`,
`authority-amplification`, `authority-scope-exceeded`, `authority-not-evaluated`,
`policy-reproduced`, `policy-contradicted`, `policy-not-attempted`,
`operation-mismatch`, `self-issued-receipt`, `mediation-unsupported`,
`weak-algorithm`, `withheld`, `erased`, `missing-parent`, `bounds-exceeded`.


# Conformance {#conformance}

An implementation conforms as a **recorder** if it produces objects satisfying
{{data-model}}, carries a mediation declaration it can support
({{completeness}}), and records authority for every transition including the
explicit null case ({{authority-element}}).

An implementation conforms as a **verifier** if it performs every step of
{{procedure}}, produces an assurance vector ({{dimensions}}), respects the
epistemic typing rules ({{epistemic}}) and completeness obligations
({{completeness-verifier}}), operates offline against a bundle, and observes
{{summarization}} and {{output}}.

An implementation conforms as a **profile** if it satisfies {{profile-reqs}}.

Test vectors, including malformed-input rejection cases, are required for
interoperability and are expected in a companion document.


--- back

# Acknowledgements
{:numbered="false"}

This specification generalizes design discipline developed independently in
several provenance, transparency, and authorization systems, and owes its
central caution — that evidence must never silently upgrade its own type — to
practitioners who found that lesson expensively.
