#! /bin/bash
### By: Peter Talbott 2019-06-01
### Updated 2019-11-23, 11-25
### Added In NBD Support
### Bug Fixes
###  1) Corrected Missing Firts Mount Point

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.3"

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
declare -ig BOL_BTRFS=$TRUE
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
export VM_WWW="$CONTAINER_PREFIX/www.gigaware.lan"
export VM_SQL="$CONTAINER_PREFIX/sql.gigaware.lan"
export VM_UBS="$CONTAINER_PREFIX/ubuntuserver.gigaware.lan"

# Define NBD Array
declare -ag NBD_ARRAY=("/dev/nbd0" "/dev/nbd1" "/dev/nbd2" "/dev/nbd3" "/dev/nbd4" "/dev/nbd5" "/dev/nbd6" "/dev/nbd7" "/dev/nbd8" "/dev/nbd9" "/dev/nbd10");

# Define Global NBD Mount Points
declare -ag NBD_LVM_ARRAY=(	"$MAPPER/xen.host-www.disk" \
				"$MAPPER/xen.storage-apt.cache.disk" \
				"$MAPPER/xen.host-sql.disk" \
				"$MAPPER/xen.data-sql.data.disk" \
				"$MAPPER/xen.host-ubuntuserver.disk" \
				"$MAPPER/xen.storage-prod.disk" \
				"$MAPPER/xen.storage-usr.disk" \
				"$MAPPER/xen.storage-video.disk" \
				"$MAPPER/xen.storage-zoneminder.data" \
				"$MAPPER/xen.backup-user.data" \
				"$MAPPER/xen.backup-data.disk");

# Function To Store Arrays Data in Reverse
function REVERSE_ARRAYS()
{
  declare -ag REVERSE_DEVICE_ARRAY=();
  declare -ag REVERSE_SUBVOL_ARRAY=();
  declare -ag REVERSE_MOUNT_ARRAY=();
  declare -i i=0

  for (( i=${#DEVICE_ARRAY[@]}-1; i>=0; i-- )); do
    REVERSE_DEVICE_ARRAY[${#REVERSE_DEVICE_ARRAY[@]}]=${DEVICE_ARRAY[i]}
  done

  for (( i=${#SUBVOL_ARRAY[@]}-1; i>=0; i-- )); do
    REVERSE_SUBVOL_ARRAY[${#REVERSE_SUBVOL_ARRAY[@]}]=${SUBVOL_ARRAY[i]}
  done

  for (( i=${#MOUNT_ARRAY[@]}-1; i>=0; i-- )); do
    REVERSE_MOUNT_ARRAY[${#REVERSE_MOUNT_ARRAY[@]}]=${MOUNT_ARRAY[i]}
  done

  return $i
};

function INIT_MOUNT_POINTS()
{
  export BOL_BTRFS=$TRUE

  # Define Global Default Mount Points
  declare -ag DEVICE_ARRAY=('/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.data-xen.disk' '/dev/mapper/xen.backup-domain.disk' '/dev/mapper/xen.backup-domain.disk');
  declare -ag SUBVOL_ARRAY=('@xen' '@download' '@System.Configs' '@Disk.Images');
  declare -ag MOUNT_ARRAY=('/opt/xen' '/opt/download' '/opt/bak' '/opt/DiskImages');

  REVERSE_ARRAYS
  return $SUCCESS
};

function INIT_EXT_MOUNT_POINTS()
{
  export BOL_BTRFS=$FALSE

  declare -ag DEVICE_ARRAY=(	"$MAPPER/xen.storage-prod.disk" \
				"$MAPPER/xen.storage-usr.disk" \
				"$MAPPER/xen.storage-video.disk" \
				"$MAPPER/zm.guest-data.disk" \
				"UUID=68e71f8c-2426-41db-84b7-d7304e5ba2df" \
				"UUID=79a02db7-8dbf-4581-b22a-f266f71966a1" \
				"UUID=f8f517e9-ffea-4259-9383-0ef7ff12343d");

  declare -ag MOUNT_ARRAY=(	"$VM_UBS/opt/prod" \
				"$VM_UBS/opt/usr" \
				"$VM_UBS/opt/video" \
				"$VM_UBS/opt/zm" \
				"$VM_WWW/boot" \
				"$VM_SQL/boot" \
				"$VM_UBS/boot");

  REVERSE_ARRAYS
  return $SUCCESS
};

function INIT_LVM_MOUNT_POINTS()
{
  export BOL_BTRFS=$TRUE

  declare -ag DEVICE_ARRAY=(	"/dev/mapper/www.guest-root.disk" \
				"/dev/mapper/www.cache-apt.disk" \
				"/dev/mapper/sql.guest-root.disk" \
				"/dev/mapper/sql.data-sql.data.disk" \
				"/dev/mapper/sql.data-sql.data.disk" \
    				"/dev/mapper/sql.data-sql.data.disk" \
				"/dev/mapper/sql.data-sql.data.disk" \
				"/dev/mapper/sql.data-sql.log.disk" \
				"/dev/mapper/ubuntuserver.guest-root.disk" \
				"/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
                                "/dev/mapper/data.backup-rar.bak" \
				"/dev/mapper/user.backup-home");

  declare -ag SUBVOL_ARRAY=(	'@' '@apt.cacher' \
				'@' '@mysql' '@keyring' '@files' '@upgrade' '@log' \
				'@' '@home.bak' '@iso.bak' '@movies.bak' '@mp3drive.bak' '@porn.bak' '@roms.bak' '@storage.bak' '@home.bak');

  declare -ag MOUNT_ARRAY=(	"$VM_WWW" "$VM_WWW/var/cache/apt-cacher-ng" \
				"$VM_SQL" "$VM_SQL/var/lib/mysql" "$VM_SQL/var/lib/mysql-keyring" "$VM_SQL/var/lib/mysql-files" "$VM_SQL/var/lib/mysql-upgrade" "$VM_SQL/var/log/mysql" \
				"$VM_UBS" "$VM_UBS/opt/data.bak/home.bak" "$VM_UBS/opt/data.bak/iso.bak" "$VM_UBS/opt/data.bak/movies.bak" "$VM_UBS/opt/data.bak/mp3drive.bak" "$VM_UBS/opt/data.bak/porn.bak" \
				"$VM_UBS/opt/data.bak/roms.bak" "$VM_UBS/opt/data.bak/storage.bak" "$VM_UBS/opt/home.bak");

  REVERSE_ARRAYS
  return $SUCCESS
};

# Initialize All Mount Point Arrays
INIT_MOUNT_POINTS

# Function Display Log Results
function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "Success!"
  else
        log_failure_msg "Failure!"
  fi
  return $RETVAL
};

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
};

# Create NBD Devices
function CREATE_NBD_DEVICES()
{
  declare -i index=-1

  for DEVICE in ${NBD_LVM_ARRAY[@]}; do
    ((index++))
    NBD_DEVICE="${NBD_ARRAY[$((index))]}"
    ps -ax | grep -v grep | grep $NBD_DEVICE >/dev/null
    if [ $? -ne $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$NBD_BIN $CONNECT_OPTION $NBD_DEVICE $DEVICE $FORMAT_OPTION"; fi
      $NBD_BIN $CONNECT_OPTION $NBD_DEVICE $DEVICE $FORMAT_OPTION
      export RETVAL=$?
      if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$NBD_DEVICE Already In Use!"; fi
    fi
  done
  return $RETVAL
};

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
    if [ $BOL_BTRFS -eq $TRUE ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT"; fi
      $MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT
      export RETVAL=$?
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$MOUNT_BIN $TEMP_DEVICE $TEMP_MOUNT"; fi
      $MOUNT_BIN $TEMP_DEVICE $TEMP_MOUNT
      export RETVAL=$?
    fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    if [ $RETVAL -eq $SUCCESS ]; then
      BOL_RETRY=$FALSE
    else
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Retry Attempt: $COUNT of $VAR_LIMIT\n"; fi
      BOL_RETRY=$TRUE
    fi
    if [ $COUNT -eq $VAR_LIMIT ]; then BOL_RETRY=$FALSE; fi
  done
  return $RETVAL
};

function MOUNT_LOOP()
{
  declare -i RETVAL=$FAILURE
  declare -i INDEX=-1
  for TEMP_DATA in ${DEVICE_ARRAY[@]}; do
    ((INDEX++))
    export TEMP_SUBVOL="$SUBVOL_OPTION=${SUBVOL_ARRAY[$((INDEX))]}"
    export TEMP_MOUNT="${MOUNT_ARRAY[$((INDEX))]}"
    export TEMP_DEVICE=$TEMP_DATA
    $MOUNT_BIN | grep "$TEMP_MOUNT " >/dev/null
    if [ $? -ne $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Subvol: $TEMP_SUBVOL\nMount: $TEMP_MOUNT\nDevice: $TEMP_DEVICE\n"; fi
      DO_MOUNT
      RETVAL=$?
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Skipping\nSubvol: $TEMP_SUBVOL\nMount: $TEMP_MOUNT\nDevice: $TEMP_DEVICE\nAlready Mounted!\n"; fi
    fi
  done
  return $RETVAL
};

function CHECK_MOUNT()
{
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Checking Mount Points:\n${MOUNT_ARRAY[@]}"; fi
  for TEMP_DATA in ${REVERSE_DEVICE_ARRAY[@]}; do
    ((INDEX++))
    export TEMP_SUBVOL="$SUBVOL_OPTION=${REVERSE_SUBVOL_ARRAY[$((INDEX))]}"
    export TEMP_MOUNT="${REVERSE_MOUNT_ARRAY[$((INDEX))]}"
    export TEMP_DEVICE="$TEMP_DATA"
    $MOUNT_BIN | grep "$TEMP_MOUNT " >/dev/null
    if [ $? -ne $SUCCESS ]; then
      sleep 5
      if [ $BOL_BTRFS -eq $TRUE ]; then
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$TEMP_MOUNT NOT Mounted! Trying Again!\n$MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT"; fi
        $MOUNT_BIN $BTRFS_MOUNT_OPTIONS,$TEMP_SUBVOL $TEMP_DEVICE $TEMP_MOUNT
        export RETVAL=$?
      else
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$TEMP_MOUNT NOT Mounted! Trying Again!\n$MOUNT_BIN $TEMP_DEVICE $TEMP_MOUNT"; fi
        $MOUNT_BIN $TEMP_DEVICE $TEMP_MOUNT
        export RETVAL=$?
      fi
      if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    fi
  done
  return $RETVAL
};

function UNMOUNT_LOOP()
{
  declare -i RETVAL=$FAILURE

  for TEMP_MOUNT in ${REVERSE_MOUNT_ARRAY[@]}; do
    mount | grep "$TEMP_MOUNT " >/dev/null
    if [ $? -eq $SUCCESS ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$UMOUNT_BIN $TEMP_MOUNT\n"; fi
      $UMOUNT_BIN $TEMP_MOUNT
      RETVAL=$?
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$TEMP_MOUNT is NOT Mounted!"; fi
    fi
  done
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "\n"; fi
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

# If Help Is Parsed, Display Help and Exit
if [ $BOL_HELP -eq $TRUE ]; then
	do_HELP
        exit $SUCCESS
fi

# Exit if ANY Unknown Parameters are Parsed
if [ $VAR_UNKNOWN -gt 0 ]; then
	exit $VAR_UNKNOWN
fi

# Print Weather or Not XEN has been Detected
if [ $BOL_VERBOSE -eq $TRUE ]; then
  if [ $BOL_XEN -eq $TRUE ]; then
    echo -e "BOOLEAN XEN = TRUE"
  else
    echo -e "BOOLEAN XEN = FALSE"
  fi
fi

# IF XEN Hypervisor IS Detected, Load XEN Scripts
if [ $BOL_XEN -eq $TRUE ]; then
  # Source function library for storing XEN info
  source /usr/local/src/xen-scripts.sh
  StoreXenArray
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
	INIT_MOUNT_POINTS
	UNMOUNT_LOOP
	export RETVAL=$?
	if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	if [ $BOL_XEN -eq $FALSE ]; then
	    INIT_EXT_MOUNT_POINTS
            UNMOUNT_LOOP
            export RETVAL=$?
            if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	    INIT_LVM_MOUNT_POINTS
	    UNMOUNT_LOOP
	    export RETVAL=$?
	    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	    DESTROY_NBD_DEVICES
	    export RETVAL=$?
	    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	fi
	RETVAL=$SUCCESS
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	INIT_MOUNT_POINTS
	MOUNT_LOOP
	if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	if [ $BOL_XEN -eq $FALSE ]; then
	    CREATE_NBD_DEVICES		# Create NBD Devices From Guest LVMs
	    export RETVAL=$?
	    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	    INIT_LVM_MOUNT_POINTS	# Re-Define Global Default Mount Points
	    MOUNT_LOOP			# Re-Run Mount Loop With Guest LVM Mount Points
	    export RETVAL=$?
	    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	    INIT_EXT_MOUNT_POINTS
	    MOUNT_LOOP
	    export RETVAL=$?
	    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
	fi
	INIT_MOUNT_POINTS
	CHECK_MOUNT
	RETVAL=$?
fi

LOG_RESULTS
## DONE!
exit $RETVAL
