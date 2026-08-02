/-
  Basic objects — core specification §4.

  Identifiers, digests and principals are modelled as `Nat`. The proofs below
  never inspect their structure; they depend only on decidable equality. This
  is deliberate: the theorems must hold for any encoding, and modelling the
  encoding would weaken rather than strengthen them.
-/
namespace Vstp

abbrev Principal  := Nat
abbrev ResourceId := Nat
abbrev ProfileId  := Nat
abbrev AlgId      := Nat
abbrev Digest     := Nat

/-- Core §4.4. A state commitment is qualified by the representation profile
    and algorithm under which it was computed, not merely by its digest.
    Derived `DecidableEq` therefore gives exactly the comparison rule the
    specification mandates: two commitments are equal only when profile,
    profile version, algorithm and digest all agree. -/
structure Commitment where
  resource  : ResourceId
  profile   : ProfileId
  version   : Nat
  algorithm : AlgId
  digest    : Digest
deriving DecidableEq, Repr

/-- Core §4.5.1. -/
inductive StructuralClass where
  | genesis | update | derive | merge | fork | approve
  | supersede | revoke | discontinuity | imported | terminate
deriving DecidableEq, Repr

/-- Core §4.5. Only the elements the graph theorems depend on are modelled. -/
structure Transition where
  id              : Nat
  parents         : List Nat
  priorStates     : List Commitment
  resultingStates : List Commitment
  actor           : Principal
  recorder        : Principal
  sequence        : Nat
  cls             : StructuralClass
deriving DecidableEq, Repr

structure Graph where
  transitions : List Transition
deriving Repr

end Vstp
