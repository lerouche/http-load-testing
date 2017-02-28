#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

# BUGFIX: HHVM doesn't use proper sock path despite being compiled with it and set 3 times in its config...
if [ ! -L "/tmp/mysql.sock" ]; then
    ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock
fi

mkdir -p dist/logs/

dist/apache/bin/httpd -k start

dist/nginx/sbin/nginx -p "dist/" -c "conf/nginx.conf"

dist/hhvm/bin/hhvm -m server -c "$(realpath dist/conf/hhvm.ini)" &

node dist/app/express/server.js --pid="$(realpath dist/logs)/express.pid" &

exit 0
