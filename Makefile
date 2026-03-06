
# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

# Set MAKEFLAGS to suppress entering/leaving directory messages
MAKEFLAGS += --no-print-directory

BUILD_PATH ?= $(shell pwd)
HACK_DIR ?= $(shell cd hack 2>/dev/null && pwd)
LOCALBIN ?= $(BUILD_PATH)/bin

OS := $(shell go env GOOS)
ARCH := $(shell go env GOARCH)

GO ?= go
SHELLCHECK ?= shellcheck
OSV_SCANNER ?= osv-scanner
MKDOCS ?= mkdocs
DOCKER ?= docker
GINKGO ?= $(LOCALBIN)/ginkgo
GOLANGCI_LINT ?= $(LOCALBIN)/golangci-lint
SETUP_ENVTEST ?= $(LOCALBIN)/setup-envtest
ADDLICENSE ?= $(LOCALBIN)/addlicense
CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen
OPENAPI_GEN ?= $(LOCALBIN)/openapi-gen
CRD_REF_DOCS ?= $(LOCALBIN)/crd-ref-docs
OCM ?= $(LOCALBIN)/ocm

GINKGO_VERSION ?= $(shell go list -json -m -u github.com/onsi/ginkgo/v2 | jq -r '.Version')
GOLANGCI_LINT_VERSION ?= v2.10.1
SETUP_ENVTEST_VERSION ?= release-0.22
ADDLICENSE_VERSION ?= v1.1.1
CRD_REF_DOCS_VERSION ?= v0.2.0

export GOPRIVATE=*.go.opendefense.cloud/testkit
export GNOSUMDB=*.go.opendefense.cloud/testkit
export GNOPROXY=*.go.opendefense.cloud/testkit

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: clean
clean:
	rm -rf $(LOCALBIN)


.PHONY: fmt
fmt: addlicense golangci-lint ## Add license headers and format
	echo $(ADDLICENCE)
	find . -not -path '*/.*' -name '*.go' -exec $(ADDLICENSE) -c 'BWI GmbH and Testkit contributors' -l apache -s=only {} +
	$(GO) fmt ./...
	$(GOLANGCI_LINT) run --fix

.PHONY: mod
mod: ## Do go mod tidy, download, verify
	@$(GO) mod tidy
	@$(GO) mod download
	@$(GO) mod verify

.PHONY: lint
lint: lint-no-golangci golangci-lint ## Run linters such as golangci-lint and addlicence checks
	$(GOLANGCI_LINT) run -v

.PHONY: lint-no-golangci
lint-no-golangci: addlicense
	find . -not -path '*/.*' -name '*.go' -exec $(ADDLICENSE) -check -l apache -s=only {} ';'

.PHONY: scan
scan:
	$(OSV_SCANNER) scan --config ./.osv-scanner.toml -r .

.PHONY: test
test: ginkgo ## Run all tests
	$(GINKGO) -r -cover --fail-fast --require-suite -covermode count --output-dir=$(BUILD_PATH) -coverprofile=testkit.coverprofile $(testargs)

TIMESTAMP ?= $(shell date '+%Y%m%d%H%M%S')

$(LOCALBIN):
	mkdir -p $(LOCALBIN)

.PHONY: golangci-lint
golangci-lint: $(LOCALBIN) ## Download golangci-lint locally if necessary.
	@test -s $(LOCALBIN)/golangci-lint && $(LOCALBIN)/golangci-lint --version | grep -q $(GOLANGCI_LINT_VERSION) || \
	GOBIN=$(LOCALBIN) go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

.PHONY: ginkgo
ginkgo: $(LOCALBIN) ## Download ginkgo locally if necessary.
	@test -s $(LOCALBIN)/ginkgo && $(LOCALBIN)/ginkgo version | grep -q $(subst v,,$(GINKGO_VERSION)) || \
	GOBIN=$(LOCALBIN) go install github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

.PHONY: addlicense
addlicense: $(LOCALBIN) ## Download addlicense locally if necessary.
	@test -s $(LOCALBIN)/addlicense && grep -q $(ADDLICENSE_VERSION) $(LOCALBIN)/.addlicense-version 2>/dev/null || \
	GOBIN=$(LOCALBIN) go install github.com/google/addlicense@$(ADDLICENSE_VERSION); \
	echo $(ADDLICENSE_VERSION) > $(LOCALBIN)/.addlicense-version



.PHONY: crd-ref-docs
crd-ref-docs: $(LOCALBIN) ## Download crd-ref-docs locally if necessary.
	@test -s $(LOCALBIN)/crd-ref-docs && $(LOCALBIN)/crd-ref-docs --version | grep -q $(CRD_REF_DOCS_VERSION) || \
	GOBIN=$(LOCALBIN) go install github.com/elastic/crd-ref-docs@$(CRD_REF_DOCS_VERSION)