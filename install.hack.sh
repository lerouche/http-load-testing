#!/usr/bin/env bash

set -e

ORIG_DIR="$(dirname "$0")"
ORIG_DIR="$(realpath "$ORIG_DIR")"
cd "$ORIG_DIR"

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

cd "$SRC"

HHVM_INI_FILE="$DST/conf/hhvm.ini"
HHVM_FILE_SOCKET="$DST/logs/hhvm.sock"

echo "pid = $DST/logs/hhvm.pid" >> "$HHVM_INI_FILE"
echo "hhvm.server.port = 1026" >> "$HHVM_INI_FILE"
echo "hhvm.server.type = proxygen" >> "$HHVM_INI_FILE"

echo "hhvm.server.exit_on_bind_fail = true" >> "$HHVM_INI_FILE"
echo "hhvm.server.expose_hphp = false" >> "$HHVM_INI_FILE"
echo "hhvm.php7.all = true" >> "$HHVM_INI_FILE"
echo "hhvm.log.file = /dev/null" >> "$HHVM_INI_FILE"
echo "hhvm.log.level = None" >> "$HHVM_INI_FILE"
echo "hhvm.repo.authoritative = true" >> "$HHVM_INI_FILE"
echo "hhvm.repo.central.path = $DST/app/hhvm.hhbc" >> "$HHVM_INI_FILE"
echo "hhvm.server.source_root = $DST/app/hack/" >> "$HHVM_INI_FILE"

echo "mysqli.allow_persistent = 1" >> "$HHVM_INI_FILE"
echo "mysqli.max_persistent = -1" >> "$HHVM_INI_FILE"
echo "mysqli.max_links = -1" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.connect_timeout = 60000" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.slow_query_threshold = 60000" >> "$HHVM_INI_FILE"

echo "mysqli.default_socket = /var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"
echo "pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.socket = /var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"

mkdir -p "$DST/app/hack/"
cp hack/* "$DST/app/hack/"

find "$DST/app/hack/" -name "*.hh" > hack-index.tmp
hhvm --hphp -t hhbc -v AllVolatile=false -l3 --input-list hack-index.tmp -o "$DST/app/"
rm hack-index.tmp

cd "$ORIG_DIR"

exit 0
