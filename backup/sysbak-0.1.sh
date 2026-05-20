#! /bin/bash
## VERY Simple Script to Backup System Files

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

function BACKUP()
{
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1
  for TARGET in ${BAK_TARGET_ARRAY[@]}; do
    ((INDEX++))
    echo -e "Executing:  $TAR_BIN --xz -cvf $TARGET -C ${BAK_SOURCE_PATH[$((INDEX))]} ${BAK_SOURCE_ARRAY[$((INDEX))]}"
    $TAR_BIN --xz -cvf $TARGET -C ${BAK_SOURCE_PATH[$((INDEX))]} ${BAK_SOURCE_ARRAY[$((INDEX))]}
    export RETVAL=$?
    export COMMAND="$TAR_BIN Return Value: $RETVAL"
    LOG_RESULTS; unset COMMAND
    $SLEEP_BIN 1
    echo -e "\n"
    UNMOUNT
    $SLEEP_BIN 1
    MOUNT
  done
  return $RETVAL
};

function PRINT_DETAILS()
{
  echo -e "\n"
  echo -e "qcow2 File:\t\t$QCOW_FILE"
  echo -e "Mount Point:\t\t$BAK_MOUNT"
  echo -e "DOW:\t\t\t$DOW"
  echo -e "NBD Dev:\t\t$NBD_DEV"
  echo -e "NBD Part:\t\t$NBD_PART"
  echo -e "BTRFS Opts:\t\t$BTRFS_OPTS"
  echo -e "Target Array:\t\t${BAK_TARGET_ARRAY[@]}"
  echo -e "Source Path Array:\t${BAK_SOURCE_PATH[@]}"
  echo -e "Source List Array:\t${BAK_SOURCE_ARRAY[@]}"
  echo -e "\n"
  return $SUCCESS
};

function DISCONNECT()
{
  echo -e "Executing: $QEMU_NBD_BIN --disconnect $NBD_DEV"
  $QEMU_NBD_BIN --disconnect $NBD_DEV
  export RETVAL=$?
  export COMMAND="$QEMU_NBD_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  $SLEEP_BIN 1
  return $RETVAL
};

function CONNECT()
{
  echo -e "Executing: $QEMU_NBD_BIN --format=qcow2 --connect=$NBD_DEV $QCOW_FILE"
  $QEMU_NBD_BIN --format=qcow2 --connect=$NBD_DEV "$QCOW_FILE"
  export RETVAL=$?
  export COMMAND="$QEMU_NBD_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  $SLEEP_BIN 1
  return $RETVAL
};

function UNMOUNT()
{
  echo -e "Executing: $UMOUNT_BIN $BAK_MOUNT"
  $UMOUNT_BIN $BAK_MOUNT
  export RETVAL=$?
  export COMMAND="$UMOUNT_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  $SLEEP_BIN 1
  return $RETVAL
};

function MOUNT()
{
  echo -e "Executing: $MOUNT_BIN -o $BTRFS_OPTS $NBD_PART $BAK_MOUNT"
  $MOUNT_BIN -o $BTRFS_OPTS $NBD_PART $BAK_MOUNT
  export RETVAL=$?
  export COMMAND="$MOUNT_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  $SLEEP_BIN 1
  return $RETVAL
};

# Function gets the next available NBD Device number
function GET_NBD()
{
  declare -i INDEX=0
  while [ $(ps -ax | grep -v grep | grep /dev/nbd$((INDEX)) | wc -l) -ne 0 ]; do ((INDEX++)); done
  echo -e "/dev/nbd$((INDEX))"
};

# Function creates QCOW2 disk image file
function MAKE_QCOW()
{
  declare -i RETVAL=$FAILURE
  echo -e "Executing: $QEMU_IMG_BIN create -f qcow2 $QCOW_FILE $QCOW_SIZE"
  $QEMU_IMG_BIN create -f qcow2 "$QCOW_FILE" $QCOW_SIZE
  export RETVAL=$?
  export COMMAND="$QEMU_IMG_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  echo -e "\n"
  if [ $RETVAL -ne $SUCCESS ]; then echo -e "Error creating $QCOW_FILE!"; exit $FAILURE;     			fi

  echo -e "Executing: $QEMU_NBD_BIN --format=qcow2 --connect=$NBD_DEV $QCOW_FILE"
  $QEMU_NBD_BIN --format=qcow2 --connect=$NBD_DEV "$QCOW_FILE"
  export RETVAL=$?
  export COMMAND="$QEMU_NBD_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  echo -e "\n"
  if [ $RETVAL -ne $SUCCESS ]; then echo -e "Error connecting $QCOW_FILE to $NBD_DEV"; exit $FAILURE;		fi
  return $RETVAL
};

# Function creates and formats partition as BTRFS
# And creates BTRFS Subvolumes
function MAKE_PART()
{
  declare -i RETVAL=$FAILURE
  echo -e "\nCreating Partition Table"
  $PARTED_BIN $NBD_DEV mklabel GPT 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$PARTED_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''

  echo -e "\nCreating Partition $NDB_PART"
  $PARTED_BIN $NBD_DEV mkpart backup 0% 100% 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$PARTED_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''

  echo -e "\nFormatting Partition $NBD_PART"
  mkfs.btrfs --label=backup $NBD_PART
  export RETVAL=$?
  export COMMAND="mkfs.btrfs Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''

  CURRENT_PATH=$(pwd)
  echo -e "Mounting $NBD_PART to create Subvolumes"
  $MOUNT_BIN $NBD_PART $BAK_MOUNT
  export RETVAL=$?
  export COMMAND="$MOUNT_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  echo -e "Creating Subvolumes"
  cd $BAK_MOUNT
  for X in Saturday Sunday Monday Tuesday Wednesday Thursday Friday; do
    echo -e "Executing: $BTRFS_BIN subvol create @$X"
    $BTRFS_BIN subvol create @$X
    export RETVAL=$?
    export COMMAND="$BTRFS_BIN Return Value: $RETVAL"
    LOG_RESULTS; unset COMMAND; echo -e ''
  done
  cd $CURRENT_PATH
  echo -e "Executing: $UMOUNT_BIN $BAK_MOUNT"
  $UMOUNT_BIN $BAK_MOUNT
  export RETVAL=$?
  export COMMAND="$UMOUNT_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  echo -e "Executing: $MOUNT_BIN -o $BTRFS_OPTS $NBD_PART $BAK_MOUNT"
  $MOUNT_BIN -o $BTRFS_OPTS $NBD_PART $BAK_MOUNT
  export RETVAL=$?
  export COMMAND="$MOUNT_BIN Return Value: $RETVAL"
  LOG_RESULTS; unset COMMAND; echo -e ''
  return $RETVAL
};

# Check for command line arguments
for OPTIONS in $@; do
  case $OPTIONS in
    --hostname=*)	export NETBIOS_HOSTNAME="${OPTIONS#*=}";;
    --fqdn-hostname=*)	export FQDN_HOSTNAME="${OPTIONS#*=}";;
    --kernel=*)		export KERNEL="${OPTIONS#*=}";;
    --bak-ext=*)	export BAK_EXT="${OPTIONS#*=}";;
    --qcow-ext=*)	export QCOW_EXT="${OPTIONS#*=}";;
    --bak-mount=*)	export BAK_MOUNT="${OPTIONS#*=}";;
    --nfs-server=*)	export NFS_SERVER="${OPTIONS#*=}";;
    --nfs-share=*)	export NFS_SHARE="${OPTIONS#*=}";;
    --qcow-img=*)	export QCOW_IMG="${OPTIONS#*=}";;
    --qcow-file=*)	export QCOW_FILE="${OPTIONS#*=}";;
    --qcow-size=*)	export QCOW_SIZE="${OPTIONS#*=}";;
    --dow=*)		export DOW="${OPTIONS#*=}";;
    --btrfs-opts=*)	export BTRFS_OPTS="${OPTIONS#*=}";;
    --nbd-dev=*)	export NBD_DEV="${OPTIONS#*=}";;
    --nbd-part=*)	export NBD_PART="${OPTIONS#*=}";;
    --debug)		export BOL_DEBUG=$TRUE;;
    --verbose)		export BOL_VERBOSE=$TRUE;;
  esac
done

# Define Variables that are not already defined
# Either as environment variables or set by command line options defined above
if [ ${#NETBIOS_HOSTNAME}		-eq 0 ]; then export NETBIOS_HOSTNAME=$($HOSTNAME_BIN --short);								fi
if [ ${#FQDN_HOSTNAME}			-eq 0 ]; then export FQDN_HOSTNAME=$($HOSTNAME_BIN --fqdn);								fi
if [ ${#KERNEL}				-eq 0 ]; then export KERNEL=$(uname -r);										fi
if [ ${#BAK_EXT}			-eq 0 ]; then export BAK_EXT="bak.tar.xz";										fi
if [ ${#QCOW_EXT}			-eq 0 ]; then export QCOW_EXT="bak.qcow2";										fi
if [ ${#BAK_MOUNT}			-eq 0 ]; then export BAK_MOUNT="/mnt/bak";										fi
if [ ${#NFS_SERVER}			-eq 0 ]; then export NFS_SERVER="lxc.gigaware.lan";									fi
if [ ${#NFS_SHARE}			-eq 0 ]; then export NFS_SHARE="/nfs/$NFS_SERVER/opt/bak/$NETBIOS_HOSTNAME";						fi
if [ ${#QCOW_IMG}			-eq 0 ]; then export QCOW_IMG="$FQDN_HOSTNAME.$QCOW_EXT";								fi
if [ ${#QCOW_FILE}			-eq 0 ]; then export QCOW_FILE="$NFS_SHARE/$QCOW_IMG";									fi
if [ ${#QCOW_SIZE}			-eq 0 ]; then export QCOW_SIZE="2G";											fi
if [ ${#DOW}				-eq 0 ]; then export DOW=$(date +%A);											fi
if [ ${#BTRFS_OPTS}             	-eq 0 ]; then export BTRFS_OPTS="compress=zstd,ssd,sync,commit=5,subvol=@$DOW";						fi
if [ $(lsmod|grep nbd|wc -l)		-eq 0 ]; then modprobe nbd;												fi
if [ ${#NBD_DEV}			-eq 0 ]; then export NBD_DEV=$(GET_NBD);										fi
if [ ${#NBD_PART}			-eq 0 ]; then export NBD_PART="$NBD_DEV""p1";										fi
if [ ! -d $BAK_MOUNT			      ]; then mkdir -p $BAK_MOUNT;											fi
if [   -f $QCOW_FILE                          ]; then echo -e "Found $QCOW_FILE! Attempting to use it";								fi
if [   -f $QCOW_FILE			      ]; then CONNECT;													fi
if [ ! -f $QCOW_FILE			      ]; then echo -e "$QCOW_FILE doesn't exist, creating it"; MAKE_QCOW;						fi
if [   -b $NBD_PART			      ]; then MOUNT;													fi
if [ ! -b $NBD_PART			      ]; then echo -e "$NBD_PART doesn't exist, creating it"; MAKE_PART;						fi
if [ $(mount|grep $BAK_MOUNT|wc -l)	-ne 1 ]; then echo -e "$BAK_MOUNT not mounted!"; exit $FAILURE;								fi
if [ ${#BAK_TARGET_ARRAY[@]}		-eq 0 ]; then declare -ag BAK_TARGET_ARRAY=( "$BAK_MOUNT/boot.$KERNEL.$BAK_EXT" "$BAK_MOUNT/etc.$BAK_EXT" "$BAK_MOUNT/lib.modules.$KERNEL.$BAK_EXT" "$BAK_MOUNT/lib.systemd.$BAK_EXT" "$BAK_MOUNT/usr.local.$BAK_EXT" );		fi
if [ ${#BAK_SOURCE_PATH[@]}		-eq 0 ]; then declare -ag BAK_SOURCE_PATH=( "/boot" "/etc" "/lib/modules/$KERNEL" "/lib/systemd" "/usr/local" );	fi
if [ ${#BAK_SOURCE_ARRAY[@]}		-eq 0 ]; then declare -ag BAK_SOURCE_ARRAY=( "efi extlinux flask grub grub2 init*-$KERNEL.img loader System.map-$KERNEL config-$KERNEL vmlinuz-$KERNEL xen*" '.' '.' '.' "bin etc include lib lib64 libexec samba scripts sbin" );	fi
if [ $BOL_DEBUG 		    -eq $TRUE ]; then PRINT_DETAILS;												fi

# Call Backup Function
BACKUP

# Call unmount Function
UNMOUNT

# Call disconnect Function
DISCONNECT

# All Done
exit $RETVAL