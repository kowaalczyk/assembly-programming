# Assignment 3

Test images are downloaded from the [course website](https://students.mimuw.edu.pl/~zbyszek/asm/image/).

Use `make` to build the executable, run `./brightness` to see usage instructions.

### Tests

In order to correctly clone the repo
you need to have [`git-lfs`](https://git-lfs.github.com/) installed.

Tests can be executed using `make test`.

More tests can be generated using [`tests/generate.py`](tests/generate.py)
script (requires `Python>=3.7`).

### Development

- Couldn't get [netpbm](<(http://netpbm.sourceforge.net/doc/)>) to install
  or build from source on the VM so I decided to implement a simple library myself
