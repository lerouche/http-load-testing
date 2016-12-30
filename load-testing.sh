#!/usr/bin/env bash

# OVERRIDE: Don't quit on fail as some ab commands fail due to server
# set -e

cd "$(dirname "$0")"

mkdir -p results/hello-world results/json results/hmac results/db-get results/db-set

ab -c10 -n100000 -r 'http://localhost/load-testing/hello-world.php' &> results/hello-world/php.log
ab -c10 -n100000 -r 'http://localhost:1500/hello-world' &> results/hello-world/openresty.log
ab -c10 -n100000 -r 'http://localhost:3000/hello-world' &> results/hello-world/express.log

ab -c10 -n100000 -r 'http://localhost/load-testing/json.php' &> results/json/php.log
ab -c10 -n100000 -r 'http://localhost:1500/json' &> results/json/openresty.log
ab -c10 -n100000 -r 'http://localhost:3000/json' &> results/json/express.log

ab -c10 -n100000 -r 'http://localhost/load-testing/hmac.php' &> results/hmac/php.log
ab -c10 -n100000 -r 'http://localhost:1500/hmac' &> results/hmac/openresty.log
ab -c10 -n100000 -r 'http://localhost:3000/hmac' &> results/hmac/express.log

ab -c10 -n10000 -r 'http://localhost/load-testing/db-get.php' &> results/db-get/php.log
ab -c10 -n10000 -r 'http://localhost:1500/db-get' &> results/db-get/openresty.log
ab -c10 -n10000 -r 'http://localhost:3000/db-get' &> results/db-get/express.log

ab -c10 -n10000 -r 'http://localhost/load-testing/db-set.php' &> results/db-set/php.log
ab -c10 -n10000 -r 'http://localhost:1500/db-set' &> results/db-set/openresty.log
ab -c10 -n10000 -r 'http://localhost:3000/db-set' &> results/db-set/express.log

node generate-report.js
xdg-open ./report.html &

exit 0
