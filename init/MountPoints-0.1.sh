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
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

# Define String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"
export XL_BIN="$SBIN_PREFIX/xl"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export MOUNT_BIN="$BIN_PREFIX/mount"
export UMOUNT_BIN="$BIN_PREFIX/umount"
export VERBOSE=""

# Define Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_XEN=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig VAR_WAIT=1
declare -ig VAR_LIMIT=5
declare -ig RETVAL=$FAILURE

# Define BTRFS Mount Options
export BTRFS_MOUNT_OPTIONS="-o defaults,compress=lzo,autodefrag,clear_cache,inode_cache,space_cache"
export SUBVOL_OPTION="subvol"

declare -ag DEVICE_ARRAY=('/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.backup-domain.disk' '/dev/mapper/xen.backup-domain.disk');
declare -ag SUBVOL_ARRAY=('@xen' '@download' '@System.Configs' '@Disk.Images');
declare -ag MOUNT_ARRAY=('/opt/xen' '/opt/download' '/opt/bak' '/opt/DiskImages');

function DO_MOUNT()
{
  declare -i BOL_RETRY=$TRUE
  declare -i RETVAL=$FAILURE
  declare -i COUNT=-1
  while [ $BOL_RETRY -eq $TRUE ]; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT"; fi
    $MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT
    RETVAL=$?
    if [ $RETVAL -eq $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Success!\n"; fi
      BOL_RETRY=$FALSE
    else
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Retry Attempt: $COUNT\n"; fi
      BOL_RETRY=$TRUE
    fi
    if [ $COUNT -eq $VAR_LIMIT ]; then BOL_RETRY=$FALSE; fi
  done
  return $RETVAL
};

function do_START()
{
  declare -i RETVAL=$FAILURE
  declare -i INDEX=-1
  for TEMP_DATA in ${DEVICE_ARRAY[@]}; do
    ((INDEX++))
    export TEMP_SUBVOL=$SUBVOL_OPTION=${SUBVOL_ARRAY[$((INDEX))]}
    export TEMP_MOUNT=${MOUNT_ARRAY[$((INDEX))]}
    export TEMP_DEVICE=$TEMP_DATA
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Subvol: $TEMP_SUBVOL\nMount: $TEMP_MOUNT\nDevice: $TEMP_DEVICE\n"; fi
    DO_MOUNT
    RETVAL=$?
  done
  return $RETVAL
};

function do_STOP()
{
  declare -i RETVAL=$FAILURE
  for TEMP_MOUNT in ${MOUNT_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$UMOUNT_BIN $TEMP_MOUNT\n"; fi
    $UMOUNT_BIN $TEMP_MOUNT
    RETVAL=$?
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
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
	export XL_BIN="$BIN_PREFIX/false"
	;;
'-x' | '--with-xen')
	export BOL_XEN=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
        ;;
-l=* | --limit=*)
        X="${i#*=}"
        VAR_LIMIT=$((X))
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

if [ $BOL_XEN -eq $TRUE ]; then
  # Source function library for storing XEN info
  source /usr/local/src/xen-scripts.sh
  StoreXenArray
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	do_STOP
	RETVAL=$SUCCESS
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
	RETVAL=$SUCCESS
fi

if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

## DONE!
exit $RETVAL
