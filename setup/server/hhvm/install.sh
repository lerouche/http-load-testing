#!/usr/bin/env bash

set -e

pushd "$(dirname "$0")" > /dev/null

sudo apt install -y software-properties-common apt-transport-https
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94

sudo add-apt-repository -y https://dl.hhvm.com/ubuntu
sudo apt update
sudo apt install -y hhvm

popd > /dev/null

exit 0
