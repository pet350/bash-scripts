#!/bin/bash

/usr/local/sbin/OpenVSwitch.sh stop --verbose
/bin/sleep 1
/usr/local/sbin/SetupWiFi.sh stop --verbose --skip-bridge
/bin/sleep 1
/sbin/ifconfig
/usr/bin/ovctl show
