#! /bin/bash
### BEGIN INIT INFO
# Provides:          Boot-Timestamp
# Required-Start:    $network $remote_fs $syslog $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Log Boot and Shutdown Time Stamp
# Description:       Log Boot and Shutdown Time and Date
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-04-01

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

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $RUN_CMD { start | stop } --help"
    exit 1
fi

export version="0.1"
export BOOT_MESSAGE="Bootup Timestamp:"
export SHUTDOWN_MESSAGE="Shutdown Timestamp:"
export LOG_PREFIX="/var/log"
export LOG_FILENAME="BootTimeStamp.log"
export VERBOSE=""

declare -ig _BOL_START=$FALSE
declare -ig _BOL_STOP=$FALSE
declare -ig _BOL_VERBOSE=$FALSE
declare -ig _BOL_HELP=$FALSE
declare -ig _VAR_UNKNOWN=$FALSE

function do_START()
{
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$BOOT_MESSAGE\t$(date)\n"; fi
    echo -e "$BOOT_MESSAGE\t$(date)" >>$LOG_PREFIX/$LOG_FILENAME
    return $SUCCESS
};

function do_STOP()
{
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$SHUTDOWN_MESSAGE\t$(date)\n"; fi
    echo -e "$SHUTDOWN_MESSAGE\t$(date)" >>$LOG_PREFIX/$LOG_FILENAME
    return $SUCCESS

};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$version"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Log Startup Timestamp"
        printf "%-15s\t\t%-25s\n" "stop" "Log Shutdown Timestamp"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export _BOL_HELP=$TRUE
	export _BOL_START=$FALSE
	export _BOL_STOP=$FALSE
	;;
'start')
        export _BOL_START=$TRUE
	export _BOL_STOP=$FALSE
        ;;
'stop')
	export _BOL_START=$FALSE
	export _BOL_STOP=$TRUE
	;;
'restart')
	export _BOL_STOP=$TRUE
	export _BOL_START=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export _BOL_VERBOSE=$TRUE
	;;
*)
        (( _VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $_BOL_HELP -eq $TRUE ]; then
        _BOL_START=$FALSE
        _BOL_STOP=$FALSE
	do_HELP
        RETVAL=$FAILURE
fi

if [ $_VAR_UNKNOWN -gt 0 ]; then
	_BOL_START=$FALSE
	_BOL_STOP=$FALSE
	RETVAL=$_VAR_UNKNOWN
fi

if [ $_BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	do_STOP
	RETVAL=$SUCCESS
fi

if [ $_BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
	RETVAL=$SUCCESS
fi

if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

## DONE!
exit $RETVAL
