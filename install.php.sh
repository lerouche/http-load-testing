#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

cp src/php/*.php dist/apache/htdocs/

exit 0
