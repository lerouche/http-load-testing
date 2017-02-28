#!/usr/bin/env bash

set -e

# Get CPU cores

CPU_CORE_COUNT=$(nproc --all)
echo "CPU cores: $CPU_CORE_COUNT"

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source and destination directories

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

# Build HHVM

cd "$SRC/hhvm/hhvm/"
rm -f CMakeCache.txt
cmake \
    -DMYSQL_UNIX_SOCK_ADDR="/var/run/mysqld/mysqld.sock" \
    -DCMAKE_INSTALL_PREFIX="$DST/hhvm" \
    .
make -j$CPU_CORE_COUNT
make install
cd "$ORIG_DIR"

# Install configuration file

cp "$SRC/hhvm/hhvm.ini" "$DST/conf/hhvm.ini"
sed -i "s%DST%$DST%" "$DST/conf/hhvm.ini"

# Finish

cd "$ORIG_DIR"

exit 0
