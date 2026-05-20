#!/bin/bash
# Setup APT Caching Server

apt-get update -q
apt-get install apt-cacher-ng -y

echo "PassThroughPattern: .*" | sudo tee -a /etc/apt-cacher-ng/acng.conf
echo "VerboseLog: 2" | sudo tee -a /etc/apt-cacher-ng/acng.conf
echo "Debug: 5" | sudo tee -a /etc/apt-cacher-ng/acng.conf

ps -ef | grep apt-cacher-ng
netstat -an | grep "LISTEN "

grep CacheDir /etc/apt-cacher-ng/acng.conf

