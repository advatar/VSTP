# VSTP Example Profile 00

Status: informative, experimental, and not suitable for production deployment.

This profile makes the smallest set of choices needed for deterministic VSTP
test vectors and an offline reference verifier. It does not modify the core
specification. Its cryptography is post-quantum only; conforming objects MUST
NOT substitute a classical signature or a classical/PQ hybrid.

## Encoding and identifiers

Objects use UTF-8 JSON. Canonical JSON has no insignificant whitespace, sorts
object member names by Unicode code point, preserves array order, and permits
only integers (no floating-point values). Strings use JSON escaping.

A digest input is `VSTP-EXAMPLE-00`, one zero byte, the ASCII domain label, one
zero byte, and the content bytes. The transition domain label is
`transition:v1`; the UTF-8 state domain label is `state:utf8-text:v1`.

A transition identifier is the lowercase hexadecimal SHA-384 domain digest of
the canonical JSON encoding of these fields: `parents`, `prior_states`,
`resulting_states`, `actor`, `recorder`, `sequence`, and `structural_class`.
The `id` and `signature` fields are excluded.

SHA-384 is mandatory for object identifiers and state commitments. Its
384-bit output retains a 192-bit generic preimage margin under Grover search.

## Signatures and principals

Signatures MUST use ML-DSA-65 as standardized in FIPS 204. Public keys and
signatures are lowercase hexadecimal encodings of the FIPS 204 byte strings.
The signature input is the 48 raw bytes represented by the transition ID, not
its 96-character hexadecimal representation. Signing is deterministic with an
empty context string so vectors are reproducible.

A principal is an opaque URI. The bundle maps it to exactly one disclosed
ML-DSA-65 public key. Key resolution is therefore offline. Example 00 defines
no key rotation or revocation and MUST NOT be used where either is required.

## Resources and representation

The only representation profile is `utf8-text` version 1. State content is the
exact UTF-8 byte sequence in the bundle's `content` string, with no newline or
Unicode normalization beyond the characters actually encoded. Its commitment
algorithm is `sha-384`.

## Authority

Authority is a finite set of `(resource, structural_class)` permissions.
Containment is subset. Each disclosed delegation MUST be issued by the current
holder and its scope MUST be a subset of the preceding scope. The final holder
MUST equal the transition actor, and its effective scope MUST contain every
resource/class pair exercised by the transition.

Delegations and authority material are evaluated from the bundle without an
online service. Revocation is unsupported; this limitation is why the profile
is experimental.

## Verification output

The reference verifier returns the recomputed identifier, a structured
assurance vector, and registered-style finding strings. A genesis transition
has `graph_continuity: not-established`, because it has no parent to check.
`disclosure_completeness` is only `declared`; a self-contained bundle does not
prove that no relevant object was withheld.

## Security note

ML-DSA-65 is the only signature algorithm accepted. Algorithm agility in the
core does not authorize downgrade within this profile. Implementations MUST
fail closed on any other signature algorithm or malformed key/signature size.
