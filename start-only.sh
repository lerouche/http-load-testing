#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

mkdir -p dist/logs/

dist/apache/bin/httpd -k start

dist/nginx/sbin/nginx -p "dist/" -c "conf/nginx.conf"

dist/hhvm/bin/hhvm -m server -c "$(realpath dist/conf/hhvm.ini)" &

node dist/app/express/server.js --pid="$(realpath dist/logs)/express.pid" &

exit 0
