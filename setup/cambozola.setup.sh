#!/bin/bash

cd /usr/src
wget http://www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz
tar -xzvf cambozola-latest.tar.gz
chmod +x cambozola-0.936/dist/*
if [ ! -d /usr/share/zoneminder/www ]; then
	mkdir -p /usr/share/zoneminder/www
fi
cp -v cambozola-0.936/dist/* /usr/share/zoneminder/www

# All Done!
