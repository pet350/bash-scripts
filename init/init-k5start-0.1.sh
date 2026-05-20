#! /bin/bash
### BEGIN INIT INFO
# Provides:          Kerberos5-Tokens
# Required-Start:    $network $remote_fs $syslog $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize Kerberos 5 Token Upon Login
# Description:       Initialize Kerberos 5 Token Upon Login
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-06-01

export __HOME=~
export __RUN_PREFIX="/usr/bin"
export __PID_PREFIX="/run"
export __SCRIPT_NAME="k5start"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __CHILD_PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.child.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __KEYTAB="$__HOME/.config/.keytab"

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

declare -ig RETVAL=$FAIL

#if [ $(id -u) -gt 0 ]; then
#    echo -e "Must be ran as Root!!"
#    exit $FAIL
#fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

if [ ! -f $__KEYTAB ]; then
    log_failure_msg "Error! $__KEYTAB Does Not Exist!"
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

export __OPTIONS="-a -b -f $__KEYTAB -p $__PID_FILE -L -q -K 30"

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"

	if [ -f $__PID_FILE ]; then
	  for DATA in $(cat $__PID_FILE); do
	    kill $DATA
	  done
	fi

	killall $__SCRIPT_NAME  2>/dev/null
	sleep 1
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
	if [ ! -f $__PID_FILE ]; then
           log_daemon_msg "Starting $RUN_CMD"
	   $__EXEC_FILE $__OPTIONS
           RETVAL=$?
	else
	   echo -e "Already Running!"
	   RETVAL=$SUCCESS
	fi
fi

if [ $RETVAL -eq 0 ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

exit $RETVAL
