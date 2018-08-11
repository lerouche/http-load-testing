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

# Prepare to build Apache Web Server

cd "$SRC/apache/"
rm -rf httpd/
tar xvf httpd-2.4.25.tar.gz
mv httpd-2.4.25/ httpd/

tar xvf apr-1.5.2.tar.gz
mv apr-1.5.2/ httpd/srclib/apr/

tar xvf apr-util-1.5.4.tar.gz
mv apr-util-1.5.4/ httpd/srclib/apr-util/

# Build Apache Web Server

cd httpd/
./configure --prefix="$DST/apache" \
    --with-included-apr \
    --disable-access-compat \
    --disable-auth-basic \
    --disable-reqtimeout \
    --disable-filter \
    --disable-charset-lite \
    --disable-log-config \
    --disable-env \
    --disable-setenvif \
    --disable-version \
    --disable-status \
    --disable-autoindex \
    --disable-dir \
    --disable-alias \
    --with-mpm=prefork
make -j$CPU_CORE_COUNT
make install
cd ..
rm -rf httpd/

tar xvf php-7.1.2.tar.gz
rm -rf php/
mv php-7.1.2/ php/
cd php/
./configure --prefix="$DST/php" \
    --with-apxs2="$DST/apache/bin/apxs" \
    --disable-cli \
    --disable-cgi \
    --disable-short-tags \
    --enable-mbstring \
    --with-mysqli \
    --with-openssl
make -j$CPU_CORE_COUNT
make install
cd ..
rm -rf php/

rm -f "$DST/apache/htdocs/index.html"

cp httpd.conf "$DST/conf/apache.conf"

SYSTEM_RAM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MPM_PREFORK_CONNECTIONS=$(($SYSTEM_RAM_KB / 10000))
# Do NOT put trailing slash after $DST/apache
sed -i "s%COMPILE_VAR_APACHE_SERVER_ROOT%$DST/apache%" "$DST/conf/apache.conf"
sed -i "s/MaxRequestWorkers.*/MaxRequestWorkers $MPM_PREFORK_CONNECTIONS/" "$DST/conf/apache.conf"
sed -i "s/ServerLimit.*/ServerLimit $MPM_PREFORK_CONNECTIONS/" "$DST/conf/apache.conf"

grep '^[ \t]*LoadModule[ \t]*' "$DST/apache/conf/httpd.conf" | while read -r line; do
    sed -i "/^# LOAD MODULES HERE$/a $line" "$DST/conf/apache.conf"
done

rm -f "$DST/apache/conf/httpd.conf"
rm -f "$DST/apache/conf/httpd.conf.bak"

cd "$ORIG_DIR"

exit 0
