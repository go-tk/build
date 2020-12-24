override SHELL := bash
override .SHELLFLAGS := -o errexit -o nounset -o pipefail -o xtrace -c

override build_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
override go_dirs := $(shell go list -f {{.Dir}} ./... | xargs realpath --relative-to=.)
override go_files := $(foreach go_dir,$(go_dirs),$(wildcard $(go_dir)/*.go))

.PHONY: all
all: generate fmt lint vet test

.PHONY: generate
generate:
	@go generate $(GO_GENERATE_FLAGS) ./...

.PHONY: fmt
fmt: | $(build_dir)/bin/goimports
	$(build_dir)/bin/goimports -format-only -w $(GOIMPORTS_FLAGS) $(go_files)

.PHONY: lint
lint: | $(build_dir)/bin/golint
	@$(build_dir)/bin/golint $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... | $(build_dir)/scripts/golint-filter.bash

.PHONY: vet
vet:
	@go vet $(GO_VET_FLAGS) ./...

.PHONY: test
test:
	@go test $(GO_TEST_FLAGS) ./...

.PHONY: clean
clean:
	@go clean

$(build_dir)/bin/goimports: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/goimports golang.org/x/tools/cmd/goimports

$(build_dir)/bin/golint: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/golint golang.org/x/lint/golint

$(build_dir)/go.mod:
	@cd $(build_dir); go mod init build
