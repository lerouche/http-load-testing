#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

rm -rf dist/logs/
mkdir -p dist/logs/

dist/nginx/sbin/nginx -p "dist/" -c "conf/nginx.conf"
rm -rf dist/logs/error.log

hhvm -m server -c "$(realpath dist/conf/hhvm.ini)" &

node dist/app/express/server.js --pid="$(realpath dist/logs)/express.pid" &

read -n 1 -s -p $'Press any key at any time to terminate\n'

kill -QUIT $(head -n 1 dist/logs/nginx.pid)
kill $(head -n 1 dist/logs/hhvm.pid)
kill -QUIT $(head -n 1 dist/logs/express.pid)

exit 0
