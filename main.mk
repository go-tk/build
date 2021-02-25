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
	@export COMPOSE_FILE=$(build_dir)/docker/docker-compose.yml$(if $(COMPOSE_FILE),$(or $(COMPOSE_PATH_SEPARATOR),:)$(COMPOSE_FILE))
	export COMPOSE_PROJECT_NAME=$(or $(COMPOSE_PROJECT_NAME),$(notdir $(CURDIR))-build)
	trap 'docker-compose down --rmi=local --volumes --remove-orphans' EXIT
	docker-compose build --build-arg ALPINE_PACKAGES='bash coreutils findutils grep sed make gcc musl-dev $(ALPINE_PACKAGES)'
	docker-compose run --rm \
		--user=$(or $(RUN_AS_USER),$$(id -u):$$(id -g)) \
		--workdir=/data \
		--volume=$(CURDIR):/data \
		-e MAKEFLAGS="$${MAKEFLAGS}" \
		-e GOCACHE=/data/$(build_dir)/go/cache \
		-e GOMODCACHE=/data/$(build_dir)/go/mod-cache \
		build \
		make --makefile=$(makefile) $@ \
			USE_DOCKER= \
			COMPOSE_FILE= \
			COMPOSE_PATH_SEPARATOR= \
			COMPOSE_PROJECT_NAME= \
			ALPINE_PACKAGES=

else ###############################################################################################
override os_arch := $(shell go env GOOS)_$(shell go env GOARCH)

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
fmt: | $(build_dir)/go/tools/goimports.$(os_arch)
	@
ifdef PRE_FMT
	$(PRE_FMT)
endif
	go fmt -n ./... |
		grep --perl-regexp --only-matching --null-data '(?<= -l -w ).+(?=\n)' |
		xargs --null $| -format-only -l -w $(GOIMPORTS_FLAGS)
ifdef POST_FMT
	$(POST_FMT)
endif

.ONESHELL:
$(build_dir)/go/tools/goimports.$(os_arch): | $(build_dir)/go/tools/go.mod
	@cd $(@D)
	go get golang.org/x/tools/cmd/goimports
	go build -o $(@F) golang.org/x/tools/cmd/goimports

.PHONY: lint
##
##  lint:
##    Check the coding style with command 'golint'.
##    Custom command-line options could be provided via variable 'GOLINT_FLAGS'.
.ONESHELL:
lint: | $(build_dir)/go/tools/golint.$(os_arch)
	@
ifdef PRE_LINT
	$(PRE_LINT)
endif
	$| $(filter-out -set_exit_status,$(GOLINT_FLAGS)) ./... |
		$(build_dir)/scripts/golint-filter.bash
ifdef POST_LINT
	$(POST_LINT)
endif

.ONESHELL:
$(build_dir)/go/tools/golint.$(os_arch): | $(build_dir)/go/tools/go.mod
	@cd $(@D)
	go get golang.org/x/lint/golint
	go build -o $(@F) golang.org/x/lint/golint

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
	@sed --silent 's/^##//p' $(makefile)

$(build_dir)/go/tools/go.mod:
	@mkdir --parents $(@D); cd $(@D); go mod init tools

##
##example:
##  make all GO_TEST_FLAGS='-race -cover'
endif ##############################################################################################
