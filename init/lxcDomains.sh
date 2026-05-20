#!/bin/bash
# Shell Script By: Peter Talbott

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

# Define Run Command and Version
export RUN_CMD="$(basename $0)"
export VERSION="0.3"

# Define Global Boolean Variables
declare -ig BOL_TEMP=$FALSE
if [ ${#BOL_DESTROY}	-eq 0 ]; then declare -ig BOL_DESTROY=$FALSE;	fi
if [ ${#BOL_TEST}	-eq 0 ]; then declare -ig BOL_TEST=$FALSE;	fi

# Define Directoy Prefix String Variables
if [ ${#BIN_PREFIX}	-eq 0 ]; then export BIN_PREFIX="/bin";		fi
if [ ${#SBIN_PREFIX}	-eq 0 ]; then export SBIN_PREFIX="/sbin";	fi
if [ ${#USER_PREFIX}	-eq 0 ]; then export USER_PREFIX="/usr";	fi
export CFG_PREFIX="/etc"
export LIBVIRT_PREFIX="$CFG_PREFIX/libvirt"
export LXC_PREFIX="$LIBVIRT_PREFIX/lxc"
export LXC_INIT_PREFIX="$LXC_PREFIX/init"
export CGROUP_PREFIX="/sys/fs/cgroup"
export CGROUP_SUFFIX="/machine/production.partition"

# Define Binary Variables
export SYSCTL_BIN="$SYSTEMCTL_BIN"
export FIND_BIN="$BIN_PREFIX/find"

# Define Option Variables
export VIRSH_LXC_OPT="-c lxc:///system"
export CREATE_OPT="create"
export SHUTDOWN_OPT="shutdown"
export DESTROY_OPT="destroy"
export LIST_OPT="list"
export OUTPUT_PIPE="/dev/null"

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
declare -ag CGROUP_ARRAY=("blkio" "cpu,cpuacct" "cpuset" "devices" "freezer" "memory" "net_cls" "perf_event");

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
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    echo -e "$RUN_CMD: Current Running LXC Domain Count:\t$DOMAIN_COUNT" | tee $OUTPUT_PIPE
    printf "\n"
  fi
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
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$RUN_CMD: Executing: $VIRSH_BIN $VIRSH_LXC_OPT $SHUTDOWN_OPT $LXC_DOMAIN" | tee $OUTPUT_PIPE; fi
    $VIRSH_BIN $VIRSH_LXC_OPT $SHUTDOWN_OPT $LXC_DOMAIN
    export RETVAL=$?
    $SLEEP_BIN $SHUTDOWN_WAIT
    if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS | tee $OUTPUT_PIPE; fi
  done

  return $RETVAL
};

function CREATE_CGROUPS()
{
  CPUSET_PREFIX="$CGROUP_PREFIX/cpuset/machine"
  PROD_PART="production.partition"
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Creating Required CGROUPS"; fi
  for CGROUP_FOLDER in ${CGROUP_ARRAY[@]}; do
    CGROUP_PATH="$CGROUP_PREFIX/$CGROUP_FOLDER/$CGROUP_SUFFIX"
    if [ ! -d $CGROUP_PATH ]; then
      if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Creating $CGROUP_PATH"; fi
      mkdir -p $CGROUP_PATH
    else
      if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] $CGROUP_PATH Already Exists"; fi
    fi
  done
  for TEMP_DATA in cpuset.cpus  cpuset.mems; do
    cat $CPUSET_PREFIX/$TEMP_DATA > $CPUSET_PREFIX/$PROD_PART/$TEMP_DATA
  done
  return $?
};

function CREATE_LXC_DOMAIN()
{
  declare -i RETVAL=$SUCCESS
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$RUN_CMD: Attempting To Create $DOMAIN" | tee $OUTPUT_PIPE; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] $VIRSH_BIN $VIRSH_LXC_OPT $CREATE_OPT $DOMAIN"; fi
  $VIRSH_BIN $VIRSH_LXC_OPT $CREATE_OPT $DOMAIN
  export RETVAL=$?
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS | tee $OUTPUT_PIPE; fi
  return $RETVAL
};

function CREATE_LXC_DOMAIN_LOOP()
{
  declare -i RETVAL=$SUCCESS
  declare -i COUNT=0
  ls -1 $LXC_INIT_PREFIX/*.xml 2>/dev/null >/dev/null
  if [ $? -eq $SUCCESS ]; then
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    for DOMAIN in $( $FIND_BIN $LXC_INIT_PREFIX -iname '*.xml' ); do
      BOL_LOOP=$TRUE
      COUNT=0
      while [ $BOL_LOOP -eq $TRUE ]; do
	((COUNT++))
	CREATE_LXC_DOMAIN
	RETVAL=$?
	if [ $RETVAL -eq $SUCCESS ] || [ $COUNT -eq $LIMIT ]; then
	  BOL_LOOP=$FALSE
	else
	  BOL_LOOP=$TRUE
	  $SLEEP_BIN $RETRY_WAIT
	  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$RUN_CMD: Retry Attempt $COUNT of $LIMIT" | tee $OUTPUT_PIPE; fi
	fi
      done
    done
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$RUN_CMD: $LXC_INIT_PREFIX is Empty! Nothing To Do!" | tee $OUTPUT_PIPE; fi
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
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION"
	exit $SUCCESS
	;;
'--dmesg')
	export OUTPUT_PIPE="/dev/kmsg"
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_VERBOSE -eq $TRUE ]; then
  echo -e "$(SHOW_DATE_TIME): $RUN_CMD: $VERSION\tCommon Definisions: $COMDEF_VERSION"  | tee $OUTPUT_PIPE
fi

if [ $BOL_STOP -eq $TRUE ]; then
  STORE_LXC_DOMAIN_ARRAY
  SHUTDOWN_LXC_DOMAINS
  export EXIT_VAL=$?
  export RETVAL=$EXIT_VAL
fi

if [ $BOL_START -eq $TRUE ]; then
  CREATE_CGROUPS
  STORE_LXC_DOMAIN_ARRAY
  CREATE_LXC_DOMAIN_LOOP
  export EXIT_VAL=$?
  export RETVAL=$EXIT_VAL
fi

COUNT_DOMAINS
if [ $BOL_VERBOSE -eq $TRUE ]; then
  echo -e "$RUN_CMD: Current Running LXC Domain Count:\t$DOMAIN_COUNT" | tee $OUTPUT_PIPE
  printf "\n"
fi
STORE_LXC_DOMAIN_ARRAY

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS | tee $OUTPUT_PIPE; fi
exit $EXIT_VAL