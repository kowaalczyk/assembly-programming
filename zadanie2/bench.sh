#!/bin/bash

# Usage:
# LONG=1 ./bench.sh - to run all benchmarks
# ./bench.sh - to only run quick benchmarks
# Requirements:
# - install hyperfine (https://github.com/sharkdp/hyperfine)

set -euo pipefail
IFS=$'\n\t'

# compile the testing program
make pollution

test_dir="$(pwd)/bench"
echo "Running in:"
echo "$test_dir"
echo ""

LONG=${LONG:-}

for test_in in "$test_dir"/*.in; do
  test_name="${test_in%.in}"
  >&2 echo "$test_name..."

  infile="${test_name}.in"

  if [[ "$infile" == *_long.in && -z "$LONG" ]]; then
    >&2 echo "SKIPPED"
    continue
  fi

  # run benchmarks
  hyperfine --warmup 3 "./pollution < $infile >/dev/null"

  # mark test as passed to indicate progress
  >&2 echo "DONE"
done
