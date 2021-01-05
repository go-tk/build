override SHELL := bash
override .SHELLFLAGS := -o errexit -o nounset -o pipefail -o xtrace -c
override .DEFAULT_GOAL := help

override makefile := $(lastword $(MAKEFILE_LIST))
override build_dir := $(patsubst %/,%,$(dir $(makefile)))

##targets:

.PHONY: all
##  all: generate & fmt & lint & vet & test
all: generate fmt lint vet test

.PHONY: generate
##
##  generate:
##    Generate files with command 'go generate'.
##    Custom command-line options could be provided via variable 'GO_GENERATE_FLAGS'.
generate:
	@go generate $(GO_GENERATE_FLAGS) ./...

.PHONY: fmt
##
##  fmt:
##    Format source code with command 'goimports'.
##    Custom command-line options could be provided via variable 'GOIMPORTS_FLAGS'.
fmt: | $(build_dir)/bin/goimports
	@go fmt -n ./... | grep --perl-regexp --only-matching '(?<=^| )[^ ]+\.go(?=$$| )' | xargs $| -format-only -l -w $(GOIMPORTS_FLAGS)

$(build_dir)/bin/goimports: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/goimports golang.org/x/tools/cmd/goimports

.PHONY: lint
##
##  lint:
##    Check the coding style with command 'golint'.
##    Custom command-line options could be provided via variable 'GOLINT_FLAGS'.
lint: | $(build_dir)/bin/golint
	@$| $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... | $(build_dir)/scripts/golint-filter.bash

$(build_dir)/bin/golint: | $(build_dir)/go.mod
	@cd $(build_dir); go build -o bin/golint golang.org/x/lint/golint

.PHONY: vet
##
##  vet:
##    Examine source code with command 'go vet'.
##    Custom command-line options could be provided via variable 'GO_VET_FLAGS'.
vet:
	@go vet $(GO_VET_FLAGS) ./...

.PHONY: test
##
##  test:
##    Test packages with command 'go test'.
##    Custom command-line options could be provided via variable 'GO_TEST_FLAGS'.
test:
	@go test $(GO_TEST_FLAGS) ./...

.PHONY: clean
##
##  clean:
##    Remove object files with command 'go clean'.
##    Custom command-line options could be provided via variable 'GO_CLEAN_FLAGS'.
clean:
	@go clean $(GO_CLEAN_FLAGS) ./...

.PHONY: help
##
##  help:
##    display this help.
help: override .SHELLFLAGS := $(subst -o xtrace,,$(.SHELLFLAGS))
help:
	@sed -n 's/^##//p' $(makefile)

$(build_dir)/go.mod:
	@cd $(build_dir); go mod init build

##
##example:
##  make all GO_TEST_FLAGS='-race -cover'
