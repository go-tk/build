.ONESHELL:
export SHELL := bash
export SHELLOPTS := errexit:nounset:pipefail:xtrace

override source := $(shell find -path '*/.*' -prune -o -type f -name '*.go' -print)
override build_dir := $(dir $(lastword $(MAKEFILE_LIST)))

all: imports lint vet test

imports: force $(build_dir)bin/goimports $(source:%.go=$(build_dir)%.goimports)

$(build_dir)bin/goimports:
	go build -o $@ golang.org/x/tools/cmd/goimports

$(build_dir)%.goimports: %.go
	$(build_dir)bin/goimports -format-only -w $(IMPORTSFLAGS) $<
	install -D --mode a=r /dev/null $@

lint: force $(build_dir)bin/golint $(source:%.go=$(build_dir)%.golint)

$(build_dir)bin/golint:
	go build -o $@ golang.org/x/lint/golint

$(build_dir)%.golint: %.go
	$(build_dir)bin/golint -set_exit_status $(LINTFLAGS) $<
	install -D --mode a=r /dev/null $@

vet: force
	go vet $(VETFLAGS) ./...

test: force
	go test $(TESTFLAGS) ./...

clean: force
	go clean
	rm -rf $(build_dir)

.PHONY: force
force:
