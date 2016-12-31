#!/usr/bin/env bash

# OVERRIDE: Don't quit on fail as some ab commands fail due to server
# set -e

cd "$(dirname "$0")"

mkdir -p results/hello-world results/json results/hmac results/db-get results/db-set

HOSTNAME="$1"
if [[ -z "${HOSTNAME// }" ]]; then
    HOSTNAME="localhost"
fi

echo "Testing on $HOSTNAME..."
echo
echo "HELLO WORLD"
echo
printf "PHP..."
ab -c10 -n100000 -r "http://$HOSTNAME/load-testing/hello-world.php" &> results/hello-world/php.log
printf " done\n"
printf "OpenResty..."
ab -c10 -n100000 -r "http://$HOSTNAME:1500/hello-world" &> results/hello-world/openresty.log
printf " done\n"
printf "Express..."
ab -c10 -n100000 -r "http://$HOSTNAME:3000/hello-world" &> results/hello-world/express.log
printf " done\n"
echo
echo "JSON"
echo
printf "PHP..."
ab -c10 -n100000 -r "http://$HOSTNAME/load-testing/json.php" &> results/json/php.log
printf " done\n"
printf "OpenResty..."
ab -c10 -n100000 -r "http://$HOSTNAME:1500/json" &> results/json/openresty.log
printf " done\n"
printf "Express..."
ab -c10 -n100000 -r "http://$HOSTNAME:3000/json" &> results/json/express.log
printf " done\n"
echo
echo "HMAC"
echo
printf "PHP..."
ab -c10 -n100000 -r "http://$HOSTNAME/load-testing/hmac.php" &> results/hmac/php.log
printf " done\n"
printf "OpenResty..."
ab -c10 -n100000 -r "http://$HOSTNAME:1500/hmac" &> results/hmac/openresty.log
printf " done\n"
printf "Express..."
ab -c10 -n100000 -r "http://$HOSTNAME:3000/hmac" &> results/hmac/express.log
printf " done\n"
echo
echo "DB GET"
echo
printf "PHP..."
ab -c10 -n10000 -r "http://$HOSTNAME/load-testing/db-get.php" &> results/db-get/php.log
printf " done\n"
printf "OpenResty..."
ab -c10 -n10000 -r "http://$HOSTNAME:1500/db-get" &> results/db-get/openresty.log
printf " done\n"
printf "Express..."
ab -c10 -n10000 -r "http://$HOSTNAME:3000/db-get" &> results/db-get/express.log
printf " done\n"
echo
echo "DB SET"
echo
printf "PHP..."
ab -c10 -n10000 -r "http://$HOSTNAME/load-testing/db-set.php" &> results/db-set/php.log
printf " done\n"
printf "OpenResty..."
ab -c10 -n10000 -r "http://$HOSTNAME:1500/db-set" &> results/db-set/openresty.log
printf " done\n"
printf "Express..."
ab -c10 -n10000 -r "http://$HOSTNAME:3000/db-set" &> results/db-set/express.log
printf " done\n"

node generate-report.js
xdg-open ./report.html &

exit 0
