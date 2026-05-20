#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018; 04/10/2019

# Current Version
VERSION=0.1

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

# Define String Variables
export RUN_CMD="$(basename $0)"
export LOG_PREFIX="/var/log/unison"

# Make Sure That Only Root is Running this Script
if [ $(id -u) -gt 0 ]; then
  echo -e "Error: $RUN_CMD Version $VERSION\nMust be ran as ROOT user!"
  exit $FAILURE
fi

if [ ! -d $LOG_PREFIX ]; then mkdir -p $LOG_PREFIX; fi

# Synchronize These Folders
FOLDER1="/var/lib/mysql"
FOLDER2="/var/lib/mysql.local"

# Define the Log Filename
DOW=$(date +%w)
FULL_DATE=$(date +%F)
FULL_TIME=$(date +%r)
LOGFILE="/var/log/unison/$DOW-MySQL.log"
echo -e "[$FULL_DATE @ $FULL_TIME] Start of Log: " >>$LOGFILE

# Define Local Host Name
UNISONLOCALHOSTNAME="$(hostname -f)"

# Define Options
OPTIONS="-auto -batch -times -numericids -rsync -killserver"

# Remove ANY ' (copy: *' Files that Have Been Created
find $FOLDER1 -name '*(copy:*' -type f -exec rm -v '{}'  \;

# Run Unison With The PreDefined Variables Above
unison $FOLDER1 $FOLDER2 $OPTIONS -prefer $FOLDER1 -nodeletion $FOLDER1 -logfile $LOGFILE

# Remove ANY ' (copy: *' Files that Have Been Created
find $FOLDER1 -name '*(copy:*' -type f -exec rm -v '{}'  \;

# Set  Current Time and Date to both Folders
touch $FOLDER1
touch $FOLDER2

# The End
