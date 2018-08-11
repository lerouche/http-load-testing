#!/usr/bin/env bash

set -e

pushd "$(dirname "$0")" > /dev/null

sudo apt install -y curl

curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt install -y nodejs

popd > /dev/null

exit 0
