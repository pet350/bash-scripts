#! /bin/bash
### By: Peter Talbott 2019-06-01
### Updated 2019-11-23
### Added In NBD Support

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.2"

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

# Define String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"
export XL_BIN="$SBIN_PREFIX/xl"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export MOUNT_BIN="$BIN_PREFIX/mount"
export UMOUNT_BIN="$BIN_PREFIX/umount"
export NBD_BIN="/usr/bin/qemu-nbd"
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
declare -ig VAR_WAIT=3
declare -ig VAR_LIMIT=7
declare -ig RETVAL=$FAILURE

# Define BTRFS Mount Options
export BTRFS_MOUNT_OPTIONS="-o defaults,compress=lzo,autodefrag,clear_cache,inode_cache,space_cache"
export SUBVOL_OPTION="subvol"
export MAPPER="/dev/mapper"
export CONNECT_OPTION="--connect"
export DISCONNECT_OPTION="--disconnect"
export FORMAT_OPTION="--format=raw"
export CONTAINER_PREFIX="/usr/local/share/container"

# Define Global Default Mount Points
declare -ag DEVICE_ARRAY=('/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.backup-domain.disk' '/dev/mapper/xen.backup-domain.disk');
declare -ag SUBVOL_ARRAY=('@xen' '@download' '@System.Configs' '@Disk.Images');
declare -ag MOUNT_ARRAY=('/opt/xen' '/opt/download' '/opt/bak' '/opt/DiskImages');

# Define Global NBD Mount Points
declare -ag ALT_DEVICE_ARRAY=("$MAPPER/xen.host-www.disk" "$MAPPER/xen.storage-apt.cache.disk" \
	"$MAPPER/xen.host-sql.disk" "$MAPPER/xen.data-sql.data.disk" "$MAPPER/xen.host-ubuntuserver.disk" \
	"$MAPPER/xen.storage-prod.disk" "$MAPPER/xen.storage-usr.disk" "$MAPPER/xen.storage-video.disk" "$MAPPER/xen.storage-zoneminder.data" \
	"$MAPPER/xen.backup-user.data" "$MAPPER/xen.backup-data.disk");
declare -ag NBD_ARRAY=("/dev/nbd0" "/dev/nbd1" "/dev/nbd2" "/dev/nbd3" "/dev/nbd4" "/dev/nbd5" "/dev/nbd6" "/dev/nbd7" "/dev/nbd8" "/dev/nbd9" "/dev/nbd10");

# Function Display Log Results
function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "Success!"
  else
        log_failure_msg "Failure!"
  fi
  return $?
}

# Function To Remove All NBD Devices
function DESTROY_NBD_DEVICES()
{
  for NBD_DEVICE in ${NBD_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$NBD_BIN $DISCONNECT_OPTION $NBD_DEVICE"; fi
    $NBD_BIN $DISCONNECT_OPTION $NBD_DEVICE
    export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
  done
  return $RETVAL
}

# Create NBD Devices
function CREATE_NBD_DEVICES()
{
  declare -i index=-1

  for DEVICE in ${ALT_DEVICE_ARRAY[@]}; do
    ((index++))
    NBD_DEVICE="${NBD_ARRAY[$((index))]}"
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$NBD_BIN $CONNECT_OPTION $NBD_DEVICE $DEVICE $FORMAT_OPTION"; fi
    $NBD_BIN $CONNECT_OPTION $NBD_DEVICE $DEVICE $FORMAT_OPTION
    export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
  done
  return $RETVAL
}

# Test For XEN
$XL_BIN info 2>/dev/null
if [ $? -eq $SUCCESS ]; then
  export BOL_XEN=$TRUE
fi

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
'-ox'| '--without-xen')
	export BOL_XEN=$FALSE
	## Currently Script Checks for XEN. However This Will Override!
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

if [ $BOL_VERBOSE -eq $TRUE ]; then
  echo -e "BOOLEAN XEN = $BOL_XEN"
fi

if [ $BOL_XEN -eq $TRUE ]; then
  # Source function library for storing XEN info
  source /usr/local/src/xen-scripts.sh
  StoreXenArray
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	do_STOP
	if [ $BOL_XEN -eq $FALSE ]; then
	    DESTROY_NBD_DEVICES
	fi
	RETVAL=$SUCCESS
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
	if [ $BOL_XEN -eq $FALSE ]; then
	    CREATE_NBD_DEVICES
	    export VM_WWW="$CONTAINER_PREFIX/www.gigaware.lan"
	    export VM_SQL="$CONTAINER_PREFIX/sql.gigaware.lan"
	    # Re-Define Global Default Mount Points

	    declare -ag DEVICE_ARRAY=('/dev/mapper/www.group-root.disk' '/dev/mapper/sql.group-root.disk' '/dev/mapper/sql.data-sql.data.disk' '/dev/mapper/sql.data-sql.data.disk' \
		'/dev/mapper/sql.data-sql.data.disk' '/dev/mapper/sql.data-sql.data.disk' '/dev/mapper/sql.data-sql.log.disk');

	    declare -ag SUBVOL_ARRAY=('@' '@' '@mysql' '@keyring' '@files' '@upgrade' '@log');

	    declare -ag MOUNT_ARRAY=("$VM_WWW" "$VM_SQL" "$VM_SQL/var/lib/mysql" "$VM_SQL/var/lib/mysql-keyring" "$VM_SQL/var/lib/mysql-files" "$VM_SQL/var/lib/mysql-upgrade" \
		"$VM_SQL/var/log/mysql");
	    do_START
	fi
	RETVAL=$SUCCESS
fi

LOG_RESULTS
## DONE!
exit $RETVAL
