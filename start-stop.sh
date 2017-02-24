#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

./start-only.sh

read -n 1 -s -p $'Press any key at any time to terminate\n'

./stop-only.sh

exit 0