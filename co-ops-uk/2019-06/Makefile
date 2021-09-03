# Usage:
#
# EDITION=$edition make $target
#
# You need to supply $edition (one of dev, prod, or staging) and
# $target (one of those listed below).

SE_OPEN_DATA_DIR :=  $(shell bundle info se_open_data --path)

.PHONY: csv
csv:
	bundle exec make -f csv.mk edition=$(EDITION)

.PHONY: generate
generate:
	bundle exec make -f $(SE_OPEN_DATA_DIR)/makefiles/generate.mk edition=$(EDITION)

.PHONY: deploy
deploy:
	bundle exec make -f $(SE_OPEN_DATA_DIR)/makefiles/deploy.mk edition=$(EDITION)

.PHONY: triplestore
triplestore:
	bundle exec make -f $(SE_OPEN_DATA_DIR)/makefiles/triplestore.mk edition=$(EDITION)

.PHONY: clean
clean:
	rm -rf docs generated-data

.PHONY: install
install:
	bundle install

.PHONY: all
all: csv generate deploy triplestore
