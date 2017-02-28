#!/usr/bin/env bash

cd "$(dirname "$0")"

./stop-only.sh &>/dev/null

./start-only.sh || { ./stop-only.sh &>/dev/null; exit 1; }

read -n 1 -s -p $'Press any key at any time to terminate\n'

./stop-only.sh &>/dev/null

exit 0
