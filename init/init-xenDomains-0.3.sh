#!/bin/bash
### BEGIN INIT INFO
# Provides:          xenDomains.sh
# Required-Start:    $network $remote_fs $syslog $openvswitch-configuration $xen
# Required-Stop:     $network $remote_fs $syslog $xen
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Startup init XEN Domains
# Description:       Starts init XEN Domains located in /etc/xen/init
### END INIT INFO
# chkconfig: 2345 08 08

export __RUN_PREFIX="/usr/local/sbin"
export __PID_PREFIX="/run"
export __SCRIPT_NAME="xenDomains.sh"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __OPTIONS="--wait=2"

# Source LSB function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.3

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0
declare -ig SUCCESS=0
declare -ig FAIL=1
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit $FAIL
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
        ;;
'stop')
        export BOL_STOP=$TRUE
        ;;
'restart')
        export BOL_STOP=$TRUE
        export BOL_START=$TRUE
        ;;
esac
done

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"
        start_daemon -p $__PID_FILE $__EXEC_FILE stop
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
        start_daemon -p $__PID_FILE $__EXEC_FILE start $__OPTIONS &
        RETVAL=$?
fi


if [ $RETVAL -eq 0 ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

exit $RETVAL
