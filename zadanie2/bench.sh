#!/bin/bash

echo "Usage:"
echo "LONG=1 ./bench.sh - to run all benchmarks"
echo "./bench.sh - to only run quick benchmarks"
echo "Requirements:"
echo "- install hyperfine (https://github.com/sharkdp/hyperfine)"
echo ""

set -euo pipefail
IFS=$'\n\t'

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
