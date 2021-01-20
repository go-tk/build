override SHELL := bash
override .SHELLFLAGS := -o errexit -o nounset -o pipefail -o xtrace -c
override .DEFAULT_GOAL := help

override makefile := $(lastword $(MAKEFILE_LIST))
override build_dir := $(patsubst %/,%,$(dir $(makefile)))

ifdef USE_DOCKER ###################################################################################
override targets := $(or $(MAKECMDGOALS),$(.DEFAULT_GOAL))

.PHONY: $(targets)
.ONESHELL:
$(targets):
	export BUILD_DIR=$(build_dir)/docker
	@cp go.{mod,sum} $${BUILD_DIR}
	export COMPOSE_FILE=$${BUILD_DIR}/docker-compose.yml$${COMPOSE_FILE:+$${COMPOSE_PATH_SEPARATOR:-:}$${COMPOSE_FILE}}
	export COMPOSE_PROJECT_NAME=$${COMPOSE_PROJECT_NAME:-$(notdir $(CURDIR))}
	trap "docker-compose down --rmi=local --remove-orphans" EXIT
	docker-compose build
	docker-compose run --rm build make $(MFLAGS) USE_DOCKER= _BUILD_DIR=$${BUILD_DIR} --makefile=$(makefile) $@

else ###############################################################################################
_BUILD_DIR := $(build_dir)

## targets:

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
fmt: | $(_BUILD_DIR)/bin/goimports
	@go fmt -n ./... | grep -o '[^ ]\+.go$$' | xargs $| -format-only -l -w $(GOIMPORTS_FLAGS)

$(_BUILD_DIR)/bin/goimports: | $(_BUILD_DIR)/bin/go.mod
	@cd $(@D); go build -o $(@F) golang.org/x/tools/cmd/goimports

.PHONY: lint
##
##  lint:
##    Check the coding style with command 'golint'.
##    Custom command-line options could be provided via variable 'GOLINT_FLAGS'.
lint: | $(_BUILD_DIR)/bin/golint
	@$| $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... | $(build_dir)/scripts/golint-filter.bash

$(_BUILD_DIR)/bin/golint: | $(_BUILD_DIR)/bin/go.mod
	@cd $(@D); go build -o $(@F) golang.org/x/lint/golint

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

$(_BUILD_DIR)/bin/go.mod:
	@mkdir --parents $(@D); cd $(@D); go mod init bin

##
##example:
##  make all GO_TEST_FLAGS='-race -cover'
endif ##############################################################################################
