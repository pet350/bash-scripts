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
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_REVERSE=$FALSE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig VAR_WAIT=1
declare -ig VAR_MIN_CPU=0
declare -ig VAR_MAX_CPU=1
declare -ig RETVAL=$FAILURE

function do_START()
{
  declare -i PIN=1
  declare -i RETVAL=$FAILURE
  if [ $BOL_REVERSE -eq $TRUE ]; then PIN=0; fi
  for TEMP in ${XEN_NAME_ARRAY[@]}; do
    ((PIN++))
    if [ $((PIN)) -gt $((VAR_MAX_CPU)) ]; then PIN=$VAR_MIN_CPU; fi
    if [ $TEMP != "Domain-0" ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "xl vcpu-pin $TEMP 0 $((PIN)) $((PIN))"; fi
      $XL_BIN vcpu-pin $TEMP 0 $((PIN)) $((PIN))
      RETVAL=$?
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    fi
  done
  return $RETVAL
};

function do_STOP()
{
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
	export BOL_WAIT=$FALSE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	export BOL_START=$FALSE
	export BOL_STOP=$FALSE
	;;
'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
        ;;
'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export XL_BIN="$BIN_PREFIX/false"
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
'--reverse')
	export BOL_REVERSE=$TRUE
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
	do_HELP
        RETVAL=$FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

StoreXenArray
if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	do_STOP
	RETVAL=$SUCCESS
fi

if [ $BOL_START -eq $TRUE ]; then
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
