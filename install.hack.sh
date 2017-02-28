#!/usr/bin/env bash

set -e

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

cd "$SRC"

HHVM_INI_FILE="$DST/conf/hhvm.ini"
> "$HHVM_INI_FILE"

echo "pid=$DST/logs/hhvm.pid" >> "$HHVM_INI_FILE"
echo "hhvm.server.port=1026" >> "$HHVM_INI_FILE"
echo "hhvm.server.type=proxygen" >> "$HHVM_INI_FILE"
echo "hhvm.server.backlog=10000" >> "$HHVM_INI_FILE"
echo "hhvm.server.thread_count=10000" >> "$HHVM_INI_FILE"
echo "hhvm.server.stat_cache=true" >> "$HHVM_INI_FILE"
echo "hhvm.server.enable_output_buffering=true" >> "$HHVM_INI_FILE"
echo "hhvm.server.enable_keep_alive=true" >> "$HHVM_INI_FILE"

echo "hhvm.repo.authoritative=true" >> "$HHVM_INI_FILE"
echo "hhvm.repo.central.path=$DST/app/hhvm.hhbc" >> "$HHVM_INI_FILE"
echo "hhvm.server.source_root=$DST/app/hack/" >> "$HHVM_INI_FILE" # The reason why this is necessary is because despite having a compiled DB, it still needs to check the filesystem to see if the path exists

echo "hhvm.server.kill_on_sigterm=true" >> "$HHVM_INI_FILE"
echo "hhvm.server.exit_on_bind_fail=true" >> "$HHVM_INI_FILE"
echo "hhvm.server.expose_hphp=false" >> "$HHVM_INI_FILE"

echo "hhvm.log.use_log_file=false" >> "$HHVM_INI_FILE"

echo "mysqli.allow_persistent=1" >> "$HHVM_INI_FILE"
echo "mysqli.max_persistent=-1" >> "$HHVM_INI_FILE"
echo "mysqli.max_links=-1" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.connect_timeout=60000" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.slow_query_threshold=60000" >> "$HHVM_INI_FILE"

echo "mysqli.default_socket=/var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"
echo "pdo_mysql.default_socket=/var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"
echo "hhvm.mysql.socket=/var/run/mysqld/mysqld.sock" >> "$HHVM_INI_FILE"

mkdir -p "$DST/app/hack/"
cp hack/* "$DST/app/hack/"

find "$DST/app/hack/" -name "*.hh" > hack-index.tmp
"$DST/hhvm/bin/hhvm" --hphp -t hhbc -v AllVolatile=false -l3 --input-list hack-index.tmp -o "$DST/app/"
rm hack-index.tmp

cd "$ORIG_DIR"

exit 0
