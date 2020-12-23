override SHELL := /usr/bin/env bash -euxo pipefail

ifneq ($(filter all imports lint,$(or $(MAKECMDGOALS),all)),)
override sources := $(shell find -path '*/.*' -prune -o -type f -name '*.go' -printf '%P\n')
endif
override build_dir := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: all
all: generate imports lint vet test

.PHONY: generate
generate:
	go generate $(GENERATEFLAGS) ./...

.PHONY: imports
imports: $(sources:%.go=$(build_dir)%.goimports)

.PHONY: lint
lint: $(sources:%.go=$(build_dir)%.golint)

.PHONY: vet
vet:
	go vet $(VETFLAGS) ./...

.PHONY: test
test:
	go test $(TESTFLAGS) ./...

.PHONY: clean
clean:
	go clean
	cd $(build_dir) && git clean -dfx --exclude=/EXPIRATION_DATE

$(build_dir)%.goimports: %.go | $(build_dir)bin/goimports
	$(build_dir)bin/goimports -format-only -w $(IMPORTSFLAGS) $< && install -D --mode=a=r /dev/null $@

$(build_dir)bin/goimports: | $(build_dir)go.mod
	cd $(build_dir) && go build -o bin/goimports golang.org/x/tools/cmd/goimports

$(build_dir)%.golint: %.go | $(build_dir)bin/golint
	GOLINT=$(build_dir)bin/golint $(build_dir)scripts/golint-wrapper.bash $(LINTFLAGS) $< && install -D --mode=a=r /dev/null $@

$(build_dir)bin/golint: | $(build_dir)go.mod
	cd $(build_dir) && go build -o bin/golint golang.org/x/lint/golint

$(build_dir)go.mod:
	cd $(build_dir) && go mod init build
