#!/bin/bash
# Script to Initialize WiFi
# By: Peter Talbott

# Source LSB function library.
source /lib/lsb/init-functions

# Current Version
VERSION=0.1

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

# Define String Variables
export RUN_CMD="$(basename $0)"
export CONFIG_PREFIX="/etc"
export SYSBIN_PREFIX="/sbin"
export BIN_PREFIX="/usr/bin"
export TAIL_BIN="$BIN_PREFIX/tail"
export HEAD_BIN="$BIN_PREFIX/head"
export OVS_BIN="$BIN_PREFIX/ovs-vsctl"
export CONFIG_FILE="$CONFIG_PREFIX/wpa_supplicant.conf"
export WPA_PROC="wpa_supplicant"
export WPA_BIN="$SYSBIN_PREFIX/$WPA_PROC"
export WPA_OPTS="-B -dd"
export WIFI_IFACE="wlan0"
export BRIDGE_IFACE="br0"
export DRIVER_EXTERNAL="wext"
export DRIVER_80211="nl80211"
export VERBOSE=""
export WPA_DEBUG="-dd"

# Define Boolean Variables and set Default Values
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_WPA_DEBUG=$TRUE
declare -ig BOL_WIFI_UP=$TRUE
declare -ig BOL_SLEEP=$TRUE
declare -ig BOL_MAKE_BRIDGE=$TRUE
declare -ig BOL_DESTROY_BRIDGE=$TRUE
declare -ig BOL_DHCLIENT=$TRUE

# Define Intiger Variables
declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=2
declare -ig VAR_MAX_LOOP=3

# Make Sure That Only Root is Running this Script
if [ $(id -u) -gt 0 ]; then
  echo -e "Error: $RUN_CMD Version $VERSION\nMust be ran as ROOT user!"
  exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD {start|stop|restart}"
    exit 1
fi


function MAKE_BRIDGE()
{
  if [ -f /usr/local/sbin/OpenVSwitch.sh ]; then
    /usr/local/sbin/OpenVSwitch.sh start $VERBOSE
    RETVAL=$?
  else
    $OVS_BIN init 2>/dev/null
    $OVS_BIN add-br $BRIDGE_IFACE 2>/dev/null
    $OVS_BIN add-port $BRIDGE_IFACE $WIFI_IFACE 2>/dev/null
    ip link set $BRIDGE_IFACE up
    RETVAL=$?
  fi
  return $RETVAL
};

function DESTROY_BRIDGE()
{
  if [ -f /usr/local/sbin/OpenVSwitch.sh ]; then
    /usr/local/sbin/OpenVSwitch.sh stop $VERBOSE
    RETVAL=$?
  else
    $OVS_BIN del-port $BRIDGE_IFACE $WIFI_IFACE 2>/dev/null
    $OVS_BIN del-br $BRIDGE_IFACE 2>/dev/null
    RETVAL=$?
  fi
  return $RETVAL
};

# Function Checks Status of WiFi
function CheckWiFi()
{
  declare -i WIFI_STATUS=$DOWN
  for TEMP in $(dmesg | grep -v IPv6 | grep $WIFI_IFACE | $TAIL_BIN --lines=2); do
    if [ $TEMP == 'associated' ]; then
	WIFI_STATUS=$UP
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "\n\t*** Associated! ***\n"; fi
    else
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo $TEMP; fi
    fi
  done
  return $WIFI_STATUS
};

function CHECK_WPA_PROC
{
  declare -i WPA_PROC
  declare -i RETVAL
  WPA_PROC=$(pgrep $WPA_PROC) 2>/dev/null
  WPA_PROC=$((WPA_PROC))
  if [ $WPA_PROC -gt 0 ]; then RETVAL=$TRUE; else RETVAL=$FALSE; fi
  return $RETVAL
};

function WIFI_DOWN()
{
  ip link set $WIFI_IFACE down
  killall $WPA_PROC
  STATUS=$?
  return $STATUS
};

function WIFI_UP()
{
  declare -i STATUS=$DOWN
  declare -i RUN_LOOP=$TRUE
  declare -i LOOP_COUNT=-1
  while [ $RUN_LOOP -eq $TRUE ]; do
    ((LOOP_COUNT++))
    WIFI_DOWN
    if [ $LOOP_COUNT -eq 0 ]; then $WPA_BIN -D$DRIVER_80211,$DRIVER_EXTERNAL -i$WIFI_IFACE -c$CONFIG_FILE -B $WPA_DEBUG
    elif [ $LOOP_COUNT -eq 1 ]; then $WPA_BIN -D$DRIVER_80211 -i$WIFI_IFACE -c$CONFIG_FILE -B $WPA_DEBUG
    elif [ $LOOP_COUNT -eq 2 ]; then $WPA_BIN -D$DRIVER_EXTERNAL -i$WIFI_IFACE -c$CONFIG_FILE -B $WPA_DEBUG
    else $WPA_BIN -D$DRIVER_EXTERNAL,$DRIVER_80211 -i$WIFI_IFACE -c$CONFIG_FILE -B $WPA_DEBUG; fi
    sleep $VAR_WAIT
    CheckWiFi
    STATUS=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "CheckWiFi Returned: $STATUS"; fi
    if [ $LOOP_COUNT -eq $VAR_MAX_LOOP ]; then RUN_LOOP=$FALSE; fi
    if [ $STATUS -eq $UP ]; then RUN_LOOP=$FALSE; fi
  done
  ip link set $WIFI_IFACE up
  return $STATUS
};

function do_START()
{
  if [ $BOL_WIFI_UP -eq $TRUE ]; then WIFI_UP; fi
  if [ $BOL_SLEEP -eq $TRUE ]; then sleep $VAR_WAIT; fi
  if [ $BOL_MAKE_BRIDGE -eq $TRUE ]; then MAKE_BRIDGE; fi
  if [ $BOL_SLEEP -eq $TRUE ]; then sleep $VAR_WAIT; fi
  if [ $BOL_DHCLIENT -eq $TRUE ]; then dhclient -v $BRIDGE_IFACE; fi
  RETVAL=$?
  return $RETVAL
};

function do_STOP()
{
  if [ $BOL_DESTROY_BRIDGE -eq $TRUE ]; then DESTROY_BRIDGE; fi
  if [ $BOL_SLEEP -eq $TRUE ]; then sleep $VAR_WAIT; fi
  WIFI_DOWN
  RETVAL=$?
  return $RETVAL
};

for i in "$@"
do
case $i in
'start')
	export BOL_STOP=$TRUE
        export BOL_START=$TRUE
        ;;
'stop')
	export BOL_STOP=$TRUE
	export BOL_START=$FALSE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
'--skip-wifi-up')
	export BOL_WIFI_UP=$FALSE
	;;
'--wifi-up')
        export BOL_WIFI_UP=$TRUE
        ;;
'--skip-sleep')
	export BOL_SLEEP=$FALSE
	;;
'--sleep')
        export BOL_SLEEP=$TRUE
        ;;
'--skip-make-bridge')
	export BOL_MAKE_BRIDGE=$FALSE
	;;
'--make-bridge')
        export BOL_MAKE_BRIDGE=$TRUE
        ;;
'--skip-destroy-bridge')
	export BOL_DESTROY_BRIDGE=$FALSE
	;;
'--skip-bridge')
	export BOL_MAKE_BRIDGE=$FALSE
	export BOL_DESTROY_BRIDGE=$FALSE
	;;
'--skip-dhcp-client')
	export BOL_DHCLIENT=$FALSE
	;;
'--skip-wpa-debug')
	export BOL_WPA_DEBUG=$FALSE
	export WPA_DEBUG=""
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        BOL_START=$FALSE
        BOL_STOP=$FALSE
	#do_HELP
        RETVAL=1
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"
        do_STOP
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
	do_START
	RETVAL=$?
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "OK!"
else
	log_failure_msg "FAIL!"
fi

exit $RETVAL
## Done!
