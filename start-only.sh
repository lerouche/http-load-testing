#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

# BUG FIX: HHVM doesn't use config values for sock location
if [ ! -L "/tmp/mysql.sock" ]; then
    ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock
fi

rm -rf dist/logs/
mkdir -p dist/logs/

dist/nginx/sbin/nginx -p "dist/" -c "conf/nginx.conf"
rm -rf dist/logs/error.log

hhvm -m server -c "$(realpath dist/conf/hhvm.ini)" &

node dist/app/express/server.js --pid="$(realpath dist/logs)/express.pid" &

exit 0
