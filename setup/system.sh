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

sudo apt update
sudo apt dist-upgrade -y

sudo apt install -y \
    autoconf \
    automake \
    bc \
    binutils-dev \
    bison \
    build-essential \
    cmake \
    dstat \
    g++ \
    gawk \
    git \
    gperf \
    libboost-context-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-regex-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libbz2-dev \
    libc-client-dev \
    libc-client2007e-dev \
    libcap-dev \
    libcurl4-openssl-dev \
    libdwarf-dev \
    libedit-dev \
    libelf-dev \
    libevent-dev \
    libexpat-dev \
    libgd2-xpm-dev \
    libgmp3-dev \
    libgoogle-glog-dev \
    libgoogle-perftools-dev \
    libiberty-dev \
    libiconv-hook-dev \
    libicu-dev \
    libinotifytools0-dev \
    libjemalloc-dev \
    libkrb5-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libncurses5-dev \
    libnotify-dev \
    libonig-dev \
    libpcre3-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libtbb-dev \
    libtool \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    make \
    mysql-server \
    nodejs \
    ocaml-native-compilers \
    perl \
    unzip \
    zlib1g-dev \

sudo mysql_secure_installation

sudo mkdir -p /etc/systemd/system/mysql.service.d/
echo '[Service]' | sudo tee /etc/systemd/system/mysql.service.d/override.conf
echo 'LimitNOFILE=infinity' | sudo tee -a /etc/systemd/system/mysql.service.d/override.conf

sudo sed -i '/^skip-external-locking$/a sql-mode = "STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^max_allowed_packet.*/max_allowed_packet = 4096M/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^thread_stack.*/thread_stack = 256K/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^#max_connections.*/max_connections=1000000/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^bind-address.*/skip-networking/' /etc/mysql/mysql.conf.d/mysqld.cnf

echo 'net.ipv4.ip_local_port_range = 1024 65535' | sudo tee -a /etc/sysctl.conf
echo 'fs.file-max = 1024000' | sudo tee -a /etc/sysctl.conf
echo '* soft nproc 1024000' | sudo tee -a /etc/security/limits.conf
echo '* hard nproc 1024000' | sudo tee -a /etc/security/limits.conf
echo '* soft nofile 1024000' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 1024000' | sudo tee -a /etc/security/limits.conf

mysql -u root -p < database.sql

cd ../report-template
npm install
node minify-report-template.js

cd ..

exit 0
