#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
if [ -f /lib/lsb/init-functions ]; then
  source /lib/lsb/init-functions
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEMP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_LOG_RESULTS=$TRUE

# Define Global SYSCTL Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_STATUS=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_HELP=$FALSE

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export CFG_PREFIX="/etc"

# Define Binary Variables
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export HEAD_BIN="$USER_PREFIX$BIN_PREFIX/head"
export TAIL_BIN="$USER_PREFIX$BIN_PREFIX/tail"
export FIND_BIN="$USER_PREFIX$BIN_PREFIX/find"

# Define Global Integer Variables
declare -ig EXIT_VAL=$SUCCESS
declare -i  RETVAL=$SUCCESS
declare -ig VAR_WAIT=1
declare -ig LIMIT=10
declare -ig RETRY_WAIT=15

# Define Global String Variables
export START="start"
export STOP="stop"
export RESTART="restart"
export STATUS="status"

# Define Global Arrays
declare -ag SERVICE_ARRAY=("systemd-tmpfiles-setup.service" "tomcat8" "nfs-server" "autofs" "guacd" "apache2");


if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { service1 service2 service3  } --help"
    exit $EXIT_VAL
fi


function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$SYSCTL_BIN $SYSCTL_OPT $SERVICE_NAME: Success!"
  else
    log_failure_msg "$SYSCTL_BIN $SYSCTL_OPT $SERVICE_NAME: Failure!"
  fi
  return $RETVAL
};


function SYSCTL_SERVICE()
{
  declare BOL_LOOP=$TRUE
  declare INDEX=-1
  declare -ig RETVAL=$FAILURE
  while [ $BOL_LOOP -eq $TRUE ]; do
    ((INDEX++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$SYSCTL_BIN $SYSCTL_OPT $SERVICE_NAME"; fi
    $SYSCTL_BIN $SYSCTL_OPT $SERVICE_NAME
    RETVAL=$?
    if [ $RETVAL -eq $SUCCESS ]; then
      BOL_LOOP=$FALSE
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Failed! Attempt: $INDEX"; fi
      if [ $BOL_WAIT -eq $TRUE ]; then $LEEP_BIN $VAR_WAIT; fi
    fi
    if [ $INDEX -eq $LIMIT ]; then BOL_LOOP=$FALSE; fi
  done
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
  return $RETVAL
};

function CHECK_SERVICE()
{
  $SYSCTL_BIN $STATUS $SERVICE_NAME >/dev/null 2>/dev/null
  return $?
};

function SERVICE_LOOP()
{
  declare -ig RETVAL
  for TEMP in ${SERVICE_ARRAY[@]}; do
    export SERVICE_NAME="$TEMP"
    if [ $SYSCTL_OPT == $START ]; then
      CHECK_SERVICE
      if [ $? -ne $SUCCESS ]; then SYSCTL_SERVICE; fi
    else
      SYSCTL_SERVICE
    fi
    RETVAL=$?
  done
  return $RETVAL
};

function DO_START()
{
  export SYSCTL_OPT="$START"
  SERVICE_LOOP
  return $?
};

function DO_STOP()
{
  export SYSCTL_OPT="$STOP"
  SERVICE_LOOP
  return $?
};


for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
        export BOL_LOG_RESULTS=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
        export BOL_LOG_RESULTS=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'--test')
	export SYSCTL_BIN="$BIN_PREFIX/true"
	export SLEEP_BIN="$BIN_PREFIX/true"
	;;
'start')
	export BOL_STOP=$FALSE
	export BOL_START=$TRUE
	;;
'stop')
	export BOL_STOP=$TRUE
	export BOL_START=$FALSE
	;;
'restart' | 'reload')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_STOP -eq $TRUE ]; then DO_STOP; fi

if [ $BOL_START -eq $TRUE ]; then DO_START; fi

exit $?