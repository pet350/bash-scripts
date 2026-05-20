#! /bin/bash
### BEGIN INIT INFO
# Provides:          Xen-VCPU-Pin
# Required-Start:    $network $remote_fs $syslog $xenDomains.sh $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Pin VCPUs on Xen Domains
# Description:       Pin VCPUs on Xen Domains
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-06-01

export __RUN_PREFIX="/usr/local/sbin"
export __PID_PREFIX="/run"
export __SCRIPT_NAME="vcpu-Pin.sh"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __OPTIONS=""

# Source LSB function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.1

# Define TRUE/FALSE Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE Variables
declare -ig SUCCESS=0
declare -ig FAIL=1

# Define BOOLEAN Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit $FAIL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

for i in "$@"
do
case $i in
'start')
	export BOL_STOP=$FALSE
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
esac
done

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"
        start_daemon -p $__PID_FILE $__EXEC_FILE stop
	#$__EXEC_FILE stop
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
        start_daemon -p $__PID_FILE $__EXEC_FILE start $__OPTIONS &
	#$__EXEC_FILE start && /etc/init.d/lxdm restart
        RETVAL=$?
fi


if [ $RETVAL -eq 0 ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

