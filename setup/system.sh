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
    bc \
    libreadline-dev \
    libncurses5-dev \
    libpcre3-dev \
    libssl-dev \
    perl \
    make \
    build-essential \
    mysql-server \
    nodejs \
    dstat \
    unzip \
    autoconf \
    automake \
    binutils-dev \
    bison \
    build-essential \
    cmake \
    g++ \
    gawk \
    git \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-regex-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-context-dev \
    libbz2-dev \
    libc-client-dev \
    libldap2-dev \
    libc-client2007e-dev \
    libcap-dev \
    libcurl4-openssl-dev \
    libdwarf-dev \
    libelf-dev \
    libexpat-dev \
    libgd2-xpm-dev \
    libgoogle-glog-dev \
    libgoogle-perftools-dev \
    libicu-dev \
    libjemalloc-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libonig-dev \
    libpcre3-dev \
    libreadline-dev \
    libtbb-dev \
    libtool \
    libxml2-dev \
    zlib1g-dev \
    libevent-dev \
    libmagickwand-dev \
    libinotifytools0-dev \
    libiconv-hook-dev \
    libedit-dev \
    libiberty-dev \
    libxslt1-dev \
    ocaml-native-compilers \
    libsqlite3-dev \
    libyaml-dev \
    libgmp3-dev \
    gperf \
    libkrb5-dev \
    libnotify-dev \
    libpq-dev \

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
