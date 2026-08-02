/-
  Completeness — core specification §7.

  §7.1 asserts that integrity of a record set is independent of its
  completeness. That is the load-bearing honesty claim of the whole protocol,
  and every evaluator tests it within a minute of hearing the pitch. Here it
  is a theorem rather than a disclaimer.

  The model: a *history* is the sequence of states a resource actually held.
  A recorder sees a subsequence of it. Two histories are indistinguishable to
  a recorder when they share an observation subsequence — no amount of
  integrity protection on the record can separate them, because the record is
  identical in both worlds.
-/
import Vstp.Basic

namespace Vstp

/-- The true sequence of states a resource held. Not observable. -/
abbrev History := List Commitment

/-- `Sub o h` : the observations `o` occur in the true history `h`, in order.
    This is exactly what an observational recorder learns. -/
inductive Sub : List Commitment → History → Prop where
  | nil  : Sub [] []
  | keep : ∀ {s t : List Commitment} {a : Commitment}, Sub s t → Sub (a :: s) (a :: t)
  | drop : ∀ {s t : List Commitment} {a : Commitment}, Sub s t → Sub s (a :: t)

private def c (n : Nat) : Commitment := ⟨0, 0, 1, 0, n⟩

private def sA : Commitment := c 100
private def sB : Commitment := c 200
private def sC : Commitment := c 300

/-- **Integrity does not imply completeness.** There exist two distinct true
    histories that produce identical observations. No property of the record —
    hash chaining, signatures, checkpoints, receipts — can distinguish them,
    because the record is bit-identical in both cases.

    Core §7.1. -/
theorem integrity_does_not_imply_completeness :
    ∃ (h₁ h₂ : History) (o : List Commitment),
      h₁ ≠ h₂ ∧ Sub o h₁ ∧ Sub o h₂ := by
  refine ⟨[sA, sC], [sA, sB, sC], [sA, sC], by decide, ?_, ?_⟩
  · exact Sub.keep (Sub.keep Sub.nil)
  · exact Sub.keep (Sub.drop (Sub.keep Sub.nil))

/-- **Continuity does not close the gap.** The stronger statement, and the one
    that matters, because the obvious rebuttal to the theorem above is "then
    require the chain to be continuous".

    Here the recorded chain is continuous — the recorder observed `sA` and
    then `sC`, and its single recorded step `sA → sC` chains perfectly — yet
    the true history may have passed through `sB` and returned to `sA` before
    reaching `sC`. A change that reverts between two observations is invisible
    to any recorder, at any level of cryptographic assurance.

    This is why core §7.4 forbids a verifier from reporting a history as
    complete on the strength of continuity alone. -/
theorem continuity_does_not_imply_completeness :
    ∃ (h₁ h₂ : History) (o : List Commitment),
      h₁ ≠ h₂ ∧ Sub o h₁ ∧ Sub o h₂ ∧ o = [sA, sC] := by
  refine ⟨[sA, sC], [sA, sB, sA, sC], [sA, sC], by decide, ?_, ?_, rfl⟩
  · exact Sub.keep (Sub.keep Sub.nil)
  · exact Sub.keep (Sub.drop (Sub.drop (Sub.keep Sub.nil)))

/-! ## What observation does establish

    The negative results above are bounded. Observation is not worthless: it
    pins the true history at every point the recorder looked. -/

/-- Every observation is a state the resource genuinely held. -/
theorem observed_states_are_real :
    ∀ {o : List Commitment} {h : History}, Sub o h →
      ∀ x ∈ o, x ∈ h := by
  intro o h hs
  induction hs with
  | nil => intro x hx; cases hx
  | keep _ ih =>
      intro x hx
      cases hx with
      | head => exact List.Mem.head _
      | tail _ hx' => exact List.Mem.tail _ (ih x hx')
  | drop _ ih => intro x hx; exact List.Mem.tail _ (ih x hx)

/-- A recorder never sees more states than occurred. Combined with
    `integrity_does_not_imply_completeness`, this is the precise shape of the
    guarantee: observations are sound but not complete. -/
theorem observations_are_bounded :
    ∀ {o : List Commitment} {h : History}, Sub o h → o.length ≤ h.length := by
  intro o h hs
  induction hs with
  | nil => exact Nat.le_refl 0
  | keep _ ih => exact Nat.succ_le_succ ih
  | drop _ ih => exact Nat.le_succ_of_le ih

/-- An observation cannot introduce a state that did not occur in the true
    history. This is the element-wise form of `observed_states_are_real`,
    useful to consumers that reason about a particular commitment.

    Core §7.3's temporal claim that an undetected change is bounded by two
    observations requires a model of observation times, which this deliberately
    order-only model does not contain. -/
theorem observed_commitment_occurred
    {o : List Commitment} {h : History} (hs : Sub o h) (x : Commitment)
    (hx : x ∈ o) : x ∈ h :=
  observed_states_are_real hs x hx

end Vstp
