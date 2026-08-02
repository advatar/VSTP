/-
  Assurance — core specification §6 and §8.4.

  Two properties the specification states as prohibitions on implementers:

  - §6: evidence never silently upgrades its own type. A claim's assertion
    about its own strength must not affect the verdict.
  - §8.4: assurance is per-dimension and monotone in evidence.

  A prohibition is hard to check. Here both are consequences of the shape of
  the assessment function, which is easier to audit than a rule an
  implementation is asked to obey.
-/
import Vstp.Basic

namespace Vstp

/-- Core §8.4, the positive scale. `contradicted` is deliberately absent: it
    is not a point on this order but a separate negative finding, and
    modelling it as a maximum or minimum would be wrong in both directions. -/
inductive Level where
  | notEstablished | declared | observed | attested | verified
deriving DecidableEq, Repr

def Level.toNat : Level → Nat
  | .notEstablished => 0
  | .declared       => 1
  | .observed       => 2
  | .attested       => 3
  | .verified       => 4

/-- Ordering on assurance, defined on the numeric rank so that arithmetic
    reasoning is available without an instance-unfolding detour. -/
def Level.le (a b : Level) : Prop := a.toNat ≤ b.toNat

def Level.max (a b : Level) : Level := if a.toNat ≤ b.toNat then b else a

theorem toNat_max (a b : Level) :
    (Level.max a b).toNat = if a.toNat ≤ b.toNat then b.toNat else a.toNat := by
  simp only [Level.max]; split <;> rfl

theorem max_ge_left (a b : Level) : a.toNat ≤ (Level.max a b).toNat := by
  rw [toNat_max]; split <;> omega

theorem max_ge_right (a b : Level) : b.toNat ≤ (Level.max a b).toNat := by
  rw [toNat_max]; split <;> omega

/-- Kinds of supporting evidence, ordered by the strength each can justify. -/
inductive EvidenceKind where
  | selfSigned        -- a declaration by the claimant
  | witnessObserved   -- an independent observation
  | issuerAttested    -- a named issuer's attestation
  | policyReproduced  -- the verifier re-derived the result itself
deriving DecidableEq, Repr

def levelOf : EvidenceKind → Level
  | .selfSigned       => .declared
  | .witnessObserved  => .observed
  | .issuerAttested   => .attested
  | .policyReproduced => .verified

/-- The assessment of one dimension. Note what is *not* a parameter: the
    claim's own assertion about its strength. -/
def assess : List EvidenceKind → Level
  | []      => .notEstablished
  | e :: r  => Level.max (levelOf e) (assess r)

/-- Every piece of evidence supports at least its own level. -/
theorem assess_supports :
    ∀ (ev : List EvidenceKind), ∀ e ∈ ev,
      (levelOf e).toNat ≤ (assess ev).toNat := by
  intro ev
  induction ev with
  | nil => intro e he; cases he
  | cons x r ih =>
      intro e he
      cases he with
      | head => simpa [assess] using max_ge_left (levelOf x) (assess r)
      | tail _ he' =>
          have h1 := ih e he'
          have h2 := max_ge_right (levelOf x) (assess r)
          simp only [assess]
          omega

/-- **Monotonicity in evidence.** Adding evidence never lowers a dimension.

    Core §8.4. The converse — that removing evidence never raises one — is the
    same statement, and is why withholding part of a bundle reduces
    `disclosure-completeness` without inflating any other dimension. -/
theorem assess_monotone :
    ∀ (ev₁ ev₂ : List EvidenceKind), (∀ e ∈ ev₁, e ∈ ev₂) →
      (assess ev₁).toNat ≤ (assess ev₂).toNat := by
  intro ev₁
  induction ev₁ with
  | nil => intro ev₂ _; exact Nat.zero_le _
  | cons x r ih =>
      intro ev₂ hsub
      have hx := assess_supports ev₂ x (hsub x (List.Mem.head _))
      have hr := ih ev₂ (fun e he => hsub e (List.Mem.tail _ he))
      simp only [assess]
      rw [toNat_max]
      split <;> omega

/-- Restated in terms of `Level.le`. -/
theorem assess_monotone_le (ev₁ ev₂ : List EvidenceKind)
    (h : ∀ e ∈ ev₁, e ∈ ev₂) : Level.le (assess ev₁) (assess ev₂) :=
  assess_monotone ev₁ ev₂ h

/-! ## No silent upgrade -/

/-- A claim as it arrives at a verifier: what it says about itself, and what
    actually supports it. -/
structure Claim where
  claimed  : Level
  evidence : List EvidenceKind

def assessClaim (cl : Claim) : Level := assess cl.evidence

/-- **A claim's self-assertion is irrelevant to its assessment.** Two claims
    differing only in what they assert about their own strength receive
    identical verdicts.

    Core §6. Stated as a theorem the model satisfies by construction rather
    than as a rule implementers are asked to follow. -/
theorem self_assertion_irrelevant (cl : Claim) (l : Level) :
    assessClaim { cl with claimed := l } = assessClaim cl := rfl

/-- In particular, a claim asserting the maximum cannot obtain it without
    evidence. -/
theorem claiming_does_not_establish :
    assessClaim { claimed := .verified, evidence := [] } = .notEstablished := rfl

/-- Self-signed evidence supports a declaration and nothing more, however the
    claim describes itself. -/
theorem self_signed_caps_at_declared :
    assessClaim { claimed := .verified, evidence := [.selfSigned] } = .declared := rfl

/-- A witness observation cannot reach the level that only independent
    re-derivation supports. -/
theorem witness_does_not_reach_verified :
    assessClaim { claimed := .verified, evidence := [.witnessObserved] } ≠ .verified := by
  decide

end Vstp
