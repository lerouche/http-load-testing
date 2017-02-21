#!/usr/bin/env bash

set -e

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run using sudo or as the root user"
    echo "Sudo commands will be run as necessary, but some actions require them to be run as you"
    exit 1
fi

sudo apt update
sudo apt install -y curl software-properties-common wget

curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo add-apt-repository -y ppa:ondrej/php

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
sudo add-apt-repository "deb http://dl.hhvm.com/ubuntu $(lsb_release -sc) main"

sudo apt update
sudo apt -y dist-upgrade

sudo apt install -y \
    libreadline-dev \
    libncurses5-dev \
    libpcre3-dev \
    libssl-dev \
    perl \
    make \
    build-essential \
    mysql-server \
    hhvm \
    nodejs \

sudo mysql_secure_installation

sudo mkdir -p /etc/systemd/system/mysql.service.d/
echo '[Service]' | sudo tee /etc/systemd/system/mysql.service.d/override.conf
echo 'LimitNOFILE=infinity' | sudo tee -a /etc/systemd/system/mysql.service.d/override.conf

sudo sed -i '/^skip-external-locking$/a sql-mode = "STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^max_allowed_packet.*/max_allowed_packet = 4096M/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^thread_stack.*/thread_stack = 256K/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^#max_connections.*/max_connections=1000000/' /etc/mysql/mysql.conf.d/mysqld.cnf

exit 0