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

# Source LSB function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.2

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit 1
fi

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh
export PREFIX="/etc/xen/init"

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=1
declare -ig RETVAL=$FAILURE

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
   # We Don't Know What Domains are Running, So Stopping them is a Little Bit Different
   for (( DOMAIN_INDEX=0; $((DOMAIN_INDEX)) <= $((XEN_FOUND_DOMAIN_INDEX)); DOMAIN_INDEX++ )); do
	DOM_NAME="${XEN_NAME_ARRAY[$((DOMAIN_INDEX))]}"
	DOM_ID="${XEN_ID_ARRAY[$((DOMAIN_INDEX))]}"
	DOM_ID=$((DOM_ID))
        if [ $DOM_ID -ne 0 ]; then
	    xl destroy $DOM_NAME
            RETVAL=$?
            sleep $VAR_WAIT
	fi
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
-w=* | --wait=*)
	X="${i#*=}"
	VAR_WAIT=$((X))
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

StoreXenArray
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

