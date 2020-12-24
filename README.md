# build

Generic makefile for Go projects

## Targets

- **all**: The combination of target **generate**, **fmt**, **lint**, **vet** and **test**.

- **generate**: Generate files with command `go generate`.

  *Custom command-line options could be provided via variable `GO_GENERATE_FLAGS`.*

- **fmt**: Format source code with command `goimports`.

  *Custom command-line options could be provided via variable `GOIMPORTS_FLAGS`.*

- **lint**: Check the coding style with command `golint`.

  *Custom command-line options could be provided via variable `GOLINT_FLAGS`.*

- **vet**: Examine source code with command `go vet`.

  *Custom command-line options could be provided via variable `GO_VET_FLAGS`.*

- **test**: Test packages with command `go test`.

  *Custom command-line options could be provided via variable `GO_TEST_FLAGS`.*

- **clean**: Remove object files with command `go clean`.

## Quick Start

1. ```bash
   cd PATH/TO/PROJECT/DIR
   ```

2. ```bash
   curl -Lo GNUmakefile https://raw.githubusercontent.com/go-tk/build/master/GNUmakefile.orig
   ```

3. ```bash
   make all GO_TEST_FLAGS='-count=1 -v'
   ```
