# Usage:
#
# EDITION=$edition make $target
#
# You need to supply $edition (one of dev, prod, or staging) and
# $target (one of those listed below).

.PHONY: csv
csv:
	make -f csv.mk edition=$(EDITION)

.PHONY: generate
generate:
	make -f ../../tools/se_open_data/makefiles/generate.mk edition=$(EDITION)

.PHONY: deploy
deploy:
	make -f ../../tools/se_open_data/makefiles/deploy.mk edition=$(EDITION)

.PHONY: triplestore
triplestore:
	make -f ../../tools/se_open_data/makefiles/triplestore.mk edition=$(EDITION)

.PHONY: clean
clean:
	rm -rf docs generated-data

.PHONY: all
all: csv generate deploy triplestore
