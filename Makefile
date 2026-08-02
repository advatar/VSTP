DRAFT = draft-sellstrom-vstp-core-00

.PHONY: all clean check

all: $(DRAFT).txt $(DRAFT).html

$(DRAFT).xml: $(DRAFT).md
	kramdown-rfc2629 $< > $@

$(DRAFT).txt $(DRAFT).html: $(DRAFT).xml
	xml2rfc $< --text --html

# Fail on anything xml2rfc reports as an Error (warnings are tolerated).
check: $(DRAFT).xml
	@xml2rfc $(DRAFT).xml --text --html 2>&1 | tee /tmp/vstp-build.log
	@! grep -q ': Error:' /tmp/vstp-build.log || { echo "BUILD HAS ERRORS"; exit 1; }
	@echo "OK — no errors"

clean:
	rm -f $(DRAFT).xml $(DRAFT).txt $(DRAFT).html
