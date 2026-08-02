# VSTP Design Rationale

Non-normative. This document explains why the core specification is shaped the
way it is, records the designs that were considered and rejected, and states
the open questions honestly. Nothing here is binding; where this document and
`draft-sellstrom-vstp-core-00.md` disagree, the specification governs.

---

## 1. The one-sentence thesis

Provenance systems answer *what happened*. Transparency systems answer *what
was registered*. Neither answers *who was permitted*.

VSTP's only genuinely novel requirement is that authority is mandatory,
structured, and — where the model permits — reproducible. Everything else in
the specification is careful engineering around a primitive that several
communities have converged on independently. If the authority requirement were
removed, VSTP would be a slightly cleaner restatement of prior art and should
not be standardized.

This is worth being blunt about, because it determines where the specification
should be defended and where it should yield. On the object model, yield
readily — it is conventional and should be. On mandatory authority, mandatory
mediation, and the verifier prohibitions, do not yield; those are the
contribution.

---

## 2. Why one transition object instead of a type hierarchy

An earlier formulation of this design proposed a hierarchy of sibling record
types: mutation, derivation, approval, release, revocation. That hierarchy is
attractive because each type has genuinely different fields.

It was rejected because it destroys the property that makes the graph useful.
If an approval is a different kind of object than a mutation, then traversing
"how did this resource reach this state" requires a verifier to understand
every type in the hierarchy, and adding a type breaks every existing verifier.
The graph stops being uniformly traversable, which was the point.

The resolution is the split between **structural class** and **semantic
operation**. Structural class is a small, closed, standards-action registry
because it changes how a verifier walks the graph — a verifier must understand
every value. Semantic operation is an open registry because it does not affect
traversal at all; an unrecognized operation profile is opaque and costs the
verifier nothing.

An approval is therefore a transition over the proposal it approves. A release
is a transition under a release operation profile. A revocation is a transition
that withdraws a claim. This is not a naming trick: it means a single graph
traversal answers questions that would otherwise require joining across object
types, and it means the definition of an act — *a verifiable transition between
committed states performed by an identified principal under specified
authority* — is literally true of every object in the graph rather than true of
one of them.

The test of whether this holds is the intent transformation chain, which other
designs model as a dedicated structure: what a principal expressed, what
software interpreted it to mean, what was authorized, what executed. Under the
single primitive these are four resources linked by three transitions (spec
§3.4), each stage separately committed. Nothing is lost, no new object type is
needed, and a misinterpretation shows up as a divergence between two committed
stages rather than disappearing inside one signed action. If a construction of
that importance had required a new object, the collapse would have been wrong.

---

## 3. Why there is no layer stack

A layered presentation of this design is tempting and was drafted: a State
layer holding bare commitments, a Transition layer holding pure `S₀ → S₁`
mathematics with no actors or semantics, an Execution layer adding principals
and authority, and a Trust layer holding timestamps and witnesses.

The stack was rejected as architecture, though it survives as pedagogy.

The problem is that the bottom two layers have no independent conformance
surface. A transition with no actor, no signature, and no semantics is a pair
of hashes. Nothing can consume it alone. No verifier can check anything
meaningful about it. It has no security properties to specify and no
interoperability to test. But making it a layer costs a specification, a
version series, a registry, and a migration obligation — real, permanent costs
for zero verifiable capability.

Worse, the stack invites the belief that the layers are separable in
deployment, which they are not. You cannot ship layers 1 and 2 and have
anything. The dependency is not layering; it is a single object with optional
elements.

What the stack was *actually* reaching for is preserved, in a cheaper form:

- The distinction between "a commitment to bytes" and "a commitment to a
  normalized model" became `representation_profile` — a field, not a stratum.
- The distinction between "the claim" and "what supports the claim" became the
  assertion/evidence/assurance separation (spec §3.3), which is a genuine
  three-way distinction because all three have independent conformance
  surfaces: recorders produce assertions, third parties produce evidence,
  verifiers produce assurance.

### The decomposition survives — as verification dimensions

The strongest objection to discarding the stack is that the distinctions it
draws are real. *What is committed? What changed? How was the change produced?
Who was permitted to cause it? Why should an external verifier accept the
evidence? What does this mean in this domain?* Those are six genuinely
different questions, and a design that could not answer them separately would
be worse.

The specification answers all six — as **verification dimensions** rather than
as protocol layers. This is the right home for them, because a dimension is
exactly a question a verifier answers independently, whereas a layer is a thing
that must be shipped, versioned, registered, and migrated:

| Layered question | Answered by |
|---|---|
| What is committed? | `record-integrity`, and `representation_profile` on each commitment |
| What changed? | `graph-continuity`, plus structural class |
| How was it produced? | `instrument-identity`, `semantic-fidelity` |
| Who was permitted? | `authority`, `policy-reproduction` |
| Why accept the evidence? | `existence-time`, `ordering`, `finality`, and the epistemic types |
| What does it mean here? | the profile, and its published assurance policy |

Nothing is lost. What is avoided is six specifications, six registries, six
version series, and six migration obligations for distinctions that cost one
field and one dimension each.

`representation_profile` deserves specific credit. The observation that a hash
of raw octets and a hash of a normalized document model are *different claims
about different things, neither implying the other*, is the single most useful
idea recovered from the layered drafts. It is one field and it removes an
entire class of false-equality bugs that otherwise surface as
impossible-to-diagnose continuity failures across implementations.

---

## 4. Why authority is mandatory, including the null case

An optional field is an absent field. If `authority` were optional, the
overwhelming majority of records would omit it, and a verifier could not
distinguish "the actor was not authorized" from "authorization was not
recorded" from "this deployment does not do authorization". Those are three
very different findings.

The mandatory null authority model forces the distinction into the record. A
recorder that watches a system it does not control writes `not-evaluated` under
the null model, and that is an honest, complete, conforming record. What it
cannot do is stay silent and let a reader assume.

### Why reproducibility is the sharp edge

"Authorized by policy" is unfalsifiable unless a third party can re-derive the
decision. Without `policy_commitment` a system can claim any policy after the
fact; without `inputs_commitment` it can claim any inputs; without both plus
determinism, `reproducible` is meaningless.

So the specification makes reproducibility a claim with teeth: a decision may
only be typed `decision` if it is reproducible, and otherwise it is a
`declaration`. A verifier that reproduces the policy and gets a different
answer reports `policy-contradicted`, which is a strong negative finding — it
establishes that the recorded decision is not the decision the stated policy
produces, which is either a bug or a fabrication and is worth surfacing loudly
either way.

The escape hatch for confidential policies is a proof that the committed
decision correctly evaluates the committed policy over the committed inputs.
The specification deliberately does not name a proof system. Naming one would
bind VSTP to a cryptographic construction with a much shorter expected lifetime
than the protocol.

### Why the requirements on authority models are stated abstractly

VSTP cannot define a capability format without picking a side in an unsettled
design space and without breaking every deployment that already has one. But it
can state what a model must provide for a verifier to check anything:

- decidable scope containment, or delegation cannot be checked at all;
- non-amplification, or delegation is not delegation;
- scope expressible over resources and structural classes, or the check does
  not connect to the transition presented;
- defined revocation semantics, or two verifiers reach different conclusions
  from the same evidence;
- offline evaluability, or the verifier depends on the party it is verifying.

These are testable at registration time. They are the real content of "VSTP
supports capability-based authorization" without VSTP defining a capability.

---

## 5. Why completeness is mandatory and stated as a limitation

Every hash-chained history has the same asymmetry: it proves recorded entries
were not altered; it proves nothing about entries that were never made.

This is universally known among implementers and almost universally absent from
the output such systems produce. Users read "verified history" as "the
history". The gap between those two readings is where the trust in these
systems will eventually break, and it will break in a dispute, in public.

So the specification does three things rather than one:

1. **Declares.** `mediation` is mandatory on every context and checkpoint, with
   evidence required for the two strong levels and automatic downgrade without
   it. A deployment at `observational` is legitimate; presenting it as
   `mediated` is not.

2. **Detects.** Continuity checking is the part of this design that is
   genuinely better than a disclaimer. Because every transition commits to both
   prior and resulting state, a verifier can check that consecutive transitions
   chain. Where they do not, an unrecorded change *provably occurred* between
   two specific observations. An observational recorder cannot prove
   completeness — but wherever it re-observes a resource, it detects
   out-of-band modification, and the undetectability window is bounded by the
   observation interval rather than unbounded. This converts the honest
   disclaimer into a bounded, quantifiable property, and it is the strongest
   available answer to the question every evaluator asks within ninety seconds:
   *what stops someone editing out of band?*

   The answer is: nothing stops it; the next observation detects it; here is
   the interval.

3. **Constrains the verifier.** The prohibition on the words "complete",
   "full", and "entire" absent supported `mediated`/`enforced` mediation is
   deliberately blunt. It is the kind of requirement that gets negotiated away
   in review as "not a protocol matter". It is a protocol matter, because the
   protocol's value depends on its output being read correctly.

The `discontinuity` structural class exists so an honest recorder has somewhere
to put "I know something changed and I do not know what". Systems without such
a construct either hide gaps or fail loudly on them; both are worse than
recording them.

---

## 6. Why the assurance vector, and how the badge problem is resolved

A single verification verdict is a lossy projection of a genuinely
multidimensional result. Record integrity, authority, human approval, existence
time, and completeness are independent; a record can have any subset. Reducing
them to one bit necessarily overstates the weak dimensions.

The counter-argument is real and should not be waved away: a vector of fifteen
dimensions is unusable at a decision point. Someone has to decide what is good
enough, and if the specification refuses, every implementer will invent a
threshold privately — recreating the badge, but unattributably and
inconsistently.

The resolution is not to suppress the summary but to make the threshold
**attributable**. A summary may be emitted only if it is computed by a named,
versioned, published assurance policy, whose identifier and publisher travel
with the summary. The vector stays honest; the threshold becomes a statement by
an identifiable party who can be held to it.

This has a useful secondary effect: assurance policies become a public artifact
that regulators, industry bodies, and auditors can specify, compare, and
mandate — which is where that judgement belongs and where this specification
should not be.

---

## 7. Erasure and metadata leakage

Two problems that provenance designs consistently defer until a partner's data
protection officer asks. Both are addressed in the core because both are
structural, not incidental.

**Erasure.** A permanent signed record of who did what, when, is unerasable by
construction. A revocation withdraws a claim; it does not remove data, and the
legal distinction between the two should not be assumed to hold. The
specification therefore mandates erasure-tolerant construction: hiding
commitments with separately stored openings, such that destroying the opening
renders the element unrecoverable while leaving every identifier, signature,
and graph relationship intact and verifiable. A verifier encountering an
unopenable commitment reports `erased`, not `invalid`.

This has to be designed in from the start. Retrofitting it means re-committing
history, which means the history was never what it claimed to be.

**Leakage.** A graph with every payload withheld still discloses transition
count, timing and cadence, principal recurrence, branching structure, committed
sizes, and cross-resource correlation. For collaboration, clinical, and
employment domains this structural metadata is frequently more sensitive than
the content, and it leaks through precisely the mechanism that provides
integrity. That trade-off cannot be engineered away — only bounded and
disclosed. Hence the requirement that every profile publish a leakage
statement.

---

## 8. Deliberately rejected designs

**A universal diff or change representation.** The same octet-level change may
be a substantive revision, a metadata update, an autosave, a re-render, or a
regeneration. No universal representation distinguishes them, and mandating one
would force every domain into a vocabulary that fits none. The operation
element is optional and commitment-based; core guarantees do not depend on it.

**A universal ontology of acts.** The same argument, one level up, and a more
seductive mistake. Attempts to enumerate the kinds of things people and systems
do produce taxonomies that are simultaneously too coarse for the domains they
cover and unbounded in growth. Structural classes are the minimum a verifier
must understand to walk the graph — eleven of them — and semantics are pushed
entirely to profiles.

**Path, name, or location as identity.** Identity derived from location breaks
under exactly the operations this protocol exists to record: rename, move,
copy, export, migration. Identity derived from content makes every modification
a new resource, discarding the continuity being recorded. Hence a stable
identifier and mutable, explicitly non-identifying labels.

**A linear feed as the core structure.** Feeds are a useful operational
projection and a poor core. Concurrent modification, offline work,
unreconciled divergence, and partial synchronization are all normal, and a
linear core forces each into either a lie or an error. The graph is the core;
feeds are projections of it.

**A mandatory serialization.** Genuinely arguable, and the strongest objection
to the current draft. Standards ordinarily mandate a mandatory-to-implement
encoding, and refusing to do so risks a family of profiles that cannot exchange
anything. The compromise adopted: no encoding is mandated globally, but each
*context* declares exactly one and all objects within it must use it, with
determinism, injectivity, domain separation, and bounds required normatively.
This preserves bit-exact agreement where it matters — inside a context, where
content addressing lives — without binding the protocol's lifetime to a
serialization's. This should be revisited if profiles proliferate without
converging.

**A mandatory ledger, timestamping authority, or transparency service.** These
supply evidence for three of fifteen dimensions. Requiring one would make the
protocol unusable in air-gapped, local-first, and regulated-retention
deployments where it is otherwise a good fit, in exchange for guarantees that
are properly reported as dimensions rather than assumed.

**An identity system.** Every deployment that would adopt VSTP has one. A core
that picks inherits that choice's governance and excludes everyone else.
Principals are opaque; profiles bind them; `principal-identity` reports what
was established.

**A boolean verification result.** See §6.

---

## 9. Comparison with related work

| | States committed | Cryptographic binding | Authority modelled | Policy reproducible | Completeness declared | Domain |
|---|---|---|---|---|---|---|
| W3C PROV-DM | no | no | no | no | no | general |
| C2PA | yes | yes | no | no | partial | media |
| in-toto / SLSA | yes | yes | layout-scoped | no | pipeline-scoped | software build |
| SCITT | statement digests | yes | no (by design) | no | registration-scoped | supply chain |
| W3C VC | n/a | yes | issuer-scoped | no | n/a | claims about subjects |
| Signed VCS commits | yes | yes | no | no | no | source code |
| VSTP | yes | yes | **required** | **required where claimed** | **required** | general |

The row that matters is the third-from-right. Everything else in this table has
five or more years of head start, real deployments, and tooling. Competing on
"provenance graph" is competing where they are strong. The defensible position
is authority-bearing state transitions: none of these bind a state transition
to an attenuated authority chain plus a reproducible authorization decision.

A useful way to state the boundary: SCITT proves a statement was registered.
C2PA proves a media assertion chain. VCs prove an issuer said something.
None of them answers *was this principal permitted to do this, under which
policy, and can I re-run the decision myself?*

The correct posture toward all of them is carriage, not replacement. Every one
is a registered evidence binding contributing to named dimensions. A VSTP that
tried to absorb them would be both worse at their jobs and unadoptable.

---

## 10. Open questions

Stated plainly rather than resolved, because a specification that pretends
these are settled will be corrected in review.

1. **Mandatory-to-implement encoding.** §8 explains the current compromise. It
   may be wrong. If two independent profiles ship and cannot exchange objects,
   it is wrong.

2. **Accumulator construction for checkpoints.** Left to encoding profiles.
   Non-inclusion proofs in particular are not available in all constructions,
   and the specification currently requires only that their availability be
   declared. This may be too weak: detecting a *suppressed* transition may
   require them.

3. **Revocation timing semantics.** The specification requires authority models
   to define whether authority is evaluated at transition time or verification
   time, and requires verifiers to report which. It does not choose. Two
   verifiers can therefore reach different conclusions about the same record
   under different models, which is honest but operationally awkward.

4. **Cross-context composition.** `import` transitions link contexts, but the
   assurance semantics of a graph spanning contexts with different authority
   models, mediation levels, and encoding profiles are underspecified. This
   will matter as soon as two organizations exchange bundles.

5. **Whether `intent-fidelity` should exist as a dimension at all.** It is
   permanently `not-established` in essentially every deployment. Retaining it
   documents an important limit; removing it avoids implying the protocol is
   working toward it. The current draft retains it as documentation.

6. **The first profile.** Not a specification question, but the one that
   determines whether any of this is used. The domains where the authority
   requirement is load-bearing *and* where instrumentation can plausibly reach
   `asserted` or better — rather than being stuck at `observational` because
   the software being observed will never cooperate — are the domains to
   profile first. Autonomous agent execution is the obvious candidate: the
   frameworks are new, unstandardized, actively seeking auditability, and
   already emit structured records of tool calls under delegated permissions.
   Established application ecosystems are the opposite case: the reason
   external watchers exist is that vendor integration does not happen, and
   publishing a specification does not change the incentive that caused that.

   A specification whose first profile is chosen by what already exists rather
   than by where the requirement bites will be evaluated at `observational`
   mediation with a null authority model — which is to say, evaluated as prior
   art.
