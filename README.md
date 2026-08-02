# VSTP — Verifiable State Transition Protocol

An implementation-independent protocol for recording, exchanging, and
independently verifying claims about transitions between committed states of
identified resources.

A VSTP record binds a prior state commitment and a resulting state commitment
to the principals that caused the transition, **the authority under which they
were permitted to cause it**, and the evidence supporting each of those claims.
Recorded transitions form a content-addressed causal graph. Provenance, audit
trails, and change histories are derived views over that graph rather than
separate constructs.

The defining abstraction:

> An act is a verifiable transition between committed states, performed by an
> identified principal under specified authority.

---

## What distinguishes it

Provenance systems answer *what happened*. Transparency systems answer *what
was registered*. Neither answers *who was permitted*.

VSTP requires every recorded transition to carry the authority under which it
was permitted and a commitment to the authorization decision, in a form that
lets an independent verifier re-derive that decision. That is the contribution;
the rest of the specification is engineering around it.

Two further requirements follow from taking verification seriously:

- **Completeness is declared, not assumed.** A hash chain proves recorded
  transitions were not altered. It proves nothing about transitions never
  recorded. Every context declares how thoroughly state-changing paths were
  mediated, and no verifier may report a stronger conclusion than the evidence
  supports. Continuity checking additionally *detects* out-of-band modification
  wherever a resource is re-observed, bounding the undetectability window to
  the observation interval.

- **Verification returns a vector, not a verdict.** Record integrity,
  authority, approval, existence time, and completeness are independent
  properties. A single badge necessarily overstates the weak ones. A summary
  may be emitted only when it is attributable to a named, published assurance
  policy.

All conforming cryptographic profiles are post-quantum. Classical-only
signature modes are not conforming; hybrids are permitted only when acceptance
requires the post-quantum component over the complete signed input.

---

## Documents

| File | Status | Contents |
|---|---|---|
| `draft-sellstrom-vstp-core-00.md` | Normative | The core specification. Data model, authority requirements, epistemic typing, completeness, verification, disclosure, profiles, IANA registries, security and privacy considerations. |
| `RATIONALE.md` | Informative | Why the specification is shaped this way. Rejected designs, comparison with related work, open questions. |
| `PROFILES.md` | Informative | Checklist and template for authoring a domain profile, with the failure modes to check before publishing. |
| `lean/` | Informative | Lean 4 model and machine-checked proofs of graph acyclicity, authority attenuation, completeness limits, and assurance monotonicity. |
| `profiles/example-00.md` | Informative | Minimal post-quantum profile used by the executable test vectors. |
| `reference/` | Informative | Rust offline verifier for Example Profile 00. |
| `vectors/example-00/` | Informative | Deterministic positive and negative conformance vectors with expected reports. |

Read `RATIONALE.md` first if you want the argument; read the draft if you want
the requirements.

---

## Status

Individual draft, pre-submission. Not adopted by any working group and not
endorsed by any standards body. The core specification is written in
kramdown-rfc format and targets Internet-Draft submission; the choice of venue
is not settled, and the content is equally viable as a W3C or ISO input with
front-matter changes only.

Not implemented. No test vectors yet — these are required for conformance
(core §14) and are expected in a companion document.

### Building the draft

```
gem install kramdown-rfc      # provides kramdown-rfc2629
pipx install xml2rfc

make            # produces .txt and .html
make check      # build and fail on any xml2rfc Error
make lean       # build the Lean 4 formal model
make lean-check # build it and audit theorem axioms / reject sorry
make reference-check # test the post-quantum reference verifier and vectors
make clean
```

Builds to a 52-page Internet-Draft with no errors. All bibliography entries are
defined inline in the front matter, and `.refcache/` is committed, so the build
requires **no network access** — `bib.ietf.org` is unreachable from some
networks and the default fetch path hangs for ~30s per reference.

The Markdown is readable as-is; `{{...}}` are cross-references and citations
that resolve at build time.

---

## Scope boundaries

VSTP deliberately does **not** define an identity system, a policy language, a
serialization, a transport, a ledger, a diff format, or an ontology of actions.
Each is supplied by a profile or by a referenced external specification. A core
that selects any of them inherits that choice's lifetime and governance, and
becomes unusable in every deployment that has already chosen differently.

It is designed to **carry** rather than replace existing work: W3C PROV-DM,
C2PA, in-toto/SLSA, IETF SCITT, W3C Verifiable Credentials, RFC 3161
timestamping, and RFC 9162 transparency logs are all usable as VSTP evidence,
each contributing to specifically named assurance dimensions and no others.

---

## Open questions

Recorded honestly in `RATIONALE.md` §10 rather than papered over. In short:
whether a mandatory-to-implement encoding is needed; whether checkpoint
accumulators must support non-inclusion proofs; how revocation timing semantics
should be constrained; how graphs spanning contexts compose; and which domain
should be profiled first.

---

## Contributing

Review of the normative sections is the most useful contribution, particularly
§5 (Authority), §7 (Completeness), and §11–12 (Security and Privacy
Considerations). Objections to the rejected designs in `RATIONALE.md` §8 are
welcome and should reference the argument given there.

## License

To be determined before submission. Contributions are expected to be made under
terms compatible with the intended standards venue.
