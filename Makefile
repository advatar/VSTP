DRAFT = draft-sellstrom-vstp-core-00

.DELETE_ON_ERROR:

.PHONY: all clean check lean lean-check reference-check

all: $(DRAFT).txt $(DRAFT).html

# Verify the formal model. Fails the build on any sorry.
lean:
	cd lean && lake build

lean-check: lean
	@log=$$(mktemp /tmp/vstp-axioms.XXXXXX); trap 'rm -f "$$log"' EXIT; \
	cd lean && lake env lean check-axioms.lean >"$$log" 2>&1; rc=$$?; \
	cat "$$log"; test $$rc -eq 0 || exit $$rc; \
	! grep -q 'sorryAx' "$$log" || { echo "SORRY FOUND"; exit 1; }; \
	echo "OK — no sorry, standard axioms only"

reference-check:
	cargo test --manifest-path reference/Cargo.toml
	cargo run --quiet --manifest-path reference/Cargo.toml -- verify vectors/example-00/valid-genesis.json

$(DRAFT).xml: $(DRAFT).md
	kramdown-rfc2629 $< > $@

$(DRAFT).txt $(DRAFT).html: $(DRAFT).xml
	xml2rfc $< --text --html

# Fail on anything xml2rfc reports as an Error (warnings are tolerated).
check: $(DRAFT).xml
	@log=$$(mktemp /tmp/vstp-build.XXXXXX); trap 'rm -f "$$log"' EXIT; \
	xml2rfc $(DRAFT).xml --text --html >"$$log" 2>&1; rc=$$?; \
	cat "$$log"; test $$rc -eq 0 || exit $$rc; \
	! grep -q 'Error:' "$$log" || { echo "BUILD HAS ERRORS"; exit 1; }; \
	echo "OK — no errors"

clean:
	rm -f $(DRAFT).xml $(DRAFT).txt $(DRAFT).html
