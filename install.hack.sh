#!/usr/bin/env bash

set -e

ORIG_DIR="$(realpath "$(dirname "$0")")"
cd "$ORIG_DIR"

SRC="$(realpath ./src/)"
DST="$(realpath ./dist/)"

cd "$SRC"

mkdir -p "$DST/app/hack/"
cp hack/* "$DST/app/hack/"

find "$DST/app/hack/" -name "*.hh" > hack-index.tmp
"$DST/hhvm/bin/hhvm" --hphp -t hhbc -v AllVolatile=false -l3 --input-list hack-index.tmp -o "$DST/app/"
rm hack-index.tmp

cd "$ORIG_DIR"

exit 0
