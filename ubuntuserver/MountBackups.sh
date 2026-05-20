#!/bin/bash
# Simple script to mount the backup device subvolumes
# Peter Talbott

# Define Initial Variables
export VERSION="0.1"
declare -ag CMDLINE=();
declare -i INDEX=-1

for TEMP in $@; do
  ((INDEX++))
  CMDLINE[$((INDEX))]="$TEMP"
done
declare -ig CMD_LINE_COUNT=$((INDEX+1))

unset INDEX
unset TEMP

# Define Script Specific Variables
export MOUNT_PATH="/opt/data.bak"
export LOG_PATH="/var/log"
export LOG_FILE="$LOG_PATH/mount.data.bak.log"
export COMPRESSION="zlib"
export DISK_UUID="57026956-b97c-4ce8-abc5-94d3b1d3ea49"

declare -i WAIT_TIME=30
declare -ag SUBVOL_ARRAY=("home.bak" "keys" "mp3drive" \
		"porn" "storage" "iso" "movies.bak" "roms");

declare -ag HELP_ARRAY=("start" "mount backup device\n" \
 "stop" "unmount backup device\n" "restart" "unmount then remount backup device\n" \
 "--verbose" "Verbose terminal output\n" "--version" "Display version information\n" \
 "--bw" "Black and White text");

# Function to clear all variables
function UNSET_VARIABLES()
{
  unset MOUNT_PATH
  unset LOG_PATH
  unset LOG_FILE
  unset COMPRESSION
  unset DISK_UUID
  unset DISK_DEVICE
  unset WAIT_TIME
  unset SUBVOL_ARRAY
  unset COMMAND
  return 0
};

# Function to load source script file
function SOURCE_INCLUDE_FILE()
{
  if [ -f $INCLUDE_FILE ]; then
    . $INCLUDE_FILE
  else
    echo -e "Error: $INCLUDE_FILE Not found!" | tee "$LOG_FILE"
    UNSET_VARIABLES
    exit 1
  fi
  return $SUCCESS
};

export INCLUDE_FILE="/usr/local/scripts/include/comdef.sh"
SOURCE_INCLUDE_FILE

export INCLUDE_FILE="/lib/lsb/init-functions"
SOURCE_INCLUDE_FILE

unset INCLUDE_FILE
export DISK_DEVICE="$($BLKID_BIN --uuid $DISK_UUID)"

# Make sure that root user is executing this script
REQUIRE_ROOT_USER | tee "$LOG_FILE"

function MOUNT_BAKUPS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  export COMMAND=$MOUNT_BIN
  for DATA in ${SUBVOL_ARRAY[@]}; do
    BTRFS_SUBVOL="@$DATA"
    MOUNT_POINT="$MOUNT_PATH/$DATA"
    MOUNT_OPTIONS="-o compress=$COMPRESSION,subvol=$BTRFS_SUBVOL"
    $COMMAND $MOUNT_OPTIONS $DISK_DEVICE $MOUNT_POINT 2>/dev/null
    FUNCTION_RETURN=$?
    echo -e "$(date) $COMMAND $MOUNT_OPTIONS $DISK_DEVICE $MOUNT_POINT\nReturned: $FUNCTION_RETURN" >>"$LOG_FILE"
  done
  return $FUNCTION_RETURN
};

function MAKE_MOUNT_POINT()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  export COMMAND=$MKDIR_BIN
  for DATA in ${SUBVOL_ARRAY[@]}; do
    MOUNT_POINT="$MOUNT_PATH/$DATA"
    if [ ! -d $MOUNT_POINT ]; then
      $COMMAND -p $MOUNT_POINT 2>/dev/null
      FUNCTION_RETURN=$?
      echo -e "$(date) $COMMAND -p $MOUNT_POINT\nReturned: $FUNCTION_RETURN" >>"$LOG_FILE"
    fi
  done
  return $FUNCTION_RETURN
};

function REMOVE_MOUNT_POINT()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  export COMMAND=$RMDIR_BIN
  for DATA in ${SUBVOL_ARRAY[@]}; do
    MOUNT_POINT="$MOUNT_PATH/$DATA"
    if [ -d $MOUNT_POINT ]; then
      $COMMAND $MOUNT_POINT 2>/dev/null
      FUNCTION_RETURN=$?
      echo -e "$(date) $COMMAND $MOUNT_POINT\nReturned: $FUNCTION_RETURN" >>"$LOG_FILE"
    fi
  done
  return $FUNCTION_RETURN
};

function UNMOUNT_DEVICE()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  export COMMAND=$UMOUNT_BIN
  for DATA in ${SUBVOL_ARRAY[@]}; do
    MOUNT_POINT="$MOUNT_PATH/$DATA"
    $COMMAND $MOUNT_POINT 2>/dev/null
    FUNCTION_RETURN=$?
    echo -e "$(date) $COMMAND $MOUNT_POINT\nReturned: $FUNCTION_RETURN" >>"$LOG_FILE"
  done
  return $FUNCTION_RETURN
};

STANDARD_CMD_LINE_OPTIONS
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi

REQUIRE_ROOT_USER
CHECK_CMD_LINE

if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

if [ $BOL_STOP -eq $TRUE ]; then
  log_daemon_msg "Stopping $RUN_CMD " | tee -a "$LOG_FILE"
  UNMOUNT_DEVICE
  export RETVAL=$?
  REMOVE_MOUNT_POINT
  LOG_RESULTS | tee -a "$LOG_FILE"
  echo -e "\n" >>"$LOG_FILE"
fi

if [ $BOL_START -eq $TRUE ]; then
  log_daemon_msg "Starting $RUN_CMD " | tee -a "$LOG_FILE"
  MAKE_MOUNT_POINT
  MOUNT_BAKUPS
  export RETVAL=$?
  LOG_RESULTS | tee -a "$LOG_FILE"
  echo -e "\n" >>"$LOG_FILE"
fi

UNSET_VARIABLES
exit $RETVAL
