#!/usr/bin/env bash

set -e

# Get CPU cores

CPU_CORE_COUNT=$(nproc --all)
echo "CPU cores: $CPU_CORE_COUNT"

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source directory

SRC="$(realpath ./src/)"

# Prepare destination folder

DST="$(realpath ./dist/)"
rm -rf "$DST"
mkdir -p "$DST"

# Prepare to build OpenResty

cd "$SRC/nginx/"
rm -rf openresty/
tar -zvxf openresty-1.11.2.2.tar.gz
mv openresty-1.11.2.2/ openresty/
cp __patches/* openresty/bundle/nginx-1.11.2/src/http/

# Build OpenResty

cd openresty/
./configure -j$CPU_CORE_COUNT --prefix="$DST" \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_v2_module \
    --without-http_echo_module \
    --without-http_xss_module \
    --without-http_coolkit_module \
    --without-http_set_misc_module \
    --without-http_form_input_module \
    --without-http_encrypted_session_module \
    --without-http_array_var_module \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_autoindex_module \
    --without-http_geo_module \
    --without-http_map_module \
    --without-http_split_clients_module \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_empty_gif_module \
    --without-http_browser_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module
make -j$CPU_CORE_COUNT
make install
cd ..
rm -rf openresty/

# Copy OpenResty configuration

rm -rf "$DST/conf/"
mkdir -p "$DST/conf/"
cp conf/* "$DST/conf/"

LUA_MODULES_PATH1="$DST/lualib/"
LUA_MODULES_PATH2="$DST/site/lualib/"
LUA_MODULES_PATH3="$DST/rocks/lib/lua/5.1/"

sed -i "s%lua_package_cpath.*%lua_package_cpath \"$LUA_MODULES_PATH1?.so;$LUA_MODULES_PATH2?.so;$LUA_MODULES_PATH3?.so\";%" "$DST/conf/nginx.conf"
sed -i "s%lua_package_path.*%lua_package_path \"$LUA_MODULES_PATH1?.lua;$LUA_MODULES_PATH2?.lua;$LUA_MODULES_PATH3?.lua\";%" "$DST/conf/nginx.conf"

cd "$ORIG_DIR"

# Copy code for PHP

./install.apache.sh
./install.php.sh

# Install dependencies for OpenResty

export LUA_INCDIR="$DST/luajit/include/luajit-2.1"
LUA_MODULES_DIR="$DST/site/lualib"

cd src/nginx
tar -xzvf luarocks-2.4.2.tar.gz
cd luarocks-2.4.2/
mkdir -p "$DST/luarocks/"
mkdir -p "$DST/rocks/"
./configure \
    --prefix="$DST/luarocks" \
    --with-lua="$DST/luajit/" \
    --with-lua-include="$LUA_INCDIR" \
    --rocks-tree="$DST/rocks/" \
    --lua-suffix=jit \
    --sysconfdir="$DST/conf/" \
    --force-config
make -j$CPU_CORE_COUNT build
make install
cd ..
rm -rf luarocks-2.4.2/

cd lib

tar -zvxf LuaBitOp-1.0.2.tar.gz
cd LuaBitOp-1.0.2
sed -i "s%^INCLUDES= -I.*%INCLUDES= -I$LUA_INCDIR%" Makefile
make
mv bit.so "$LUA_MODULES_DIR"
cd ..
rm -rf LuaBitOp-1.0.2

wget "https://raw.githubusercontent.com/jkeys089/lua-resty-hmac/master/lib/resty/hmac.lua" -O "$LUA_MODULES_DIR/hmac.lua"

"$DST/luarocks/bin/luarocks" install bcrypt
"$DST/luarocks/bin/luarocks" install luautf8

cd "$ORIG_DIR"

# Compile HHVM code

./install.hhvm.sh
./install.hack.sh

# Finish

cd "$ORIG_DIR"

exit 0
