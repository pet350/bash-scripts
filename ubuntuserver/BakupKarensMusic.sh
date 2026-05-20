#!/bin/bash
# Simple Backup Scrpt to Backup Karen's Music Nightly
# Peter Talbott

# Define Initial Variables
export VERSION="0.1"
export CMDLINE=$@
export BACKUP_PATH="/opt/data.bak/home.bak"
export LOG_FILE="$BACKUP_PATH/$(date +%w)-Karens_music.log"
export BACKUP_FILE="$BACKUP_PATH/$(date +%w)-Karens_music.tar.gz"
export BACKUP_SOURCE="/home/karen/Karens music"
export BACKUP_OPTIONS="-zcvf"
export CHDIR_OPTION="-C"
export CURRENT_DIR="."
export TEST_TAR=$(pgrep tar)
declare -i WAIT_TIME=30

# Function to clear all variables
function UNSET_VARIABLES()
{
  unset TEST_TAR
  unset WAIT_TIME
  unset LOG_FILE
  unset BACKUP_FILE
  unset BACKUP_SOURCE
  unset BACKUP_OPTIONS
  unset CHDIR_OPTION
  unset CURRENT_DIR
  unset COMMAND
  return 0
};

# Function to load source script file
function SOURCE_INCLUDE_FILE()
{
  if [ -f $INCLUDE_FILE ]; then
    . $INCLUDE_FILE
  else
    echo -e "Error: $INCLUDE_FILE Not found!" | tee "$LOG_FILE" >/dev/stdout
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
export COMMAND=$TAR_BIN

# Make sure that root user is executing this script
REQUIRE_ROOT_USER | tee "$LOG_FILE" >/dev/stdout

# Only reason for backup path not to exist is backup is not mounted
if [ ! -d $BACKUP_PATH ]; then
  echo -e "Error: $BACKUP_PATH Does not exist!"
  UNSET_VARIABLES
  exit $FAILURE
fi

# Clear log file
echo -e "" >$LOG_FILE

# make sure tar is not running, and wait it if is
while [ ${#TEST_TAR} -ne 0 ]; do
  echo -e "$COMMAND Currently Running! Waiting $WAIT_TIME Seconds for PID $TEST_TAR to end." | tee -a "$LOG_FILE" >/dev/stdout
  $SLEEP_BIN $WAIT_TIME
  TEST_TAR=$(pgrep tar)
done

echo -e "Backup Starting at $(date +%T) on $(date +%D)" | tee -a "$LOG_FILE" >/dev/stdout
echo -e "Executing: $COMMAND" "$BACKUP_OPTIONS" "$BACKUP_FILE" "$CHDIR_OPTION" "$BACKUP_SOURCE" "$CURRENT_DIR" | tee -a "$LOG_FILE" >/dev/stdout

# Run backup job!
$COMMAND "$BACKUP_OPTIONS" "$BACKUP_FILE" "$CHDIR_OPTION" "$BACKUP_SOURCE" "$CURRENT_DIR" | tee -a "$LOG_FILE" >/dev/stdout
export RETVAL=$?

LOG_RESULTS | tee -a "$LOG_FILE" >/dev/stdout
UNSET_VARIABLES

exit $RETVAL
