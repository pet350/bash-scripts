#! /bin/bash
### BEGIN INIT INFO
# Provides:          RAR-Backup-ROMS
# Required-Start:    $network $remote_fs $syslog $xenDomains.sh $all
# Required-Stop:
# Default-Start:
# Default-Stop:      0 1 6
# Short-Description: Perform RAR Backup of Video Game ROMS
# Description:       Perform RAR Backup of Video Game ROMS
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-06-14

export __RUN_PREFIX="/usr/local/sbin"
export __PID_PREFIX="/run"
export __SCRIPT_NAME="rarBackup.sh"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __OPTIONS="--roms --verbose"

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
        start_daemon -p $__PID_FILE $__EXEC_FILE $__OPTIONS &
	#$__EXEC_FILE start && /etc/init.d/lxdm restart
        RETVAL=$?
fi


if [ $RETVAL -eq 0 ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

