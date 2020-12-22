override SHELL := /usr/bin/env bash -euxo pipefail

override sources := $(shell find -path '*/.*' -prune -o -type f -name '*.go' -printf '%P\n')
override build_dir := $(dir $(lastword $(MAKEFILE_LIST)))

all: imports lint vet test

imports: force $(build_dir)bin/goimports $(sources:%.go=$(build_dir)%.goimports)
$(build_dir)bin/goimports:
	go build -o $@ golang.org/x/tools/cmd/goimports
$(build_dir)%.goimports: %.go
	$(build_dir)bin/goimports -format-only -w $(IMPORTSFLAGS) $< && install -D --mode a=r /dev/null $@

lint: force $(build_dir)bin/golint $(sources:%.go=$(build_dir)%.golint)
$(build_dir)bin/golint:
	go build -o $@ golang.org/x/lint/golint
$(build_dir)%.golint: %.go
	GOLINT=$(build_dir)bin/golint $(build_dir)scripts/golint-wrapper.bash $(LINTFLAGS) $< && install -D --mode a=r /dev/null $@

vet: force
	go vet $(VETFLAGS) ./...

test: force
	go test $(TESTFLAGS) ./...

clean: force
	go clean
	rm -rf $(build_dir)

.PHONY: force
force:
