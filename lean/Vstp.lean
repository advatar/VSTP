/-
  VSTP — formal model of draft-sellstrom-vstp-core-00.

  Scope: the four claims the specification asserts in prose and which are
  theorems rather than design choices. Deliberately NOT modelled: encodings,
  signatures, digests, transports. Those are checked by test vectors, not
  proofs.

  No mathlib dependency.
-/
import Vstp.Basic
import Vstp.Graph
import Vstp.Authority
import Vstp.Completeness
import Vstp.Assurance
