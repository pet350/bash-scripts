#!/bin/bash
# Simple Bash Script to Start all
# XEN Domains listed in /etc/xen/init

# Define True/False Boolean Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define Success/Failure Boolean Variables
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Run Command
export RUN_CMD="$(basename $0)"
declare -ig BOL_XEN_HYPERVISOR=$FALSE

# Define Script Version
_VER=0.7

# ----------------------------------------------------------------------------- #
# First We'll Check To Make Sure Everything Is OK Before Proceding		#
# Check To Make Sure ROOT is Running This Script
if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nMust be ran as Root!!"
    exit $FAILURE
fi

# Check To Make Sure That /usr/sbin/xl Exists
if [ ! -f /usr/sbin/xl ]; then
    echo -e "$RUN_CMD Version $_VER\nError: /usr/sbin/xl Does NOT Exist!"
    exit $FAILURE
fi

# Check To Make Sure XEN Hypervisor IS Running
/usr/sbin/xl info 2>/dev/null
if [ $? -ne $SUCCESS ]; then
    echo -e "$RUN_CMD Version $_VER\nCould Not Find XEN Hypervisor!"
    exit $FAILURE
fi

# Check To Make Sure There Is Some Option To Parse At The Command Line
if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAILURE
fi

# Made It This Far And All Checked Out. Lets Continue With The Script!		#
# ----------------------------------------------------------------------------- #

# Source LSB function library.
source /lib/lsb/init-functions

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export CFG_PREFIX="/etc"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export AUTO_PREFIX="$CFG_PREFIX/xen/init"

# Define Application Binaries
export NMAP_BIN="$USER_PREFIX$BIN_PREFIX/nmap"
export XL_BIN="$USER_PREFIX$SBIN_PREFIX/xl"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export PS_BIN="$BIN_PREFIX/ps"
export GREP_BIN="$BIN_PREFIX/grep"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export KILL_BIN="$BIN_PREFIX/kill"

# Define Application Options
export VERBOSE=""
export CREATE="create"
export LIST="vcpu-list"
export DESTROY="destroy"
export INFO="info"

# Define Global Booleans
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_REQUIRED=$FALSE

# Define Global Booleans To Call Other Services
declare -ig BOL_WEBSOCKIFY=$TRUE
declare -ig BOL_SCHED_CREDIT=$TRUE
declare -ig BOL_VCPU_PIN=$TRUE

# Define Global Integer Variable Defaults
declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=1
declare -ig VAR_RETRY_WAIT=10
declare -ig VAR_RETRY_LIMIT=5
declare -ig RETVAL=$FAILURE

function CREATE_DOMAIN()
{
  declare -i COUNT=0
  declare -i BOL_RETRY=$TRUE
  declare -i RETVAL=$FAILURE

  while [ $BOL_RETRY -eq $TRUE ]; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $CREATE $AUTO_DOMAIN"; fi
    $XL_BIN $CREATE $AUTO_DOMAIN
    RETVAL=$?
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    if [ $RETVAL -eq $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Domain: $AUTO_DOMAIN Created Successfuly!\n"; fi
      BOL_RETRY=$FALSE
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Domain: $AUTO_DOMAIN Failed!"; fi
      if [ $COUNT -eq $VAR_RETRY_LIMIT ]; then
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Reached Retry Limit: $VAR_RETRY_LIMIT!\nGiving Up On Domain: $AUTO_DOMAIN\n"; fi
        BOL_RETRY=$FALSE
      else
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Retry Attempt: $COUNT\nWill Retry Creating Domain: $AUTO_DOMAIN in $VAR_RETRY_WAIT Seconds\n"; fi
        $SLEEP_BIN $VAR_RETRY_WAIT
	BOL_RETRY=$TRUE
      fi
    fi
  done
  return $RETVAL
};

# Function Called from the 'start' or 'restart' Command
function do_START()
{
  declare -i RETVAL=$FAILURE
  for TEMP_DATA in $(ls -1 $AUTO_PREFIX); do
    export AUTO_DOMAIN="$AUTO_PREFIX/$TEMP_DATA"
    CREATE_DOMAIN
    RETVAL=$?
  done
  if [ $BOL_VERBOSE -eq $TRUE ]; then $XL_BIN $LIST; fi
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
	    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$XL_BIN $DESTROY $DOM_NAME\n"; fi
	    $XL_BIN $DESTROY $DOM_NAME
            RETVAL=$?
            if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
	fi
   done
   if [ $BOL_VERBOSE -eq $TRUE ]; then $XL_BIN $LIST; fi

   # Remove Any Leftover Files In /var/lib/xen
   for TEMP in $(find /var/lib/xen -name '*json'|grep -v userdata-d.0); do
      rm $VERBOSE $TEMP
   done
   return $RETVAL
};

$XL_BIN $INFO 2>/dev/null >/dev/null
if [ $? -eq $SUCCESS ]; then export BOL_XEN_HYPERVISOR=$TRUE; fi

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
	export BOL_REQUIRED=$TRUE
        ;;
'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	export BOL_REQUIRED=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	export BOL_REQUIRED=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'--no-websockify')
	export BOL_WEBSOCKIFY=$FALSE
	;;
'--no-sched-credit')
	export BOL_SCHED_CREDIT=$FALSE
	;;
'--no-vcpu-pin')
	export BOL_VCPU_PIN=$FALSE
	;;
-w=* | --wait=*)
	X="${i#*=}"
	VAR_WAIT=$((X))
	;;
-rw=* | --retry-wait=*)
	X="${i#*=}"
	VAR_RETRY_WAIT=$((X))
        ;;
-rl=* | --retry-limit=*)
        X="${i#*=}"
        VAR_RETRY_LIMIT=$((X))
        ;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_XEN_HYPERVISOR -eq $FALSE ]; then
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "XEN Hypervisor not detected!"; fi
	exit $FAILURE
fi

if [ $BOL_HELP -eq $TRUE ]; then
	#do_HELP
        exit $FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	exit $VAR_UNKNOWN
fi

if [ $BOL_REQUIRED -eq $FALSE ]; then
    echo -e "$RUN_CMD Version $_VER\tMissing Required Parameter!\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAILURE
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
	if [ $BOL_WEBSOCKIFY -eq $TRUE ]; then /etc/init.d/init-xenWebSockify.sh start; fi
	if [ $BOL_VCPU_PIN -eq $TRUE ]; then /etc/init.d/init-vcpu-Pin.sh start; fi
	if [ $BOL_SCHED_CREDIT -eq $TRUE ]; then /etc/init.d/init-SchedCredit.sh start; fi
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "OK!"
else
	log_failure_msg "FAIL!"
fi

exit $RETVAL
## Done!

