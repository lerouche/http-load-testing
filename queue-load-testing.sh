#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

KEEPALIVE=false
SLEEP_DURATION_ARG="10"
REPORT_NAME="http-load-testing $(date)"
OUTPUT_DIR="~/http-load-testing-reports/"

TESTS=()

while [[ $# -gt 0 ]]; do
    ARG=$1

    case $ARG in
        -k|--keepalive)
            KEEPALIVE=true
            ;;

        -s|--sleep)
            SLEEP_DURATION_ARG="$2"
            shift
            ;;

        -n|--name)
            REPORT_NAME="$2"
            shift
            ;;

        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift
            ;;

        *)
            TESTS+=("$ARG")
            ;;
    esac
    shift
done

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"

for (( i=0; i<=$(( ${#TESTS[*]} - 1 )); i++ ))
do
    TEST_C_VAL="${TESTS[$i]}"
    ./load-testing -c "$TEST_C_VAL" -s "$SLEEP" -n "$REPORT_NAME (${TEST_C_VAL}c)"
    mv report.html "$OUTPUT_DIR/$REPORT_NAME-${TEST_C_VAL}c.html"
done

if [ "$KEEPALIVE" = true ]; then
    for (( j=0; j<=$(( ${#TESTS[*]} - 1 )); j++ ))
    do
        TEST_C_VAL="${TESTS[$j]}"
        ./load-testing -k -c "$TEST_C_VAL" -s "$SLEEP" -n "$REPORT_NAME (${TEST_C_VAL}c k)"
        mv report.html "$OUTPUT_DIR/$REPORT_NAME-${TEST_C_VAL}c-k.html"
    done
fi

exit 0
