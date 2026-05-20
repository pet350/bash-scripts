#! /bin/bash
### By: Peter Talbott 2019-06-15

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

# Define Integer Variables
declare -ig VAR_OLD_WEIGHT=256
declare -ig VAR_NEW_WEIGHT=512
declare -ig VAR_OLD_CAP=0
declare -ig VAR_NEW_CAP=0

# Define Domain Names
export OLD_NAME="Domain-0"
export NEW_NAME="Xen"

# Define Path Prefix Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"

# Define Binary Variables
export XL_BIN="$SBIN_PREFIX/xl"
export SLEEP_BIN="$BIN_PREFIX/sleep"

# Define Option Variables
export SCH_CREDIT="sched-credit"
export RENAME="rename"
export CAP="-c"
export WEIGHT="-w"
export DOMAIN="-d"
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

function CheckDomainName()
{
  declare -i RETVAL=$FAILURE
  for TEMP_DATA in ${XEN_NAME_ARRAY[@]}; do
     if [ $TEMP_DATA == $CHECK_DOMAIN ]; then RETVAL=$SUCCESS; fi
  done
  return $RETVAL
};

function do_START()
{
  declare -i RETVAL=$FAILURE
  export CHECK_DOMAIN="$OLD_NAME"
  CheckDomainName
  if [ $? -eq $SUCCESS ]; then
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $SCH_CREDIT $DOMAIN $OLD_NAME $CAP $VAR_NEW_CAP $WEIGHT $VAR_NEW_WEIGHT"; fi
    $XL_BIN $SCH_CREDIT $DOMAIN $OLD_NAME $CAP $VAR_NEW_CAP $WEIGHT $VAR_NEW_WEIGHT
    RETVAL=$?
    if [ $_BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $_VAR_WAIT; fi
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $RENAME $OLD_NAME $NEW_NAME"; fi
    $XL_BIN $RENAME $OLD_NAME $NEW_NAME
    if [ $_BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $_VAR_WAIT; fi
  else
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "Error: $CHECK_DOMAIN Not Found!"; fi
  fi
  return $RETVAL
};

function do_STOP()
{
  declare -i RETVAL=$FAILURE
  export CHECK_DOMAIN="$NEW_NAME"
  CheckDomainName
  if [ $? -eq $SUCCESS ]; then
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $SCH_CREDIT $DOMAIN $NEW_NAME $CAP $VAR_OLD_CAP $WEIGHT $VAR_OLD_WEIGHT"; fi
    $XL_BIN $SCH_CREDIT $DOMAIN $NEW_NAME $CAP $VAR_OLD_CAP $WEIGHT $VAR_OLD_WEIGHT
    RETVAL=$?
    if [ $_BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $_VAR_WAIT; fi
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $RENAME $NEW_NAME $OLD_NAME"; fi
    $XL_BIN $RENAME $NEW_NAME $OLD_NAME
    if [ $_BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $_VAR_WAIT; fi
  else
    if [ $_BOL_VERBOSE -eq $TRUE ]; then echo -e "Error: $CHECK_DOMAIN Not Found!"; fi
  fi
  return $RETVAL
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$VERSION"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Set Xen Domain-0 Pre-Defined Schedule Credit"
        printf "%-15s\t\t%-25s\n" "stop" "Unset Xen Domain-0 Schedule Credit"
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
