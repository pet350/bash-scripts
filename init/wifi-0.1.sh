#!/bin/bash

function doSTART()
{
  /usr/local/sbin/SetupWiFi.sh start --verbose --skip-bridge --skip-dhcp-client
  /bin/sleep 1
  #/usr/local/sbin/OpenVSwitch.sh start --verbose
  #/bin/sleep 1
  #/usr/bin/ovctl show
  #/bin/sleep 1
  /sbin/dhclient -v wlan0
  /sbin/ifconfig
  /etc/init.d/nscd restart
  return 0
};

function doSTOP()
{
  /usr/local/sbin/OpenVSwitch.sh stop --verbose
  /bin/sleep 1
  /usr/local/sbin/SetupWiFi.sh stop --verbose --skip-bridge
  /bin/sleep 1
  /sbin/ifconfig
  /usr/bin/ovctl show
  return 0
};

case $1 in
'start' | 'START')
	doSTART
	RETVAL=$?
	;;
'stop' | 'STOP')
	doSTOP
	RETVAL=$?
	;;
'restart' | 'RESTART')
	doSTOP
	/bin/sleep 1
	doSTART
	RETVAL=$?
	;;
esac

exit $RETVAL
