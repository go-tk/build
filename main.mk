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
	@BUILD_DIR=$(build_dir)/docker
	export COMPOSE_FILE=$${BUILD_DIR}/docker-compose.yml$${COMPOSE_FILE:+$${COMPOSE_PATH_SEPARATOR:-:}$${COMPOSE_FILE}}
	export COMPOSE_PROJECT_NAME=$${COMPOSE_PROJECT_NAME:-$(notdir $(CURDIR))}
	trap 'docker-compose down --rmi=local --volumes --remove-orphans' EXIT
	docker-compose build
	docker-compose run --rm \
		--user=$${RUN_AS_USER:-$$(id -u):$$(id -g)} \
		--workdir=/data \
		--volume=$(CURDIR):/data \
		-e MAKEFLAGS="$${MAKEFLAGS}" \
		-e GOCACHE=/data/$${BUILD_DIR}/cache \
		-e GOMODCACHE=/data/$${BUILD_DIR}/mod-cache \
		build \
		make --makefile=$(makefile) $@ USE_DOCKER= _BUILD_DIR=$${BUILD_DIR}

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
.ONESHELL:
generate:
	@
ifdef PRE_GENERATE
	$(PRE_GENERATE)
endif
	go generate $(GO_GENERATE_FLAGS) ./...
ifdef POST_GENERATE
	$(POST_GENERATE)
endif

.PHONY: fmt
##
##  fmt:
##    Format source code with command 'goimports'.
##    Custom command-line options could be provided via variable 'GOIMPORTS_FLAGS'.
.ONESHELL:
fmt: | $(_BUILD_DIR)/bin/goimports
	@
ifdef PRE_FMT
	$(PRE_FMT)
endif
	go fmt -n ./... | grep -o '[^ ]\+.go$$' | xargs $| -format-only -l -w $(GOIMPORTS_FLAGS)
ifdef POST_FMT
	$(POST_FMT)
endif

$(_BUILD_DIR)/bin/goimports: | $(_BUILD_DIR)/bin/go.mod
	@cd $(@D); go build -o $(@F) golang.org/x/tools/cmd/goimports

.PHONY: lint
##
##  lint:
##    Check the coding style with command 'golint'.
##    Custom command-line options could be provided via variable 'GOLINT_FLAGS'.
.ONESHELL:
lint: | $(_BUILD_DIR)/bin/golint
	@
ifdef PRE_LINT
	$(PRE_LINT)
endif
	$| $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... | $(build_dir)/scripts/golint-filter.bash
ifdef POST_LINT
	$(POST_LINT)
endif

$(_BUILD_DIR)/bin/golint: | $(_BUILD_DIR)/bin/go.mod
	@cd $(@D); go build -o $(@F) golang.org/x/lint/golint

.PHONY: vet
##
##  vet:
##    Examine source code with command 'go vet'.
##    Custom command-line options could be provided via variable 'GO_VET_FLAGS'.
.ONESHELL:
vet:
	@
ifdef PRE_VET
	$(PRE_VET)
endif
	go vet $(GO_VET_FLAGS) ./...
ifdef POST_VET
	$(POST_VET)
endif

.PHONY: test
##
##  test:
##    Test packages with command 'go test'.
##    Custom command-line options could be provided via variable 'GO_TEST_FLAGS'.
.ONESHELL:
test:
	@
ifdef PRE_TEST
	$(PRE_TEST)
endif
	go test $(GO_TEST_FLAGS) ./...
ifdef POST_TEST
	$(POST_TEST)
endif

.PHONY: clean
##
##  clean:
##    Remove object files with command 'go clean'.
##    Custom command-line options could be provided via variable 'GO_CLEAN_FLAGS'.
.ONESHELL:
clean:
	@
ifdef PRE_CLEAN
	$(PRE_CLEAN)
endif
	go clean $(GO_CLEAN_FLAGS) ./...
ifdef POST_CLEAN
	$(POST_CLEAN)
endif

.PHONY: help
##
##  help:
##    display this help.
help: override .SHELLFLAGS := $(subst -o xtrace,,$(.SHELLFLAGS))
help:
	@sed -n 's/^##//p' $(makefile)

$(_BUILD_DIR)/bin/go.mod:
	@mkdir -p $(@D); cd $(@D); go mod init bin

##
##example:
##  make all GO_TEST_FLAGS='-race -cover'
endif ##############################################################################################
