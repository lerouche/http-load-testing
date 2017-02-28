#!/usr/bin/env bash

set -e

# Remember script directory

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

# Get source and destination directories

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

cp -r "$SRC/express/." "$DST/app/express/"

# Install dependencies for Express

npm install --prefix "$DST/app/express/"
rm "$DST/app/express/package.json"

exit 0
