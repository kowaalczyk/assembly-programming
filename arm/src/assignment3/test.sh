#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

FAILED_CASES=0

# print ppm file ($1) in a standardized way (1 value per line) for easy comparison
unpack_ppm() {
    out_file=${1%.ppm}.pixels
    tr -s '[[:punct:][:space:]]' '\n' <$1 >$out_file
    echo "$out_file"
}

# asserts that unpacked ppm version of files ($1 and $2) are equal
# returns number of rows that differ. Optionally saves digg to $3
assert_unpacked_eq() {
    out_file=${3-/dev/null}
    result=$(diff $(unpack_ppm $1) $(unpack_ppm $2) >$out_file)
    return $?
}

# wraps the test case function ($1) with printing & reporting logic,
# all consecutive parameters ($2, $3, $3, ...) are passed to function ($1)
test_case() {
    set +e
    $@
    if [[ $? -eq 0 ]]; then
        echo "."
    else
        echo "FAILED $1 (aguments: ${@:2})"
        FAILED_CASES=$((FAILED_CASES + 1))
    fi
    set -e
}

conclude_tests() {
    if [[ $FAILED_CASES -eq 0 ]]; then
        echo "All tests passed"
    else
        echo "Failed $FAILED_CASES test cases"
    fi
    return $FAILED_CASES
}

apple_same_red() {
    wdir="./tests/apple-same-any"

    ./brightness r 0 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/Yinput.ppm $wdir/output.ppm $wdir/red.diff)
    return $result
}

apple_same_green() {
    wdir="./tests/apple-same-any"

    ./brightness g 0 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/Yinput.ppm $wdir/output.ppm $wdir/green.diff)
    return $result
}

apple_same_blue() {
    wdir="./tests/apple-same-any"

    ./brightness b 0 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/Yinput.ppm $wdir/output.ppm $wdir/blue.diff)
    return $result
}

apple_zeros_red() {
    wdir="./tests/apple-zeros-red"

    ./brightness r -128 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness r -128 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

apple_zeros_green() {
    wdir="./tests/apple-zeros-green"

    ./brightness g -128 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness g -128 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

apple_zeros_blue() {
    wdir="./tests/apple-zeros-blue"

    ./brightness b -128 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness b -128 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

apple_maxval_red() {
    wdir="./tests/apple-maxval-red"

    ./brightness r 127 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness r 127 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness r 127 $wdir/YYinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

apple_maxval_green() {
    wdir="./tests/apple-maxval-green"

    ./brightness g 127 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness g 127 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness g 127 $wdir/YYinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

apple_maxval_blue() {
    wdir="./tests/apple-maxval-blue"

    ./brightness b 127 $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness b 127 $wdir/Yinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi
    ./brightness b 127 $wdir/YYinput.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/YYYinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

# generates basic test case by passing input.ppm to application
# and comparing it with output.ppm in the same directory (argument$1)
# program arguments are set using $2 (color) and $3 (brightness change)
basic_test() {
    wdir="$1"

    ./brightness "$2" "$3" $wdir/input.ppm
    if [[ $? -ne 0 ]]; then return 1; fi

    result=$(assert_unpacked_eq $wdir/Yinput.ppm $wdir/output.ppm $wdir/diff)
    return $result
}

# transformation is an identity when brightness change is set to 0
test_case apple_same_red
test_case apple_same_green
test_case apple_same_blue

# saturation: color value is zero if decreased by more than its original value
test_case apple_zeros_red
test_case apple_zeros_green
test_case apple_zeros_blue

# saturation: color value is equal to maxval (255) if increased beyond it
test_case apple_maxval_red
test_case apple_maxval_green
test_case apple_maxval_blue

# test adding 10 to all colors
test_case basic_test "./tests/apple-plus10-red" 'r' '10'
test_case basic_test "./tests/apple-plus10-green" 'g' '10'
test_case basic_test "./tests/apple-plus10-blue" 'b' '10'

# test subtracting 10 from all colors
test_case basic_test "./tests/apple-minus10-red" 'r' '-10'
test_case basic_test "./tests/apple-minus10-green" 'g' '-10'
test_case basic_test "./tests/apple-minus10-blue" 'b' '-10'

# 2 more tests on another image just to be sure
test_case basic_test "./tests/duck-minus100-red" 'r' '-100'
test_case basic_test "./tests/duck-plus100-red" 'r' '100'

conclude_tests
