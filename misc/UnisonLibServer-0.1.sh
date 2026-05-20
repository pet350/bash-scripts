#! /bin/sh
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018

# Synchronize These Folders
FOLDER1=/opt/usr/lib
FOLDER2=/mnt/sync/Sync04/lib

# Define the Log Filename
DAY=$(date +%A)
LOGFILE=/var/log/unison/lib.$DAY.log
echo Start of Log: >$LOGFILE

# Define Local Host Name
UNISONLOCALHOSTNAME=UbuntuLaptop.local

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
