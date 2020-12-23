# build

Generic Makefile for Go projects

## Targets

- **all**: The combination of target **generate**, **imports**, **lint**, **vet** and **test**.

- **generate**: Generate files with command `go generate`.

  *Custom command-line options could be provided via variable `GENERATEFLAGS`.*

- **imports**: Format source code with command `goimports`.

  *Custom command-line options could be provided via variable `IMPORTSFLAGS`.*

- **lint**: Check the coding style with command `golint`.

  *Custom command-line options could be provided via variable `LINTFLAGS`.*

- **vet**: Examine source code with command `go vet`.

  *Custom command-line options could be provided via variable `VETFLAGS`.*

- **test**: Test packages with command `go test`.

  *Custom command-line options could be provided via variable `TESTFLAGS`.*

- **clean**: Remove object files and cache files.

## Quick Start

1. ```bash
   cd PATH/TO/PROJECT/DIR
   ```

2. ```bash
   curl -Lo make.bash https://raw.githubusercontent.com/go-tk/build/master/make.bash.orig
   chmod +x make.bash
   ```

3. ```bash
   ./make.bash all TESTFLAGS=-v
   ```
