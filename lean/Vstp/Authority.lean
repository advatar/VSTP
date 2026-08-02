/-
  Authority — core specification §5.

  This is the file that matters. §5.2 states four requirements on any
  authority model registered for use with VSTP, in prose, to be checked by a
  designated expert reading it. Here they are a Lean structure.

  A registrant conforms by instantiating `AuthorityModel` and discharging its
  proof obligations. `chain_attenuates` and `no_amplification` are then
  theorems about their model, not promises about it.

  `CapModel` at the bottom is a worked instance. Its purpose is to answer a
  question the specification could not answer about itself: whether §5.2 is
  satisfiable at all, or whether it demands something no real capability
  system provides.
-/
import Vstp.Basic

namespace Vstp

/-- Core §5.2. The fields after `contains` are exactly the specification's
    requirements 1 and 2: a decidable containment relation over scopes, which
    is reflexive and transitive.

    Requirement 3 (scope expressible over resources and structural classes)
    is a property of the chosen `Scope` type; `CapModel` below exhibits one.
    Requirements 4 and 5 (revocation semantics, offline evaluability) are
    deployment properties and are not modelled here. -/
structure AuthorityModel where
  Scope          : Type
  contains       : Scope → Scope → Bool
  contains_refl  : ∀ s, contains s s = true
  contains_trans : ∀ a b c, contains a b = true → contains b c = true →
                     contains a c = true

/-- One delegation step: `delegator` grants `delegate` the authority `scope`. -/
structure Delegation (M : AuthorityModel) where
  delegator : Principal
  delegate  : Principal
  scope     : M.Scope

/-- A chain is valid from `holder`, who holds `scope`, when every link is
    issued by the current holder and does not widen the current scope.

    The second conjunct is the non-amplification requirement. It is stated
    here as a *condition on validity*, so a chain that amplifies is not a
    chain at all rather than a chain a verifier is asked to reject. -/
def ChainValid (M : AuthorityModel) :
    Principal → M.Scope → List (Delegation M) → Prop
  | _, _, [] => True
  | holder, scope, d :: rest =>
      d.delegator = holder ∧
      M.contains scope d.scope = true ∧
      ChainValid M d.delegate d.scope rest

/-- The authority actually exercised at the end of a chain. -/
def effectiveScope (M : AuthorityModel) : M.Scope → List (Delegation M) → M.Scope
  | s, []      => s
  | _, d :: rest => effectiveScope M d.scope rest

/-- **Attenuation.** The authority at the end of any valid delegation chain is
    contained in the authority at its root.

    Core §5.2 requirement 2. -/
theorem chain_attenuates (M : AuthorityModel) :
    ∀ (ch : List (Delegation M)) (holder : Principal) (root : M.Scope),
      ChainValid M holder root ch →
      M.contains root (effectiveScope M root ch) = true := by
  intro ch
  induction ch with
  | nil =>
      intro holder root _
      simpa [effectiveScope] using M.contains_refl root
  | cons d rest ih =>
      intro holder root hv
      obtain ⟨_, hcont, hrest⟩ := hv
      have hend := ih d.delegate d.scope hrest
      simpa [effectiveScope] using
        M.contains_trans root d.scope (effectiveScope M d.scope rest) hcont hend

/-- **No amplification.** Anything permitted at the end of a valid chain was
    already permitted at its root. A delegation chain can only ever narrow.

    This is the property that distinguishes a delegated act from an asserted
    one, and it is what a verifier relies on when it reports the `authority`
    dimension without possessing the root principal's private state. -/
theorem no_amplification (M : AuthorityModel) (ch : List (Delegation M))
    (holder : Principal) (root : M.Scope) (hv : ChainValid M holder root ch)
    (s : M.Scope) (hs : M.contains (effectiveScope M root ch) s = true) :
    M.contains root s = true :=
  M.contains_trans _ _ _ (chain_attenuates M ch holder root hv) hs

/-- A chain that is valid is valid from its own root: extending a chain never
    recovers authority discarded earlier. -/
theorem extension_cannot_recover (M : AuthorityModel)
    (ch ext : List (Delegation M)) (holder : Principal) (root : M.Scope)
    (hv : ChainValid M holder root ch)
    (p : Principal)
    (hext : ChainValid M p (effectiveScope M root ch) ext) :
    M.contains root (effectiveScope M (effectiveScope M root ch) ext) = true :=
  M.contains_trans _ _ _
    (chain_attenuates M ch holder root hv)
    (chain_attenuates M ext p (effectiveScope M root ch) hext)

/-! ## A conforming instance

    Scope is a finite set of (resource, structural class) permissions;
    containment is subset. This demonstrates that §5.2 is satisfiable by an
    ordinary capability model. -/

/-- A single permission: one structural class over one resource. Core §5.2
    requirement 3. -/
abbrev Perm := ResourceId × StructuralClass

def memB (p : Perm) : List Perm → Bool
  | []      => false
  | q :: r  => (p == q) || memB p r

/-- `subB x y` : every permission in `x` is also in `y`. -/
def subB : List Perm → List Perm → Bool
  | [],     _ => true
  | p :: r, y => memB p y && subB r y

theorem memB_head (p : Perm) (r : List Perm) : memB p (p :: r) = true := by
  simp [memB]

theorem memB_tail {p q : Perm} {r : List Perm} (h : memB p r = true) :
    memB p (q :: r) = true := by
  simp [memB, h]

/-- Membership transfers along containment. -/
theorem memB_mono : ∀ {x y : List Perm}, subB x y = true →
    ∀ p, memB p x = true → memB p y = true := by
  intro x
  induction x with
  | nil => intro y _ p hp; simp [memB] at hp
  | cons q r ih =>
      intro y hsub p hp
      simp [subB] at hsub
      obtain ⟨hq, hr⟩ := hsub
      simp [memB] at hp
      cases hp with
      | inl heq => subst heq; exact hq
      | inr hin => exact ih hr p hin

/-- Containment survives adding a permission to the larger scope. -/
theorem subB_weaken : ∀ {x y : List Perm} (q : Perm),
    subB x y = true → subB x (q :: y) = true := by
  intro x
  induction x with
  | nil => intro y q _; rfl
  | cons p r ih =>
      intro y q h
      simp [subB] at h ⊢
      obtain ⟨hp, hr⟩ := h
      exact ⟨memB_tail hp, ih q hr⟩

theorem subB_refl : ∀ x : List Perm, subB x x = true := by
  intro x
  induction x with
  | nil => rfl
  | cons q r ih =>
      simp [subB, memB_head]
      exact subB_weaken q ih

theorem subB_trans : ∀ {a b c : List Perm},
    subB a b = true → subB b c = true → subB a c = true := by
  intro a
  induction a with
  | nil => intro _ _ _ _; rfl
  | cons q r ih =>
      intro b c hab hbc
      simp [subB] at hab ⊢
      obtain ⟨hq, hr⟩ := hab
      exact ⟨memB_mono hbc q hq, ih hr hbc⟩

/-- A capability model conforming to core §5.2. `contains a b` holds when the
    permissions of `b` are a subset of those of `a`. -/
def CapModel : AuthorityModel where
  Scope          := List Perm
  contains a b   := subB b a
  contains_refl  := subB_refl
  contains_trans := fun _ _ _ hab hbc => subB_trans hbc hab

/-- §5.2 is satisfiable: the theorems above hold of a concrete capability
    model with decidable, finite scopes. -/
example (ch : List (Delegation CapModel)) (holder : Principal)
    (root : CapModel.Scope) (hv : ChainValid CapModel holder root ch) :
    CapModel.contains root (effectiveScope CapModel root ch) = true :=
  chain_attenuates CapModel ch holder root hv

end Vstp
