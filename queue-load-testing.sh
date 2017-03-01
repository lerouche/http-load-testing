#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

CPU_MAX_SPEED_MHZ=lscpu | awk '/max MHz/ {print $4}'
if [[ -z "${CPU_MAX_SPEED_MHZ// }" ]]; then
    CPU_MAX_SPEED_MHZ="$(lscpu | awk '/CPU MHz/ {print $3}')"
fi
CPU_MAX_SPEED_GHZ="Unknown"
if [[ ! -z "${CPU_MAX_SPEED_MHZ// }" ]]; then
    CPU_MAX_SPEED_GHZ="$(bc <<< "scale=2; $CPU_MAX_SPEED_MHZ / 1000")"
fi
CPU_CORE_COUNT=$(nproc --all)
SYSTEM_RAM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
SYSTEM_RAM_GB=$(($SYSTEM_RAM_KB / 1024 / 1024))

KEEPALIVE=false
SLEEP_DURATION="10"
REPORT_NAME="http-load-testing $CPU_CORE_COUNT-core $CPU_MAX_SPEED_GHZ GHz, $SYSTEM_RAM_GB GB RAM"
OUTPUT_DIR="$HOME/http-load-testing-reports/"

TESTS=()

while [[ $# -gt 0 ]]; do
    ARG=$1

    case $ARG in
        -k|--keepalive)
            KEEPALIVE=true
            ;;

        -s|--sleep)
            SLEEP_DURATION="$2"
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
    ./load-testing.sh -c "$TEST_C_VAL" -s "$SLEEP_DURATION" -n "$REPORT_NAME (${TEST_C_VAL}c)"
    mv report.html "$OUTPUT_DIR/$REPORT_NAME-${TEST_C_VAL}c.html"
done

if [ "$KEEPALIVE" = true ]; then
    for (( j=0; j<=$(( ${#TESTS[*]} - 1 )); j++ ))
    do
        TEST_C_VAL="${TESTS[$j]}"
        ./load-testing -k -c "$TEST_C_VAL" -s "$SLEEP_DURATION" -n "$REPORT_NAME (${TEST_C_VAL}c k)"
        mv report.html "$OUTPUT_DIR/$REPORT_NAME-${TEST_C_VAL}c-k.html"
    done
fi

exit 0
