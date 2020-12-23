# build

Generic Makefile for Go projects

## Quick Start

```bash
cd PATH/TO/PROJECT/DIR

tee make.sh <<-EOF
	#!/usr/bin/env sh

	(test -d build || git clone --depth 1 https://github.com/go-tk/build.git) && gmake -f build/go.mk "\$@"
EOF
chmod +x make.sh

./make.sh all
```
