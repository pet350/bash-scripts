#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
source /lib/lsb/init-functions

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
declare -ig BOL_DESTROY=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_ENABLE=$FALSE
declare -ig BOL_DISABLE=$FALSE

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export CFG_PREFIX="/etc"
export LIBVIRT_PREFIX="$CFG_PREFIX/libvirt"
export LXC_PREFIX="$LIBVIRT_PREFIX/lxc"
export LXC_INIT_PREFIX="$LXC_PREFIX/init"

# Define Binary Variables
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export VIRSH_BIN="$USER_PREFIX$BIN_PREFIX/virsh"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export HEAD_BIN="$USER_PREFIX$BIN_PREFIX/head"
export TAIL_BIN="$USER_PREFIX$BIN_PREFIX/tail"
export FIND_BIN="$USER_PREFIX$BIN_PREFIX/find"

# Define Option Variables
export VIRSH_LXC_OPT="-c lxc:///system"
export CREATE_OPT="create"
export SHUTDOWN_OPT="shutdown"
export DESTROY_OPT="destroy"
export LIST_OPT="list"

# Define Global Integer Variables
declare -ig EXIT_VAL=$SUCCESS
declare -i  RETVAL=$SUCCESS
declare -ig VAR_WAIT=1
declare -ig SHUTDOWN_WAIT=30
declare -ig LIMIT=10
declare -ig RETRY_WAIT=15
declare -ig DOMAIN_COUNT=$(( $($VIRSH_BIN $VIRSH_LXC_OPT $LIST_OPT | $WC_BIN -l)-3 ))

# Define Global Arrays
declare -ag LXC_DOMAIN_ARRAY=();

function COUNT_DOMAINS()
{
  declare -i RETVAL=0
  declare -ig DOMAIN_COUNT=0

  RETVAL=$(( $($VIRSH_BIN $VIRSH_LXC_OPT $LIST_OPT | $WC_BIN -l)-3 ))
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Running LXC Domain Count:\t$RETVAL\n"; fi
  export DOMAIN_COUNT=$((RETVAL))
  return $RETVAL
};

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "Success!"
  else
    log_failure_msg "Failure!"
  fi
  return $RETVAL
};

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { start | stop | restart } --help"
    exit $EXIT_VAL
fi

if [ ! -d $LXC_INIT_PREFIX ]; then mkdir -p $LXC_INIT_PREFIX; fi

function STORE_LXC_DOMAIN_ARRAY()
{
  declare -i LINE_COUNT=-1
  declare -i INDEX=-1
  declare -i DOMAIN_COUNT=0
  declare -ag LXC_DOMAIN_ARRAY=();

  COUNT_DOMAINS
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Current Running LXC Domain Count:\t$DOMAIN_COUNT\n"; fi
  while IFS= read line; do
    LINE_COUNT=-1
    for TEMP in $line; do
      ((LINE_COUNT++))
      if [ $LINE_COUNT -eq 1 ]; then
        ((INDEX++))
        LXC_DOMAIN_ARRAY[$((INDEX))]="$TEMP"
        if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] TEMP:\t$TEMP\n"; fi
      fi
    done
  done < <( $VIRSH_BIN $VIRSH_LXC_OPT $LIST_OPT | $TAIL_BIN --lines=$((DOMAIN_COUNT+1)) | $HEAD_BIN --lines=$((DOMAIN_COUNT)) )
  return $INDEX
};

function SHUTDOWN_LXC_DOMAINS()
{
  declare -i RETVAL=$SUCCESS

  if [ $BOL_DESTROY -eq $TRUE ]; then
    export SHUTDOWN_OPT="$DESTROY_OPT"
    export SHUTDOWN_WAIT=2
  fi

  for LXC_DOMAIN in ${LXC_DOMAIN_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $VIRSH_BIN $VIRSH_LXC_OPT $SHUTDOWN_OPT $LXC_DOMAIN"; fi
    $VIRSH_BIN $VIRSH_LXC_OPT $SHUTDOWN_OPT $LXC_DOMAIN
    export RETVAL=$?
    $SLEEP_BIN $SHUTDOWN_WAIT
    if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
  done

  return $RETVAL
};

function CREATE_LXC_DOMAIN()
{
  declare -i RETVAL=$SUCCESS
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Attempting To Create $DOMAIN"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] $VIRSH_BIN $VIRSH_LXC_OPT $CREATE_OPT $DOMAIN"; fi
  $VIRSH_BIN $VIRSH_LXC_OPT $CREATE_OPT $DOMAIN
  export RETVAL=$?
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
  return $RETVAL
};

function CREATE_LXC_DOMAIN_LOOP()
{
  declare -i RETVAL=$SUCCESS
  declare -i COUNT=0
  ls -1 $LXC_INIT_PREFIX/*.xml 2>/dev/null >/dev/null
  if [ $? -eq $SUCCESS ]; then
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    for DOMAIN in $( $FIND_BIN $LXC_INIT_PREFIX -name '*.xml' ); do
      BOL_LOOP=$TRUE
      COUNT=0
      while [ $BOL_LOOP -eq $TRUE ]; do
	((COUNT++))
	CREATE_LXC_DOMAIN
	RETVAL=$?
	if [ $RETVAL -eq $SUCCESS ]; then
	  BOL_LOOP=$FALSE
	elif [ $COUNT -eq $LIMIT ]; then
	  BOL_LOOP=$FALSE
	else
	  BOL_LOOP=$TRUE
	  $SLEEP_BIN $RETRY_WAIT
	  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Retry Attempt $COUNT of $LIMIT"; fi
	fi
      done
    done
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$LXC_INIT_PREFIX is Empty! Nothing To Do!"; fi
  fi
  return $RETVAL
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
'-t' | '--test' )
	export BOL_TEST=$TRUE
	export VIRSH_BIN="$BIN_PREFIX/true"
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
'--destroy')
	export BOL_DESTROY=$TRUE
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
'start')
	export BOL_START=$TRUE
	export BOL_STOP=$FALSE
	;;
'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	;;
'restart')
	export BOL_START=$TRUE
	export BOL_STOP=$TRUE
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_STOP -eq $TRUE ]; then
  STORE_LXC_DOMAIN_ARRAY
  SHUTDOWN_LXC_DOMAINS
  export EXIT_VAL=$?
  export RETVAL=$EXIT_VAL
fi

if [ $BOL_START -eq $TRUE ]; then
  STORE_LXC_DOMAIN_ARRAY
  CREATE_LXC_DOMAIN_LOOP
  export EXIT_VAL=$?
  export RETVAL=$EXIT_VAL
fi

COUNT_DOMAINS
if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Current Running LXC Domain Count:\t$DOMAIN_COUNT\n"; fi
STORE_LXC_DOMAIN_ARRAY

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
exit $EXIT_VAL