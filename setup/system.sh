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
    php7.1 \
    php7.1-mbstring \
    php7.1-mcrypt \
    php7.1-mysql \
    mysql-server \
    nodejs \

sudo mysql_secure_installation
sudo mkdir -p /etc/systemd/system/mysql.service.d/
echo '[Service]' | sudo tee -a /etc/systemd/system/mysql.service.d/override.conf
echo 'LimitNOFILE=infinity' | sudo tee -a /etc/systemd/system/mysql.service.d/override.conf
echo 'sql-mode="STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
echo 'max_connections=50000' | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

exit 0