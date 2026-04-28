# Include ODC common make targets
DEV_KIT_VERSION := v1.0.4
-include common.mk
common.mk:
	curl --fail -sSL https://raw.githubusercontent.com/opendefensecloud/dev-kit/$(DEV_KIT_VERSION)/common.mk -o common.mk.download && \
	mv common.mk.download $@

export GOPRIVATE=*.go.opendefense.cloud/testkit
export GNOSUMDB=*.go.opendefense.cloud/testkit
export GNOPROXY=*.go.opendefense.cloud/testkit

LICENSE := apache
LICENSE_COMMENT := BWI GmbH and Testkit contributors

.PHONY: fmt
fmt: $(GOLANGCI_LINT) ## Add license headers and format
	$(MAKE) addlicense license=$(LICENSE) comment='$(LICENSE_COMMENT)' pattern='*\.go'
	$(GO) fmt ./...
	$(GOLANGCI_LINT) run --fix

.PHONY: lint
lint: lint-no-golangci golangci-lint ## Run linters

.PHONY: lint-no-golangci
lint-no-golangci: $(ADDLICENSE)
	$(MAKE) addlicense-check license=$(LICENSE) comment='$(LICENSE_COMMENT)' pattern='*\.go'

.PHONY: test
test: $(GINKGO) ## Run all tests
	$(GINKGO) -r -cover --fail-fast --require-suite -covermode count --output-dir=$(BUILD_PATH) -coverprofile=testkit.coverprofile $(testargs)
