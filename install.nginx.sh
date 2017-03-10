#!/usr/bin/env bash

set -e

# Get CPU cores

CPU_CORE_COUNT=$(nproc --all)
echo "CPU cores: $CPU_CORE_COUNT"

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source and destionation directories

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

# Prepare to build Nginx

cd "$SRC/nginx/"
tar -zvxf openresty-1.11.2.2.tar.gz
rm -rf openresty/
mv openresty-1.11.2.2/ openresty/

# Build Nginx

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

# Copy Nginx configuration

cp nginx.conf "$DST/conf/nginx.conf"

LUA_MODULES_PATH1="$DST/lualib/"
LUA_MODULES_PATH2="$DST/site/lualib/"
LUA_MODULES_PATH3="$DST/rocks/lib/lua/5.1/"

sed -i "s%lua_package_cpath.*%lua_package_cpath \"$LUA_MODULES_PATH1?.so;$LUA_MODULES_PATH2?.so;$LUA_MODULES_PATH3?.so\";%" "$DST/conf/nginx.conf"
sed -i "s%lua_package_path.*%lua_package_path \"$LUA_MODULES_PATH1?.lua;$LUA_MODULES_PATH2?.lua;$LUA_MODULES_PATH3?.lua\";%" "$DST/conf/nginx.conf"

cd "$ORIG_DIR"

# Install LuaRocks

LUA_INCDIR="$DST/luajit/include/luajit-2.1"

cd "$SRC/nginx/"
tar -xzvf luarocks-2.4.2.tar.gz
rm -rf luarocks/
mv luarocks-2.4.2/ luarocks/
cd luarocks/
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
rm -rf luarocks/

# Install other Lua dependencies

LUA_MODULES_DIR="$DST/site/lualib"

wget "https://raw.githubusercontent.com/jkeys089/lua-resty-hmac/master/lib/resty/hmac.lua" -O "$LUA_MODULES_DIR/hmac.lua"

"$DST/luarocks/bin/luarocks" install bcrypt
"$DST/luarocks/bin/luarocks" install luautf8

cd "$ORIG_DIR"

exit 0
