#!/bin/bash

VER=0.1

wpa_supplicant -Dwext -iwlan0 -c/etc/wpa_supplicant.conf -bbr1 -B -dd

dhclient -v
