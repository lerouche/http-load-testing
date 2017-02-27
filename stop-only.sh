#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

dist/apache/bin/httpd -k stop || true

kill -QUIT $(head -n 1 dist/logs/nginx.pid) || true
kill $(head -n 1 dist/logs/hhvm.pid) || true
kill $(head -n 1 dist/logs/express.pid) || true

rm dist/logs/*.pid

exit 0
