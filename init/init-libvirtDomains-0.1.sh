#!/bin/bash
### BEGIN INIT INFO
# Provides:          libvirtDomains.sh
# Required-Start:    $network $remote_fs $syslog $libvirtd
# Required-Stop:     $network $remote_fs $syslog $libvirtd
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Startup LIBVIRT Domains
# Description:       Startup LIBVIRT Domains
### END INIT INFO
# chkconfig: 2345 08 08

# Define Prefix Directories
export __RUN_PREFIX="/usr/local/sbin"
export __PID_PREFIX="/run"
export __LOG_PREFIX="/var/log/libvirt/$(date +%F)"

# Defines Script Options
export __WAIT="--wait=4"
#export __RETRY_WAIT="--retry-wait=15"
#export __RETRY_LIMIT="--retry-limit=10"
export __VERBOSE="--verbose"

# Define Daemon Options
export __SCRIPT_NAME="libvirtDomains.sh"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __LOG_FILE="$__LOG_PREFIX/$__SCRIPT_NAME-$(date +%H-%M).log"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __OPTIONS="$__WAIT $__RETRY_WAIT $__RETRY_LIMIT $__VERBOSE"

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

export RUN_CMD="$(basename $0)"
_VER=0.1

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

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

# Create Log Prefix If It Doesn't Exist
if [ ! -d $__LOG_PREFIX ]; then mkdir -p $__LOG_PREFIX; fi

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
