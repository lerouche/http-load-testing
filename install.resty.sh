#!/usr/bin/env bash

set -e

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source and destination directories

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

# Copy code for OpenResty

cd "$SRC"

mkdir -p "$DST/app/resty/"
cp resty/* "$DST/app/resty/"

# Finish

cd "$ORIG_DIR"

exit 0
