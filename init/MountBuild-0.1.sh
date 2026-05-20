#! /bin/bash
# By: Peter Talbott

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

export VERSION="0.1"
export MOUNT_DEVICE=$($BLKID_BIN -L build.disk)
export MOUNT_TARGET="/opt/build"
export DEV_NULL="/dev/null"

declare -i BOL_CHECK=$FALSE
declare -i VAR_WAIT=2
declare -ig CMD_LINE_COUNT=${#@}

declare -ag HELP_ARRAY=("start" "mount $MOUNT_DEVICE onto $MOUNT_TARGET\n" "stop" "unmount $MOUNT_TARGET\n" "restart" "unmount and then remount $MOUNT_TARGET\n" \
  "--verbose" "Verbose terminal output\n" "--debug" "Disply All Debug output\n" "--check" "Perform filesystem check before mounting\n" "--version" "Display version information\n" "--bw" "Black and White text");

function DO_START()
{
  if [ $BOL_CHECK -eq $TRUE ]; then
    if [ $BOL_DEBUG -eq $TRUE ]; then printf "%b%6s %b%s%b\n" $COLOR_LT_BLUE "[Debug]" $COLOR_YELLOW "$FSCK_XFS_BIN $MOUNT_DEVICE" $COLOR_NORMAL; fi
    $FSCK_XFS_BIN $MOUNT_DEVICE >$DEV_NULL 2>$DEV_NULL
    if [ $? -ne $SUCCESS ]; then
      exit $FAILURE
    fi
  fi
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then printf "%b%6s %b%s%b\n" $COLOR_LT_BLUE "[Debug]" $COLOR_YELLOW "$MOUNT_BIN $MOUNT_DEVICE $MOUNT_TARGET" $COLOR_NORMAL; fi
  $MOUNT_BIN $MOUNT_DEVICE $MOUNT_TARGET >$DEV_NULL 2>$DEV_NULL
  return $?
};

function DO_STOP()
{
  if [ $BOL_DEBUG -eq $TRUE ]; then printf "%b%6s %b%s%b\n" $COLOR_LT_BLUE "[Debug]" $COLOR_YELLOW "$UMOUNT_BIN $MOUNT_TARGET" $COLOR_NORMAL; fi
  $UMOUNT_BIN $MOUNT_TARGET >$DEV_NULL 2>$DEV_NULL
  return $?
};


for i in "$@"; do
case $i in
'--check')
	export BOL_CHECK=$TRUE
	;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	export BOL_START=$FALSE
	export BOL_STOP=$FALSE
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	export VERBOSE="--verbose"
	;;
'--debug')
	export DEV_NULL="/dev/stdout"
	export BOL_DEBUG=$TRUE
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
	SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
        SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
CHECK_CMD_LINE

if [ $BOL_STOP -eq $TRUE ]; then
  log_daemon_msg "Stopping $RUN_CMD "
  DO_STOP
  export RETVAL=$?
  LOG_RESULTS
fi

if [ $BOL_START -eq $TRUE ]; then
  log_daemon_msg "Starting $RUN_CMD "
  DO_START
  export RETVAL=$?
  LOG_RESULTS
fi

exit $RETVAL
