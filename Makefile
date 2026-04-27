# Include ODC common make targets
DEV_KIT_VERSION := v1.0.2
-include common.mk
common.mk:
	curl --fail -sSL https://raw.githubusercontent.com/opendefensecloud/dev-kit/$(DEV_KIT_VERSION)/common.mk -o common.mk.download && \
	mv common.mk.download $@

export GOPRIVATE=*.go.opendefense.cloud/testkit
export GNOSUMDB=*.go.opendefense.cloud/testkit
export GNOPROXY=*.go.opendefense.cloud/testkit

.PHONY: fmt
fmt: $(GOLANGCI_LINT) $(ADDLICENSE) ## Add license headers and format
	echo $(ADDLICENCE)
	git ls-files | grep '.*\.go$$' | xargs $(ADDLICENSE) -c 'BWI GmbH and Testkit contributors' -l apache -s=only
	$(GO) fmt ./...
	$(GOLANGCI_LINT) run --fix

.PHONY: lint
lint: lint-no-golangci golangci-lint ## Run linters

.PHONY: lint-no-golangci
lint-no-golangci: $(ADDLICENSE)
	git ls-files | grep '.*\.go$$' | xargs $(ADDLICENSE) -check -l apache -s=only -check

.PHONY: test
test: $(GINKGO) ## Run all tests
	$(GINKGO) -r -cover --fail-fast --require-suite -covermode count --output-dir=$(BUILD_PATH) -coverprofile=testkit.coverprofile $(testargs)
