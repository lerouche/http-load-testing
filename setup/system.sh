#!/usr/bin/env bash

set -e

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run using sudo or as the root user"
    echo "Sudo commands will be run as necessary, but some actions require them to be run as you"
    exit 1
fi

cd "$(dirname "$0")"

sudo apt update
sudo apt install -y git curl software-properties-common wget

curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo add-apt-repository -y ppa:ondrej/php

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
sudo add-apt-repository "deb http://dl.hhvm.com/ubuntu $(lsb_release -sc) main"

sudo apt update
sudo apt dist-upgrade -y

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
    apache2 \
    libapache2-mod-php7.1 \
    php7.1-mcrypt \
    php7.1-mysql \
    php7.1-mbstring \
    dstat \

sudo mysql_secure_installation

sudo mkdir -p /etc/systemd/system/mysql.service.d/
echo '[Service]' | sudo tee /etc/systemd/system/mysql.service.d/override.conf
echo 'LimitNOFILE=infinity' | sudo tee -a /etc/systemd/system/mysql.service.d/override.conf

sudo sed -i '/^skip-external-locking$/a sql-mode = "STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^max_allowed_packet.*/max_allowed_packet = 4096M/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^thread_stack.*/thread_stack = 256K/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^#max_connections.*/max_connections=1000000/' /etc/mysql/mysql.conf.d/mysqld.cnf

sudo chown -R "$USER:www-data" /var/www
sudo chmod -R 770 /var/www
rm /var/www/html/index.html

echo 'net.ipv4.ip_local_port_range = 1024 65535' | sudo tee -a /etc/sysctl.conf
echo 'fs.file-max = 1024000' | sudo tee -a /etc/sysctl.conf
echo '* soft nproc 1024000' | sudo tee -a /etc/security/limits.conf
echo '* hard nproc 1024000' | sudo tee -a /etc/security/limits.conf
echo '* soft nofile 1024000' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 1024000' | sudo tee -a /etc/security/limits.conf

sudo cp -R apache2/* /etc/apache2/
sudo a2enmod headers

SYSTEM_RAM_MB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MPM_PREFORK_CONNECTIONS=$(($SYSTEM_RAM_MB / 15000))
sudo sed -i "s/MaxRequestWorkers.*/MaxRequestWorkers $MPM_PREFORK_CONNECTIONS/" /etc/apache2/mods-available/mpm_prefork.conf
sudo sed -i "s/ServerLimit.*/ServerLimit $MPM_PREFORK_CONNECTIONS/" /etc/apache2/mods-available/mpm_prefork.conf

mysql -u root -p < database.sql

cd ../report-template
npm install

cd ..

exit 0
