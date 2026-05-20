#! /bin/bash
### By: Peter Talbott 2019-06-01

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit $FAILURE
fi

# Define Prefix Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export CFG_PREFIX="/etc"

# Define Execuatable Binaries
if [ -f "$BIN_PREFIX/lsmod" ]; then export LSMOD_BIN="$BIN_PREFIX/lsmod"
elif [ -f "$SBIN_PREFIX/lsmod" ]; then export LSMOD_BIN="$SBIN_PREFIX/lsmod"
else echo -e "$RUN_CMD\tVersion: $VERSION\nlsmod not found!\n"; exit $FAILURE; fi

export GREP_BIN="$BIN_PREFIX/grep"
export MODPROBE_BIN="$SBIN_PREFIX/modprobe"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export TEST_BIN="$BIN_PREFIX/true"

# Define Configuration File
export CFG_FILE="$CFG_PREFIX/modules.conf"

# Define String Variables
export VERBOSE=""
export REMOVE=""
export MODULE=""
export OPTION=""

# Define Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_REMOVE=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig VAR_WAIT=1
declare -ig VAR_STOP_LIMIT=1
declare -ig VAR_START_LIMIT=3
declare -ig VAR_LIMIT=$VAR_START_LIMIT
declare -ig EXITVAL=$FAILURE

# Define Global Arrays
declare -ag MODULE_ARRAY=();
declare -ag MODULE_OPTIONS_ARRAY=();

if [ ! -f $CFG_FILE ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\n$CFG_FILE does not exist!"
    exit $FAILURE
fi

function GET_MODULE_ARRAY()
{
  declare -i LINE_INDEX=-1
  declare -i ARRAY_INDEX=-1
  while IFS= read LINE; do
    LINE_INDEX=-1
    ((ARRAY_INDEX++))
    for DATA in $LINE; do
      ((LINE_INDEX++))
      if [ $LINE_INDEX -eq 0 ]; then
	MODULE_ARRAY[$((ARRAY_INDEX))]="$DATA"
      else
	MODULE_OPTIONS_ARRAY[$((ARRAY_INDEX))]="${MODULE_OPTIONS_ARRAY[$((ARRAY_INDEX))]} $DATA"
      fi
    done
    TEMP_MODULE="${MODULE_ARRAY[$((ARRAY_INDEX))]}"
    TEMP_OPTIONS="${MODULE_OPTIONS_ARRAY[$((ARRAY_INDEX))]}"
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Module: $TEMP_MODULE:\t Options: $TEMP_OPTIONS"; fi
  done < <(cat $CFG_FILE)
  return $SUCCESS
};

function DO_MODPROBE()
{
  declare -i RETVAL=$FAILURE

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$MODPROBE_BIN $VERBOSE $REMOVE $MODULE"; fi
  $MODPROBE_BIN $VERBOSE $REMOVE $MODULE $OPTION
  RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "SUCCESS!"
    else
        log_failure_msg "FAILURE!"
    fi
  fi
  return $RETVAL
};

function TEST_MODULE()
{
  declare -i RETVAL=$FAILURE
  $LSMOD_BIN | $GREP_BIN $MODULE >/dev/null
  RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
        echo -e "$MODULE Is Loaded!"
    else
        echo -e "$MODULE Is Not Loaded!"
    fi
  fi
  return $RETVAL
};

function MODPROBE_LOOP()
{
  declare -i RETVAL=$FAILURE
  declare -i TEST_RETVAL=$FAILURE
  declare -i BOL_LOOP=$TRUE
  declare -i LOOP_COUNT=0
  declare -i MODULE_ARRAY_COUNT=${#MODULE_ARRAY[@]}
  declare -i MODULE_LOADED_COUNT=0
  declare -i INDEX=-1

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Total Modules In Array $MODULE_ARRAY_COUNT"; fi
  while [ $BOL_LOOP -eq $TRUE ]; do
    (( LOOP_COUNT++ ))
    MODULE_LOADED_COUNT=0
    for MODULE in ${MODULE_ARRAY[@]}; do
      ((INDEX++))
      export MODULE="$MODULE"
      export OPTION="${MODULE_OPTIONS_ARRAY[$((INDEX))]}"
      if [ $BOL_REMOVE -eq $FALSE ]; then
        TEST_MODULE
	TEST_RETVAL=$?
      else
	TEST_RETVAL=$FAILURE
      fi
      if [ $TEST_RETVAL -eq $FAILURE ]; then
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Attempting Module: $MODULE"; fi
	DO_MODPROBE
	RETVAL=$?
	if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
	if [ $RETVAL -eq $SUCCESS ]; then ((MODULE_LOADED_COUNT++)); fi
      else
	((MODULE_LOADED_COUNT++))
      fi
    done
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      echo -e "\nLoop Count $LOOP_COUNT\tLoop Limit $VAR_LIMIT"
      echo -e "Total Modules In Array $MODULE_ARRAY_COUNT"
      echo -e "Total Modules (Un)Loaded $MODULE_LOADED_COUNT\n"
    fi
    if [ $LOOP_COUNT -eq $VAR_LIMIT ]; then BOL_LOOP=$FALSE; fi
    if [ $MODULE_ARRAY_COUNT -eq $MODULE_LOADED_COUNT ]; then BOL_LOOP=$FALSE; fi
  done
  return $RETVAL
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$VERSION"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Mount Filesystems Not in /etc/fstab"
        printf "%-15s\t\t%-25s\n" "stop" "Unmount Filesystems Not in /etc/fstab"
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
	export MODPROBE_BIN="$TEST_BIN"
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        export VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
-l=* | --limit=*)
        X="${i#*=}"
        export VAR_START_LIMIT=$((X))
        ;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
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

GET_MODULE_ARRAY
if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	export BOL_REMOVE=$TRUE
	export REMOVE="-r"
        export VAR_LIMIT=$VAR_STOP_LIMIT
	MODPROBE_LOOP
	EXITVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	export BOL_REMOVE=$FALSE
	export REMOVE=""
	export VAR_LIMIT=$VAR_START_LIMIT
	MODPROBE_LOOP
	EXITVAL=$?
fi

if [ $EXITVAL -eq $SUCCESS ]; then
        log_success_msg "SUCCESS!"
else
        log_failure_msg "FAILURE!"
fi

## DONE!
exit $RETVAL

