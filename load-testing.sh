#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

SLEEP_DURATION=60

TESTS[0]='hello-world'
TESTS[1]='json'
TESTS[2]='hmac'
TESTS[3]='db-get'
TESTS[4]='db-set'

SUBJECTS[0]='Express'
SUBJECTS[1]='PHP'
SUBJECTS[2]='HHVM'
SUBJECTS[3]='OpenResty'

SUBJECT_URL_PATHS[0]=':1025/${TEST}'
SUBJECT_URL_PATHS[1]='/load-testing/${TEST}.php'
SUBJECT_URL_PATHS[2]=':1026/${TEST}.hh'
SUBJECT_URL_PATHS[3]=':1027/${TEST}'

rm -rf results
rm -f system-load.csv
rm -f report.html
rm -f times.log
rm -f system.info

TIMESTAMP_STARTED=$(($(date +%s%N)/1000000))
echo $TIMESTAMP_STARTED >> times.log
dstat -cm --noheaders --float --output system-load.csv &>/dev/null &
DSTAT_PID=$!

echo "Started at $TIMESTAMP_STARTED"
echo "============================================================"

sleep 5 # Give some buffer room for beginning of system load data

for (( i=0; i<=$(( ${#TESTS[*]} -1 )); i++ ))
do
    export TEST="${TESTS[$i]}"
    mkdir -p "results/$TEST"
    echo "#$TEST" >> times.log

    echo
    echo "$TEST"
    echo

    for (( j=0; j<=$(( ${#SUBJECTS[*]} -1 )); j++ ))
    do
        export SUBJECT="${SUBJECTS[$j]}"
        eval "URL=\"http://127.0.0.1${SUBJECT_URL_PATHS[$j]}\""

        printf "$SUBJECT..."

        SUBJECT_TIMESTAMP_STARTED=$(($(date +%s%N)/1000000))
        ab -c1000 -n500000 -q -l -r "$URL" &> "results/$TEST/$SUBJECT.log"
        SUBJECT_TIMESTAMP_ENDED=$(($(date +%s%N)/1000000))
        echo "$SUBJECT;$SUBJECT_TIMESTAMP_STARTED;$SUBJECT_TIMESTAMP_ENDED" >> times.log

        printf " done\n"

        sleep $SLEEP_DURATION
    done
done

echo "timeStarted=$TIMESTAMP_STARTED" >> system.info
echo "timeEnded=$(($(date +%s%N)/1000000))" >> system.info
echo "cpuCores=$(nproc --all)" >> system.info
echo "memory=$(free | awk '/^Mem:/{print $2}')" >> system.info
echo "sleepDuration=$SLEEP_DURATION" >> system.info

kill $DSTAT_PID
wait $DSTAT_PID &>/dev/null || true

node generate-report.js
xdg-open ./report.html &>/dev/null &

exit 0
