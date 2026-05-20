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

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Integer Variables
declare -ig CMD_LINE_COUNT=$#
declare -ig RETVAL=$SUCCESS

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_COLOR=$TRUE
declare -ig BOL_TEST=$FALSE

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USR_PREFIX="/usr"
export RUN_PREFIX="/run"

export QEMU_BIN="$USR_PREFIX$BIN_PREFIX/qemu-system-arm"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export TAPUP_BIN="$SBIN_PREFIX/tapup"
export TAPDOWN_BIN="$SBIN_PREFIX/tapdown"
export TEST_BIN="$BIN_PREFIX/true"

# Define QEMU Specific String Variables
export PID_FILE="$RUN_PREFIX/OpenWRT.arm.pid"
export BOOT_PATH="/opt/boot/arm/openwrt"
export IMAGE_PATH="/opt/qemu/images"
export TAP_NAME="tap0"
export BR_NAME="br0"
export IP_ADDRESS="172.16.184.2"
export TCP_PORT="60199"
export RAM="128"
export VERBOSE=""



function CHECK_ROOT_USER()
{
  if [ $(id -u) -ne 0 ]; then
    echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: $VERSION"$COLOR_LT_GREEN"\nMust be ran as "$COLOR_LT_RED"root!\n"$COLOR_NORMAL
    exit $FAILURE
  fi
  return $SUCCESS
};


function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$IP_BIN $OPTS: Success!"
  else
    log_failure_msg "$IP_BIN $OPTS: Failure!"
  fi
  return $RETVAL
};

function INITIALIZE_COLOR()
{
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Enabling Colorized Text Output"; fi
	export COLOR_NORMAL="\033[0m"
	export COLOR_BLACK="\033[0;30m"
	export COLOR_RED="\033[0;31m"
	export COLOR_GREEN="\033[0;32m"
	export COLOR_ORANGE="\033[0;33m"
	export COLOR_BLUE="\033[0;34m"
	export COLOR_PURPLE="\033[0;35m"
	export COLOR_CYAN="\033[0;36m"
	export COLOR_LT_GRAY="\033[0;37m"
	export COLOR_DK_GRAY="\033[1;30m"
	export COLOR_LT_RED="\033[1;31m"
	export COLOR_LT_GREEN="\033[1;32m"
        export COLOR_YELLOW="\033[1;33m"
        export COLOR_LT_BLUE="\033[1;34m"
        export COLOR_LT_PURPLE="\033[1;35m"
        export COLOR_LT_CYAN="\033[1;36m"
        export COLOR_WHITE="\033[1;37m"
	return $SUCCESS
};

function CHECK_CMD_LINE()
{
  if [ $CMD_LINE_COUNT -eq 0 ]; then
    echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: $VERSION"$COLOR_LT_GREEN"\nUsage:"$COLOR_LT_BLUE" $RUN_CMD [options] --help\n"$COLOR_NORMAL
    exit $SUCCESS
  fi
  return $SUCCESS
};


function INITIALIZE_ARRAYS()
{
  declare -ag MACHINE_ARRAY=("-display" "none" "-daemonize" "-M" "virt" "-m" "$RAM");
  declare -ag NET_ARRAY=("-netdev" "tap,id=veth0,ifname=$TAP_NAME,script=no,downscript=no" "-device" "e1000,netdev=veth0,mac=aa:d2:28:65:ad:f6");
  declare -ag KERNEL_ARRAY=("-kernel" "$BOOT_PATH/openwrt-19.07.0-rc1-armvirt-32-zImage");
  declare -ag APPEND_ARRAY=("-append" "root=/dev/vda3 rootwait");
  declare -ag DRIVE_ARRAY=("-drive" "file=$IMAGE_PATH/openwrt.arm.disk.qcow2,format=qcow2,if=virtio");
  declare -ag SERIAL_ARRAY=("-serial" "tcp:$IP_ADDRESS:$TCP_PORT,server,nowait,nodelay");
  declare -ag PID_ARRAY=("-pidfile" "$PID_FILE");
  return $SUCCESS
};

function do_STOP()
{
  declare -i STOP_RETVAL=$SUCCESS
  if [ -f $PIF_FILE ]; then
    for DATA in $(cat $PID_FILE); do
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"Executing: "$COLOR_LT_BLUE"kill $DATA"$COLOR_NORMAL; fi
      kill $DATA
      STOP_RETVAL=$?
    done
  fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"Executing: "$COLOR_LT_BLUE"$TAPDOWN_BIN "$TAP_NAME" "--bridge=$BR_NAME" $VERBOSE"$COLOR_NORMAL; fi
  $TAPDOWN_BIN "$TAP_NAME" "--bridge=$BR_NAME" $VERBOSE
  return $STOP_RETVAL
};

function do_START()
{
  declare -i START_RETVAL=$SUCCESS
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"Executing: "$COLOR_LT_BLUE"$TAPUP_BIN $TAP_NAME --bridge=$BR_NAME $VERBOSE"$COLOR_NORMAL; fi
  $TAPUP_BIN "$TAP_NAME" "--bridge=$BR_NAME" $VERBOSE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"Executing: "$COLOR_LT_BLUE"$QEMU_BIN ${MACHINE_ARRAY[@]} ${NET_ARRAY[@]} ${KERNEL_ARRAY[@]} ${APPEND_ARRAY[@]} ${DRIVE_ARRAY[@]} ${SERIAL_ARRAY[@]} ${PID_ARRAY[@]}"$COLOR_NORMAL; fi
  $QEMU_BIN "${MACHINE_ARRAY[@]}" "${NET_ARRAY[@]}" "${KERNEL_ARRAY[@]}" "${APPEND_ARRAY[@]}" \
    "${DRIVE_ARRAY[@]}" "${SERIAL_ARRAY[@]}" "${PID_ARRAY[@]}"
  START_RETVAL=$?
  return $START_RETVAL
};

function do_HELP()
{
  echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_YELLOW"\tVersion: $VERSION"$COLOR_LT_BLUE"\nUsage: $RUN_CMD [options]\n"$COLOR_NORMAL
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--help" "Show This Help Section" "--debug" "Show Debug Information"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--verbose" "Output More Details" "--quiet" "Don't Output Anything"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--file=<name>" "File Name or Pattern" "--path=<path>" "Search Path <path>"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--test" "Enable Test Mode" "--copy-audio" "Copy, do not encode audio stream"
  echo -e "\n"
  exit $SUCCESS
};


for i in "$@"
do
case $i in
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
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	;;
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
*)
	QEMU_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
        QEMU_OPTIONS[$((QEMU_OPTION_COUNT))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INITIALIZE_COLOR; fi
CHECK_CMD_LINE

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi
CHECK_ROOT_USER
INITIALIZE_ARRAYS

if [ $BOL_STOP -eq $TRUE ]; then
  log_daemon_msg "Stopping $RUNCMD"
  do_STOP
  RETVAL=$SUCCESS
  LOG_RESULTS
fi

if [ $BOL_START -eq $TRUE ]; then
  log_daemon_msg "Starting $RUNCMD"
  do_START
  RETVAL=$SUCCESS
  LOG_RESULTS
fi

exit $RETVAL
