/-
  Axiom audit. Run with `lake env lean check-axioms.lean`, or `make lean-check`
  from the repository root.

  A formal model is only worth what its axioms allow. Every theorem below must
  depend on nothing beyond Lean's standard three (`propext`,
  `Classical.choice`, `Quot.sound`). Anything else — `sorryAx` above all —
  means a claimed proof is not a proof.
-/
import Vstp
open Vstp

-- §3.2  Acyclicity
#print axioms Vstp.acyclic
#print axioms Vstp.no_self_parent
#print axioms Vstp.no_mutual_reach

-- §5.2  Authority: attenuation and non-amplification
#print axioms Vstp.chain_attenuates
#print axioms Vstp.no_amplification
#print axioms Vstp.extension_cannot_recover

-- §5.2  Satisfiability: the worked capability instance
#print axioms Vstp.subB_refl
#print axioms Vstp.subB_trans

-- §7.1  Integrity does not imply completeness
#print axioms Vstp.integrity_does_not_imply_completeness
#print axioms Vstp.continuity_does_not_imply_completeness
#print axioms Vstp.observed_states_are_real
#print axioms Vstp.observations_are_bounded
#print axioms Vstp.observed_commitment_occurred

-- §6, §8.4  Assurance: monotonicity and no silent upgrade
#print axioms Vstp.assess_monotone
#print axioms Vstp.assess_supports
#print axioms Vstp.self_assertion_irrelevant
#print axioms Vstp.self_signed_caps_at_declared
#print axioms Vstp.witness_does_not_reach_verified
