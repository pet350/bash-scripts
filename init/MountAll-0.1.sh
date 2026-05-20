#! /bin/bash
### By: Peter Talbott 2020-08-23

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh) $XEN_FUNCTIONS; do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

# Define global boolean variables that are not already defined
if [ ${#BOL_REQ}		-eq 0 ]; then declare -ig BOL_REQ=$FALSE;		fi
if [ ${#BOL_CHECK_SWAP}		-eq 0 ]; then declare -ig BOL_CHECK_SWAP=$FALSE;	fi
if [ ${#BOL_CHECK_MOUNT}	-eq 0 ]; then declare -ig BOL_CHECK_MOUNT=$FALSE;	fi
if [ ${#BOL_SETUP_RAPID_DISK}	-eq 0 ]; then declare -ig BOL_SETUP_RAPID_DISK=$FALSE;	fi
if [ ${#BOL_RESTART}		-eq 0 ]; then declare -ig BOL_RESTART=$FALSE;		fi
if [ ${#BOL_WAIT}		-eq 0 ]; then declare -ig BOL_WAIT=$TRUE;		fi

# Define gloval integer variables
if [ ${#RAPID_DISK_SIZE}	-eq 0 ]; then declare -ig RAPID_DISK_SIZE=128;		fi
if [ ${#VAR_WAIT}		-eq 0 ]; then declare -ig VAR_WAIT=1;			fi

# Define global arrays
declare -ag DEVICE_NAME_ARRAY=( "boot" "build" "qemu" "temp" );

# Function to store BTRFS arrays
function STORE_BTRFS_NAME_ARRAY()
{
  declare -ag BTRFS_NAME_ARRAY=( "mount" "home.disk" "subvol" "@home" "point" "/home" "mount" "xen.disk" "subvol" "@xen" "point" "/opt/xen" \
				 "mount" "xen.disk" "subvol" "@download" "point" "/opt/download" "mount" "host.backup" "subvol" "@System.Configs" \
				 "point" "/opt/bak" "mount" "host.backup" "subvol" "@Disk.Images" "point" "/opt/images" );
  return $SUCCESS
};

# Define global string variables
export SWAP_LABEL="swap.disk"
export BTRFS_OPT="-o compress=zlib,subvol="

# Function to get the total swap space
function GET_SWAP_SPACE()
{
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $LINE_INDEX -eq 2 ] && [ $WORD_INDEX -eq 1 ]; then
        echo -e "${WORD:0:1}"
      fi
    done
  done < <($FREE_BIN -h)
  return $SUCCESS
};

function CHECK_SWAP()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i SWAP_SPACE=$(GET_SWAP_SPACE)
  export COMMAND="$SWAPON_BIN"

  if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"Starting CHECK_SWAP function"$CN; fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Info]\t\t"$CY"Swap space: $SWAP_SPACE"$CN; fi
  if [ $SWAP_SPACE -eq 0 ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$SWAPON_BIN $(blkid --label $SWAP_LABEL)"$CN; fi
    $SWAPON_BIN $(blkid --label $SWAP_LABEL)
    export RETVAL=$?
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
    FUNCTION_RETURN=$RETVAL
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Info]\t\t"$CY"Swap space already running, nothing to do."$CN; fi
  fi
  return $FUNCTION_RETURN
};

# Function will mount devices
function DO_MOUNT()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i DEVICE_NAME_ARRY_COUNT=${#DEVICE_NAME_ARRAY[@]}
  declare -i DEVICE_NAME_ARRAY_INDEX=$((DEVICE_NAME_ARRY_COUNT-1))
  declare -i BTRFS_INDEX=-1
  declare -i INDEX=-1
  declare -i BOL_BTRFS=$FALSE
  declare -i MOUNT_STATUS=$SUCCESS

  GET_BTRFS_NAME
  for DATA in ${DEVICE_NAME_ARRAY[@]} $BTRFS_POINT; do
    ((INDEX++))
    DEVICE_LABEL="$DATA.disk"
    if [ $INDEX -eq 0 ]; then
      MOUNT_POINT="/$DATA"
      OPTIONS=""
    elif [ $INDEX -gt 0 ] && [ $INDEX -lt $DEVICE_NAME_ARRY_COUNT ]; then
      MOUNT_POINT="/opt/$DATA"
      OPTIONS=""
    else
      ((BTRFS_INDEX++))
      MOUNT_POINT="${BTRFS_POINT_ARRAY[$((BTRFS_INDEX))]}"
      DEVICE_LABEL="${BTRFS_NAME_ARRAY[$((BTRFS_INDEX))]}"
      OPTIONS="${BTRFS_SUB_ARRAY[$((BTRFS_INDEX))]}"
      BOL_BTRFS=$TRUE
    fi
    export COMMAND="$MOUNT_BIN"
    export MOUNT_STATUS=$(df -h | grep $MOUNT_POINT | wc -l)
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      SHOW_DATE_TIME; echo -e $CLB"[Info]\t\t"$CY"Mount Source: $($BLKID_BIN --label $DEVICE_LABEL)"$CN
      SHOW_DATE_TIME; echo -e $CLB"[Info]\t\t"$CY"Mount Target: $MOUNT_POINT"$CN
      SHOW_DATE_TIME; echo -e $CLB"[Info]\t\t"$CY"Mount Options: $OPTIONS"$CN"\n"
    fi
    if [ $BOL_DEBUG -eq $TRUE ]; then
      SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"Mount Status: $MOUNT_STATUS"$CN
      SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"Check Mount: $BOL_CHECK_MOUNT"$CN"\n"
    fi
    if [ $MOUNT_STATUS -eq 0 ] || [ $BOL_CHECK_MOUNT -eq $FALSE ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$MOUNT_BIN $OPTIONS $($BLKID_BIN --label $DEVICE_LABEL) $MOUNT_POINT"$CN; fi
      $MOUNT_BIN $OPTIONS $($BLKID_BIN --label $DEVICE_LABEL) $MOUNT_POINT >/dev/null 2>/dev/null 3>/dev/null
      export FUNCTION_RETURN=$?
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
      export RETVAL=$FUNCTION_RETURN
      if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
    fi
  done
  return $FUNCTION_RETURN
};

function DO_UNMOUNT()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i DEVICE_NAME_ARRY_COUNT=${#DEVICE_NAME_ARRAY[@]}
  declare -i DEVICE_NAME_ARRAY_INDEX=$((DEVICE_NAME_ARRY_COUNT-1))
  declare -i INDEX=-1
  declare -i BOL_BTRFS=$FALSE

  GET_BTRFS_NAME
  for DATA in ${DEVICE_NAME_ARRAY[@]} $BTRFS_POINT; do
    ((INDEX++))
    DEVICE_LABEL="$DATA.disk"
    if [ $INDEX -eq 0 ]; then
      MOUNT_POINT="/$DATA"
      OPTIONS=""
    elif [ $INDEX -gt 0 ] && [ $INDEX -lt $DEVICE_NAME_ARRY_COUNT ]; then
      MOUNT_POINT="/opt/$DATA"
      OPTIONS=""
    else
      BTRFS_INDEX=$((INDEX-DEVICE_NAME_ARRAY_COUNT))
      MOUNT_POINT="$DATA"
      DEVICE_LABEL="${BTRFS_NAME_ARRAY[$((BTRFS_INDEX))]}"
      OPTIONS="${BTRFS_SUB_ARRAY[$((BTRFS_INDEX))]}"
      BOL_BTRFS=$TRUE
    fi
    export COMMAND="$UMOUNT_BIN"
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$UMOUNT_BIN $MOUNT_POINT"$CN; fi
    $UMOUNT_BIN $MOUNT_POINT >/dev/null 2>/dev/null 3>/dev/null
    export FUNCTION_RETURN=$?
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    export RETVAL=$FUNCTION_RETURN
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
  done
  return $FUNCTION_RETURN
};

function GET_BTRFS_NAME()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i BOL_NAME=$FALSE
  declare -i BOL_POINT=$FALSE
  declare -i BOL_SUBVOL=$FALSE
  declare -i INDEX=-1
  declare -ag BTRFS_POINT_ARRAY=();
  declare -ag BTRFS_NAME_ARRAY=();
  declare -ag BTRFS_SUB_ARRAY=();

  unset BTRFS_NAME
  unset BTRFS_POINT
  unset BTRFS_SUB

  STORE_BTRFS_NAME_ARRAY
  if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"Starting GET_BTRFS_NAME function"$CN; fi
  for BTRFS_DATA in ${BTRFS_NAME_ARRAY[@]}; do
    if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BTRFS_DATA: $BTRFS_DATA"$CN; fi

    if [ $BOL_NAME -eq $TRUE ]; then
      ((INDEX++))
      export BTRFS_NAME="$BTRFS_NAME $BTRFS_DATA"
      if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BTRFS_NAME: $BTRFS_NAME"$CN; fi
      BTRFS_NAME_ARRAY[$((INDEX))]="$BTRFS_DATA"
      FUNCTION_RETURN=$SUCCESS
      BOL_NAME=$FALSE
    fi

    if [ $BOL_POINT -eq $TRUE ]; then
      export BTRFS_POINT="$BTRFS_POINT $BTRFS_DATA"
      if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BTRFS_POINT: $BTRFS_POINT"$CN; fi
      BTRFS_POINT_ARRAY[$((INDEX))]="$BTRFS_DATA"
      BOL_POINT=$FALSE
    fi

    if [ $BOL_SUBVOL -eq $TRUE ]; then
      export BTRFS_SUB="$BTRFS_SUB $BTRFS_DATA"
      if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BTRFS_SUB: $BTRFS_SUB"$CN; fi
      BTRFS_SUB_ARRAY[$((INDEX))]="$BTRFS_OPT$BTRFS_DATA"
      BOL_SUB=$FALSE
    fi

    case $BTRFS_DATA in
      'mount')
        BOL_NAME=$TRUE;		BOL_POINT=$FALSE;	BOL_SUBVOL=$FALSE
	;;
      'point')
        BOL_NAME=$FALSE;	BOL_POINT=$TRUE;	BOL_SUBVOL=$FALSE
        ;;
      'subvol')
        BOL_NAME=$FALSE;	BOL_POINT=$FALSE;	BOL_SUBVOL=$TRUE
	;;
      *)
        BOL_NAME=$FALSE;	BOL_POINT=$FALSE;	BOL_SUBVOL=$FALSE
        ;;
    esac
    if [ $BOL_DEBUG -eq $TRUE ]; then
      SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BOL_NAME:\t$BOL_NAME"$CN
      SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BOL_POINT:\t$BOL_POINT"$CN
      SHOW_DATE_TIME; echo -e $CLB"[Debug]\t\t"$CY"BOL_SUBVOL:\t$BOL_SUBVOL\n"$CN
    fi
  done
  return $FUNCTION_RETURN
};

function SETUP_RAPID_DISK()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i BOL_NAME=$FALSE
  declare -i INDEX=-1

  GET_BTRFS_NAME
  export COMMAND="$RAPIDDISK_BIN"
  # I've discoverd rapiddisk does not cache BTRFS partitions
  # So we're not going to include them here
  for DATA in ${DEVICE_NAME_ARRAY[@]}; do
    ((INDEX++))
    DEVICE_LABEL="$DATA.disk"
    RAPID_DISK_DEVICE="rd$((INDEX))"
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RAPIDDISK_BIN --attach $RAPID_DISK_SIZE"$CN; fi
    $RAPIDDISK_BIN --attach $RAPID_DISK_SIZE >/dev/null 2>/dev/null 3>/dev/null
    export RETVAL=$?
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    export FUNCTION_RETURN=$RETVAL
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS
      SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RAPIDDISK_BIN --cache-map $RAPID_DISK_DEVICE $($BLKID_BIN --label $DEVICE_LABEL) wa"$CN
    fi
    $RAPIDDISK_BIN --cache-map $RAPID_DISK_DEVICE $($BLKID_BIN --label $DEVICE_LABEL) wa >/dev/null 2>/dev/null 3>/dev/null
    export RETVAL=$?
    export FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
  done
  return $FUNCTION_RETURN
};
declare -ag HELP_ARRAY=( "-------------" "-----------------------------------------------------------------\n" \
        "Required" "Command Line Arguments.\n" "start" "Start $RUN_CMD\n" "stop" "Stop $RUN_CMD\n" "restart" "Restart $RUN_CMD\n" \
	"check" "Check all mounts, remount accordingly\n" "-------------" "-----------------------------------------------------------------\n" \
	"Optional" "Command Line Arguments.\n" "--help" "display this help message.\n" "--verbose" "display execution information.\n" \
	"--test" "run through all steps but do not execute them.\n" "--debug" "show debug information.\n" "--enable-rapiddisk" \
	"configure mounts with rapiddisk (cache)\n" "--check-swap" "check swap and enable accordingly.\n" "--version" "show version information.\n" \
	"--rapid-disk-size=XXX" "set cache size to XXX MB.\n" "--no-wait" "do not pause in between commands.\n" "--wait=XX" "pause XX seconds.\n" \
	"--bw" "force black & white text.\n" "--color" "enable (if supported) ANSI color text.\n" "--force-color" "Forse ANSI color output.\n" \
	"-------------" "-----------------------------------------------------------------" );

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
	export BOL_RESTART=$FALSE
	export BOL_CHECK_MOUNT=$FALSE
	export BOL_REQ=$TRUE
        ;;
'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	export BOL_RESTART=$FALSE
	export BOL_CHECK_MOUNT=$FALSE
	export BOL_REQ=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	export BOL_RESTART=$TRUE
	export BOL_CHECK_MOUNT=$FALSE
	export BOL_REQ=$TRUE
	;;
'check')
	export BOL_START=$TRUE
	export BOL_STOP=$FALSE
	export BOL_RESTART=$FALSE
	export BOL_CHECK_MOUNT=$TRUE
	export BOL_REQ=$TRUE
	export BOL_CHECK_SWAP=$TRUE
	;;
'-h' | '--help')
        export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_VERBOSE=$FALSE
        ;;
'-v' | '--verbose')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-t' | '--test')
        export BOL_TEST=$TRUE
        export MOUNT_BIN="$TRUE_BIN"
	export UMOUNT_BIN="$TRUE_BIN"
        export RAPIDDISK_BIN="$TRUE_BIN"
	export SWAPON_BIN="$TRUE_BIN"
        ;;
'--debug')
	export BOL_DEBUG=$TRUE
	;;
'--enable-rapiddisk')
	export BOL_SETUP_RAPID_DISK=$TRUE
	;;
'--check-swap')
	export BOL_CHECK_SWAP=$TRUE
	;;
'--version')
        SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
        exit $SUCCESS
        ;;
'--bw')
        export BOL_COLOR=$FALSE
        ;;
'--color')
        export BOL_COLOR=$TRUE
        ;;
'--force-color')
        export BOL_FORCE_COLOR=$TRUE
        export BOL_COLOR=$TRUE
        ;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
        export BOL_WAIT=$TRUE
        ;;
--rapid-disk-size=*)
        X="${i#*=}"
	RAPID_DISK_SIZE=$((X))
	;;
'--no-wait')
        export BOL_WAIT=$FALSE
        ;;
*)
        ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
        ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
        SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
        ;;
esac
done

if [ $BOL_CHECK_MOUNT -eq $TRUE ] || [ $BOL_RESTART -eq $TRUE ] || [ $BOL_STOP -eq $TRUE ]; then export BOL_SETUP_RAPID_DISK=$FALSE; fi
if [ $BOL_STOP -eq $TRUE ] && [ $BOL_RESTART -eq $FALSE ]; then export BOL_CHECK_SWAP=$FALSE; fi
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ] || [ $BOL_REQ -eq $FALSE ]; then DO_HELP; fi

REQUIRE_ROOT_USER

if [ $BOL_STOP -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RUN_CMD stop functions\n"$CN; fi
  DO_UNMOUNT
  export RETVAL=$?
  export COMMAND="$RUN_CMD: stop functions"
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
fi

if [ $BOL_SETUP_RAPID_DISK -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RUN_CMD setup rapiddisk functions\n"$CN; fi
  SETUP_RAPID_DISK
  export RETVAL=$?
  export COMMAND="$RUN_CMD: rapiddisk functions"
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY;LOG_RESULTS; printf "%b\n" $CN; fi
fi

if [ $BOL_CHECK_SWAP -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RUN_CMD check swap functions\n"$CN; fi
  CHECK_SWAP
  export RETVAL=$?
  export COMMAND="$RUN_CMD: check swap functions"
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
fi


if [ $BOL_START -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Executing]\t"$CY"$RUN_CMD start functions\n"$CN; fi
  DO_MOUNT
  export RETVAL=$?
  export COMMAND="$RUN_CMD: start functions"
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi
fi

export COMMAND="$RUN_CMD $@"
if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%b[Result]%b\t\t" $CLB $CY; LOG_RESULTS; printf "%b\n" $CN; fi

exit $RETVAL