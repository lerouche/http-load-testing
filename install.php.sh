#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

rm -rf "/var/www/html/load-testing/"
mkdir -p "/var/www/html/load-testing/"
cp src/php/*.php "/var/www/html/load-testing/"

exit 0
