#! /bin/bash
### By: Peter Talbott 2019-06-01

# Source function library.
source /lib/lsb/init-functions

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

# Define String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"
export XL_BIN="$SBIN_PREFIX/xl"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export SCH_CREDIT="sched-credit"
export VERBOSE=""

# Define Boolean Variables
declare -ig _BOL_START=$FALSE
declare -ig _BOL_STOP=$FALSE
declare -ig _BOL_VERBOSE=$FALSE
declare -ig _BOL_HELP=$FALSE
declare -ig _BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig _VAR_UNKNOWN=$FALSE
declare -ig _VAR_WAIT=1

declare -ag DOMAIN_NAME_ARRAY=("lede" "ldap" "ftp" "ubuntuserver" "www" "sql" "office" "zoneminder");
declare -ag DOMAIN_SCHD_ARRAY=("15" "45" "15" "75" "65" "75" "55" "45");

function do_START()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE
    declare -i BOL_RUN=$FALSE
    for DOMAIN in ${DOMAIN_NAME_ARRAY[@]}; do
	((INDEX++))
	SCHEDULE="${DOMAIN_SCHD_ARRAY[$((INDEX))]}"
	SCHEDULE=$((SCHEDULE))
	BOL_RUN=$FALSE
	for TEMP_DATA in ${XEN_NAME_ARRAY[@]}; do
	    if [ $TEMP_DATA == $DOMAIN ]; then BOL_RUN=$TRUE; fi
	done
	if [ $BOL_RUN -eq $TRUE ]; then
	  if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $SCH_CREDIT -d $DOMAIN -c $SCHEDULE"; fi
	  $XL_BIN $SCH_CREDIT -d $DOMAIN -c $SCHEDULE
	  RETVAL=$?
	  if [ $_BOL_WAIT -eq $TRUE ]; then sleep $_VAR_WAIT; fi
	fi
    done
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
	    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $SCH_CREDIT -d $DOM_NAME -c 0"; fi
            $XL_BIN $SCH_CREDIT -d $DOM_NAME -c 0
	    RETVAL=$?
	    if [ $_BOL_WAIT -eq $TRUE ]; then sleep $_VAR_WAIT; fi
	fi
   done
   return $RETVAL
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$VERSION"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Set Xen Domains Pre-Defined Schedule Credit"
        printf "%-15s\t\t%-25s\n" "stop" "Unset Xen Domain Schedule Credit"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

for i in "$@"
do
case $i in
'--no-wait')
	export _BOL_WAIT=$FALSE
	;;
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

StoreXenArray
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
