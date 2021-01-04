override SHELL := bash
override .SHELLFLAGS := -o errexit -o nounset -o pipefail -o xtrace -c

override build_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: all
all: generate fmt lint vet test

.PHONY: generate
generate:
	@go generate $(GO_GENERATE_FLAGS) ./...

.PHONY: fmt
fmt: | $(build_dir)/bin/goimports
	@go fmt -n ./... | grep --perl-regexp --only-matching '(?<=^| )[^ ]+\.go(?=$$| )' | xargs $| -format-only -l -w $(GOIMPORTS_FLAGS)

$(build_dir)/bin/goimports: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/goimports golang.org/x/tools/cmd/goimports

.PHONY: lint
lint: | $(build_dir)/bin/golint
	@$| $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... | $(build_dir)/scripts/golint-filter.bash

$(build_dir)/bin/golint: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/golint golang.org/x/lint/golint

.PHONY: vet
vet:
	@go vet $(GO_VET_FLAGS) ./...

.PHONY: test
test:
	@go test $(GO_TEST_FLAGS) ./...

.PHONY: clean
clean:
	@go clean $(GO_CLEAN_FLAGS) ./...

$(build_dir)/go.mod:
	@cd $(build_dir); go mod init build
