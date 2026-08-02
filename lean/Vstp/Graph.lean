/-
  Acyclicity — core specification §3.2.

  The specification claims the transition graph is acyclic "by construction",
  because identifiers are derived from content that includes the parent
  identifiers, and therefore a transition cannot reference a successor. That
  argument is correct but it hides an assumption. This file isolates it.

  The assumption is `Ranked`: a parent's identifier must already exist before
  a child's identifier can be computed. Content addressing under a
  collision-resistant digest supplies it. Acyclicity then follows with no
  further cryptographic input — which is the useful thing to know, because it
  says exactly which property of the digest the graph structure depends on.
-/
import Vstp.Basic

namespace Vstp

/-- `Reaches g a b` : following parent edges from `a` arrives at `b`. -/
inductive Reaches (g : Graph) : Nat → Nat → Prop where
  | step {t : Transition} {p : Nat} :
      t ∈ g.transitions → p ∈ t.parents → Reaches g t.id p
  | tail {a b c : Nat} :
      Reaches g a b → Reaches g b c → Reaches g a c

/-- The content-addressing assumption, made explicit: some measure on
    identifiers strictly decreases along parent edges. -/
def Ranked (g : Graph) (rank : Nat → Nat) : Prop :=
  ∀ t ∈ g.transitions, ∀ p ∈ t.parents, rank p < rank t.id

theorem reaches_rank_lt {g : Graph} {rank : Nat → Nat} (h : Ranked g rank) :
    ∀ {a b : Nat}, Reaches g a b → rank b < rank a := by
  intro a b hr
  induction hr with
  | step ht hp => exact h _ ht _ hp
  | tail _ _ ih₁ ih₂ => omega

/-- Core §3.2: the graph is acyclic. -/
theorem acyclic {g : Graph} {rank : Nat → Nat} (h : Ranked g rank) :
    ∀ a : Nat, ¬ Reaches g a a := by
  intro a hr
  have := reaches_rank_lt h hr
  omega

/-- A transition cannot be its own parent. -/
theorem no_self_parent {g : Graph} {rank : Nat → Nat} (h : Ranked g rank) :
    ∀ t ∈ g.transitions, t.id ∉ t.parents := by
  intro t ht hmem
  exact acyclic h t.id (Reaches.step ht hmem)

/-- Reachability is a strict order on identifiers, so no two distinct
    transitions can each reach the other: convergence is representable,
    mutual dependence is not. -/
theorem no_mutual_reach {g : Graph} {rank : Nat → Nat} (h : Ranked g rank)
    {a b : Nat} (hab : Reaches g a b) (hba : Reaches g b a) : False :=
  acyclic h a (Reaches.tail hab hba)

end Vstp
