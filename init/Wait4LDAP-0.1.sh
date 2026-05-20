#!/bin/bash
# Script to Wait For LDAP Connection
# By: Peter Talbott

# Source LSB function library.
source /lib/lsb/init-functions

# Current Version
VERSION=0.1

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

# Define Boolean Variables and set Default Values
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_VERBOSE=$FALSE

# Define String Variables
export RUN_CMD="$(basename $0)"
export PREFIX="/usr/bin"
export LDAP_BIN="$PREFIX/ldapwhoami"
export PING_BIN="/bin/ping"
export LDAP_HOST="ldap.gigaware.lan"
export LDAP_BIND_DN="cn=admin,dc=gigaware,dc=lan"
export LDAP_BIND_PW="IronMaiden666"

# Define Intiger Variables
declare -ig VAR_UNKNOWN=0
declare -ig VAR_PING_COUNT=2
declare -ig VAR_WAIT=4
declare -ig VAR_MAX_LOOP=10

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
  exit $FAILURE
fi

function do_PING_WAIT()
{
  declare -i COUNT=0
  declare -i RETVAL=$FAILURE
  declare -i BOL_LOOP=$TRUE
  while [ $BOL_LOOP -eq $TRUE ]; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "PING Loop Count:\t$COUNT"; fi
    $PING_BIN -c $VAR_PING_COUNT $LDAP_HOST >/dev/null
    RETVAL=$?
    if [ $RETVAL -eq $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$PING_BIN:\t\tSuccess!"; fi
      BOL_LOOP=$FALSE
    elif [ $COUNT -eq $VAR_MAX_LOOP ]; then
      BOL_LOOP=$FALSE
    else
      BOL_LOOP=$TRUE
      sleep $VAR_WAIT
    fi
  done
  return $RETVAL
};

# Function will wait for Successful LDAP Connection
function do_LDAP_WAIT()
{
  declare -i COUNT=0
  declare -i RETVAL=$FAILURE
  declare -i BOL_LOOP=$TRUE
  while [ $BOL_LOOP -eq $TRUE ]; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "LDAP Loop Count:\t$COUNT"; fi
    $LDAP_BIN -h $LDAP_HOST -D $LDAP_BIND_DN -w $LDAP_BIND_PW >/dev/null
    RETVAL=$?
    if [ $RETVAL -eq $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$LDAP_BIN:\tSuccess!"; fi
      BOL_LOOP=$FALSE
    elif [ $COUNT -eq $VAR_MAX_LOOP ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Max Loop:\t\tReached $VAR_MAX_LOOP Count!"; fi
      BOL_LOOP=$FALSE
    else
      sleep $VAR_WAIT
      BOL_LOOP=$TRUE
    fi
  done
  return $RETVAL
};

function do_STOP()
{
  return $SUCCESS
};

function do_START()
{
  declare -i RETVAL=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "\n"; echo -e "Checking Connection to:\t$LDAP_HOST"; fi
  do_PING_WAIT
  do_LDAP_WAIT
  RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then echo -e "Connected to:\t\t$LDAP_HOST\n"; else echo "Cannot Connect to $LDAP_HOST\n"; fi
  fi
  return $RETVAL
};


function do_HELP()
{
  printf "$RUN_CMD Version $VERSION\nHelp Section!\n\n"
  printf "%-15s\t\t%-25s\n" "-h  or --help" "Disply This Help Message"
  printf "%-15s\t%-25s\n\n" "-v  or --verbose" "Be Verbose"
  printf "%-15s\t\t%-25s\n" "start" "Waits For LDAP Connction"
  printf "%-15s\t\t%-25s\n" "stop" "Nothing"
  printf "%-15s\t\t%-25s\n" "restart" "Effective stop then start"
  echo -e ""
  return $SUCCESS
};


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
'-v' | '--verbose')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
        export BOL_HELP=$TRUE
        ;;
*)
        (( VAR_UNKNOWN++ ))
        echo -e "$RUN_CMD Version $VERSION\nUnknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        do_HELP
        exit $FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
        exit $VAR_UNKNOWN
fi

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



