#!/usr/bin/env bash

set -e

pushd "$(dirname "$0")" > /dev/null

sudo apt install -y wget software-properties-common

wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -

sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"

sudo apt update

sudo apt install -y openresty

popd > /dev/null

exit 0
