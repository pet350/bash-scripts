#!/bin/bash

/usr/local/sbin/SetupWiFi.sh start --verbose --skip-bridge --skip-dhcp-client
/bin/sleep 1
/usr/local/sbin/OpenVSwitch.sh start --verbose
/bin/sleep 1
/usr/bin/ovctl show
/bin/sleep 1
/sbin/dhclient -v br0
/sbin/ifconfig
