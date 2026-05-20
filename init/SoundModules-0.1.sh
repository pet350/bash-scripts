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
    exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit $FAILURE
fi

# Define Prefix Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"

# Define Execuatable Binaries
export LSMOD_BIN="$BIN_PREFIX/lsmod"
export GREP_BIN="$BIN_PREFIX/grep"
export MODPROBE_BIN="$SBIN_PREFIX/modprobe"
export SLEEP_BIN="$BIN_PREFIX/sleep"

# Define String Variables
export VERBOSE=""
export REMOVE=""
export MODULE=""

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
declare -ag MODULE_ARRAY=( "slicoss" "osst" "oss_ich" "oss_imux" "oss_atiaudio" "oss_hdaudio" "osscore" \
	"snd_ac97_codec" "snd_intel8x0m" "snd_intel8x0" "snd_util_mem" "snd_emu10k1" "snd_rawmidi" \
	"snd_seq_device" "snd_i2c" "snd_hda_intel" );


function DO_MODPROBE()
{
  declare -i RETVAL=$FAILURE

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$MODPROBE_BIN $VERBOSE $REMOVE $MODULE"; fi
  $MODPROBE_BIN $VERBOSE $REMOVE $MODULE
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

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Total Modules In Array $MODULE_ARRAY_COUNT"; fi
  while [ $BOL_LOOP -eq $TRUE ]; do
    (( LOOP_COUNT++ ))
    MODULE_LOADED_COUNT=0
    for MODULE in ${MODULE_ARRAY[@]}; do
      export MODULE="$MODULE"
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
	export MODPROBE_BIN="$BIN_PREFIX/false"
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

