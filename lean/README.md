# VSTP formal model

Machine-checked proofs of the claims that `draft-sellstrom-vstp-core-00.md`
asserts in prose and which are theorems rather than design choices.

Lean 4, **no mathlib** — the whole development builds in a few seconds from a
bare toolchain, so anyone can check it without a dependency tree.

```
lake build                       # verify all proofs
lake env lean check-axioms.lean  # audit axiom dependencies
```

## What is proved

| File | Claim | Spec |
|---|---|---|
| `Vstp/Graph.lean` | The transition graph is acyclic, no transition is its own parent, and no two transitions reach each other. | §3.2 |
| `Vstp/Authority.lean` | The authority at the end of any valid delegation chain is contained in the authority at its root; anything the end permits, the root already permitted. Plus a worked capability model discharging the obligations. | §5.2 |
| `Vstp/Completeness.lean` | Integrity does not imply completeness — and neither does continuity. Bounded by: observations are sound. | §7.1, §7.3 |
| `Vstp/Assurance.lean` | Assessment is monotone in evidence, and a claim's assertion about its own strength cannot affect its assessment. | §6, §8.4 |

## Why these four

**`chain_attenuates` / `no_amplification` are the point of the exercise.**
§5.2 states four requirements on any authority model registered for use with
VSTP, in prose, to be checked by a designated expert reading it. In
`Authority.lean` they are the fields of a Lean structure. A registrant
conforms by instantiating `AuthorityModel` and discharging its obligations;
attenuation is then a theorem about their model rather than a promise about
it.

`CapModel` answers a question the specification could not answer about itself:
whether §5.2 is satisfiable at all, or whether it demands something no real
capability system provides. It is satisfiable — by an ordinary
permission-set model with subset containment.

**`continuity_does_not_imply_completeness` is the one to read second.** The
completeness asymmetry (§7.1) is the protocol's load-bearing honesty claim,
and the obvious rebuttal is "then require the recorded chain to be
continuous". The theorem exhibits a continuous recorded chain consistent with
two different true histories: a resource that changed and changed back
between two observations is invisible to any recorder, at any level of
cryptographic assurance. That is a fact about observation, not a deficiency
of a particular design, and it is why §7.4 forbids a verifier from reporting
a history as complete on the strength of continuity alone.

**`acyclic` isolates an assumption the prose hides.** §3.2 argues the graph is
acyclic "by construction" because identifiers derive from content. Correct,
but it smuggles in a premise. `Ranked` names it: a parent's identifier must
exist before a child's can be computed. Acyclicity follows from that alone,
with no further cryptographic input — which tells you exactly which property
of the digest the graph structure depends on, and which it does not.

**`assess_monotone` and `self_assertion_irrelevant` convert prohibitions into
structure.** §6 tells implementers not to let evidence upgrade its own type.
Rules like that are hard to check by inspection. Here the assessment function
simply does not take the claim's self-description as a parameter, so the
property holds by construction and is auditable in one line.

## Axiom status

No `sorry`, no `admit`, no `native_decide`. Every theorem depends only on
Lean's standard axioms; `chain_attenuates` and `no_amplification` depend on
**none at all**. `check-axioms.lean` re-verifies this — treat any appearance
of `sorryAx` as a build failure.

## What is deliberately not modelled

Encodings, digests, signatures, transports, and wire formats. Modelling them
would mean fixing choices the core specification deliberately leaves to
profiles, and would weaken the theorems from "holds for any encoding" to
"holds for this one". Those concerns are checked by test vectors, which is
the right tool for them.

Also unmodelled: §5.2's requirements 4 and 5 (revocation timing semantics,
offline evaluability). Both are deployment properties rather than algebraic
ones. Requirement 4 in particular is an open question — see `RATIONALE.md`
§10.3 — and formalizing it before deciding it would prove the wrong thing.

## Relationship to the specification

The model is not normative. Where it and the draft disagree, the draft
governs and the model has a bug. Its purpose is to make four specific claims
checkable, and to make §5.2 a discharge obligation rather than a paragraph.
