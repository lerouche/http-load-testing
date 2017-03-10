#!/usr/bin/env bash

set -e

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source directory

SRC="$(realpath ./src/)"

# Prepare destination folder

DST="$(realpath ./dist/)"
rm -rf "$DST"
mkdir -p "$DST"
mkdir -p "$DST/app"
mkdir -p "$DST/conf"
mkdir -p "$DST/logs"

# Set up Express

./install.express.sh

# Set up OpenResty

./install.nginx.sh
./install.resty.sh

# Set up PHP

./install.apache.sh
./install.php.sh

# Set up HHVM

./install.hhvm.sh
./install.hack.sh

# Finish

cd "$ORIG_DIR"

exit 0
