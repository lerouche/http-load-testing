#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

kill -QUIT $(head -n 1 dist/logs/nginx.pid)
kill $(head -n 1 dist/logs/hhvm.pid)
kill -QUIT $(head -n 1 dist/logs/express.pid)

rm dist/logs/*.pid

exit 0