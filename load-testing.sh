#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

KEEPALIVE_ARG=""
CONCURRENCY_ARG="-c1000"
SLEEP_DURATION=10

while [[ $# -gt 0 ]]; do
    ARG=$1

    case $ARG in
        -k|--keepalive)
            KEEPALIVE_ARG="-k"
            ;;

        -c|--concurrency)
            CONCURRENCY_ARG="-c$2"
            shift
            ;;

        -s|--sleep)
            SLEEP_DURATION="$2"
            shift
            ;;

        *)
            echo "Unrecognised argument \"$ARG\""
            exit 1
            ;;
    esac
    shift
done

TESTS[0]='hello-world'
TESTS[1]='json'
TESTS[2]='hmac'
TESTS[3]='db-get'
TESTS[4]='db-set'
TESTS[5]='assorted-lite'

TEST_N[0]=250000
TEST_N[1]=250000
TEST_N[2]=250000
TEST_N[3]=100000
TEST_N[4]=100000
TEST_N[5]=5000

SUBJECTS[0]='Express'
SUBJECTS[1]='PHP'
SUBJECTS[2]='HHVM'
SUBJECTS[3]='OpenResty'

SUBJECT_START[0]='node dist/app/express/server.js --pid="$(realpath dist/logs)/express.pid" &'
SUBJECT_START[1]='dist/apache/bin/httpd -k start'
SUBJECT_START[2]='dist/hhvm/bin/hhvm -m server -c "$(realpath dist/conf/hhvm.ini)" &'
SUBJECT_START[3]='dist/nginx/sbin/nginx -p "dist/" -c "conf/nginx.conf"'

SUBJECT_STOP[0]='kill -QUIT $(head -n 1 dist/logs/express.pid) || true'
SUBJECT_STOP[1]='dist/apache/bin/httpd -k stop || true'
SUBJECT_STOP[2]='kill $(head -n 1 dist/logs/hhvm.pid) || true'
SUBJECT_STOP[3]='kill -QUIT $(head -n 1 dist/logs/nginx.pid) || true'

SUBJECT_URL_PATHS[0]=':1025/${TEST}'
SUBJECT_URL_PATHS[1]=':1028/${TEST}.php'
SUBJECT_URL_PATHS[2]=':1026/${TEST}.hh'
SUBJECT_URL_PATHS[3]=':1027/${TEST}'

rm -rf results
rm -f report.html
rm -f system.info
mkdir -p dist/logs/

TIMESTAMP_STARTED=$(($(date +%s%N)/1000000))

echo "Started at $(date)"
echo "============================================================"
[ "$KEEPALIVE_ARG" == "-k" ] && echo "KeepAlive   on" || echo "KeepAlive   off"
echo "Sleep       $SLEEP_DURATION"
echo "Concurrency ${CONCURRENCY_ARG:2:${#CONCURRENCY_ARG}}"

for (( j=0; j<=$(( ${#SUBJECTS[*]} - 1 )); j++ ))
do
    export SUBJECT="${SUBJECTS[$j]}"
    eval "${SUBJECT_START[$j]}"
    sleep 5 # Allow time for server to initialise and warm up

    echo
    echo "$SUBJECT"
    echo

    for (( i=0; i<=$(( ${#TESTS[*]} - 1 )); i++ ))
    do
        export TEST="${TESTS[$i]}"
        eval "URL=\"http://localhost${SUBJECT_URL_PATHS[$j]}\""
        mkdir -p "results/$TEST/$SUBJECT"

        printf "$TEST..."

        SUBJECT_TIMESTAMP_STARTED=$(($(date +%s%N)/1000000))
        dstat -cm --noheaders --float --output "results/$TEST/$SUBJECT/system-load.csv" &> /dev/null &
        DSTAT_PID=$!
        sleep 2 # Give some buffer room for system load data

        ab $CONCURRENCY_ARG -n${TEST_N[$i]} $KEEPALIVE_ARG -q -l -r -s 600 "$URL" &> "results/$TEST/$SUBJECT/benchmark.log"

        printf " done\n"

        sleep 2 # Give some buffer room for system load data
        kill $DSTAT_PID
        wait $DSTAT_PID &> /dev/null || true
        SUBJECT_TIMESTAMP_ENDED=$(($(date +%s%N)/1000000))

        echo "$SUBJECT_TIMESTAMP_STARTED;$SUBJECT_TIMESTAMP_ENDED" > "results/$TEST/$SUBJECT/timestamps.txt"

        sleep $SLEEP_DURATION
    done

    eval "${SUBJECT_STOP[$j]}"
    sleep 5 # Allow time for server to shut down and clean up
done

echo "timeStarted=$TIMESTAMP_STARTED" >> system.info
echo "timeEnded=$(($(date +%s%N)/1000000))" >> system.info
echo "cpuCores=$(nproc --all)" >> system.info
echo "memory=$(free | awk '/^Mem:/{print $2}')" >> system.info
echo "sleepDuration=$SLEEP_DURATION" >> system.info

printf "Enter the name for this report: "
read REPORT_NAME

node report-template/generate-report.js --name="$REPORT_NAME"

exit 0
