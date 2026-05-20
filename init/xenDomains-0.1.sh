#!/bin/bash
### BEGIN INIT INFO
# Provides:          Starts init-resolv.conf service
# Required-Start:    $network $remote_fs $syslog xen
# Required-Stop:     $network $remote_fs $syslog xen
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Setup xen domains
# Description:       Setup xen domains
### END INIT INFO
# chkconfig: 2345 08 08

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

export PREFIX="/etc/xen/init"

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=2


function do_START()
{
   for x in $(ls -1 $PREFIX); do
	xl create $PREFIX/$x
	RETVAL=$?
	sleep $VAR_WAIT
   done
#   xl cpupool-numa-split
#   xl list -n
   return $RETVAL
};


function do_STOP()
{
   for x in $(ls -1 $PREFIX); do
        xl destroy $x
        RETVAL=$?
        sleep $VAR_WAIT
   done
   return $RETVAL
};

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
        log_daemon_msg "Stopping $RUNCMD"
        do_STOP
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
	RETVAL=$?
fi

if [ $RETVAL -eq 0 ]; then
        log_success_msg
else
	log_failure_msg
fi

exit $RETVAL
## Done!

