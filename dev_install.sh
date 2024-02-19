#!/bin/bash

cd /tmp
apt update
apt install git gcc make postgresql-server-dev-15 -y
git clone https://github.com/okbob/plpgsql_check.git
cd plpgsql_check && make && make install