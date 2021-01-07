#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


# compile the testing program
make pollution

test_dir="$(pwd)/tests"
echo "Running in:"
echo "$test_dir"
echo ""

failed_cases=0

for test_in in "$test_dir"/*.in; do
  test_name="${test_in%.in}"

  infile="${test_name}.in"
  realout="${test_name}.realout"
  expout="${test_name}.out"
  logfile="${test_name}.log"

  # execute the program
  set +e
  ./pollution < "$infile" > "$realout" 2> "$logfile"
  retval=$?
  set -e

  if [[ $retval -ne 0 ]]; then
    echo "ERROR $test_name"
    failed_cases=$((failed_cases + 1))
    continue
  fi

  # check program output
  set +e
  out=$(diff "$realout" "$expout")
  retval=$?
  set -e

  if [[ $retval -ne 0 ]]; then
    echo "FAILED $test_name"
    failed_cases=$((failed_cases + 1))
    continue
  fi

  # mark test as passed to indicate progress
  echo "."

  # clean generated files for test cases that passed
done

if [[ $failed_cases -gt 0 ]]; then
  echo "Failed $failed_cases tests"
else
  echo "All tests passed"
fi

exit $failed_cases
