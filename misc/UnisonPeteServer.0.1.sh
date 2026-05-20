#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018

# Synchronize These Folders
FOLDER1=/home/pete
FOLDER2=/mnt/home/pete

# Define the Log Filename
_DOW=$(date +%A)		# Define _DOW:		(Day Of Week ie: Saturday, Sunday, Monday,... Etc..)
_FULL_DATE=$(date +%F)		# Define _FULL_DATE:	(Full Date; same as %Y-%m-%d)
_SHORT_DATE=$(date +%D)		# Define _SHORT_DATE:	(Short Date; same as %m/%d/%y)
_YEAR=$(date +%Y)		# Define _YEAR:		(4 Digit Format: 2017, 2018, 2019,... etc...)
_MONTH_LONG=$(date +%B)		# Define _MONTH_LONG:	(Janyary, February, March,... etc...)
_MONTH_SHORT=$(date +%b)	# Define _MONTH_SHORT:	(Jan, Feb, Mar,... etc...)
_MONTH=$(date +%m)		# Define _MONTH:	(01, 02, 03, ... 12, etc...)
_DAY=$(date +%d)		# Define _DAY:		(02, 01, 03, ... 30, etc...)
_TZ=$(date +%Z)			# Define _TZ:		(Time Zone Abbreviation (e.g., EDT)

LOGFILE=/var/log/unison/pete.$DAY.log
echo Start of Log: >$LOGFILE

# Define Local Host Name
UNISONLOCALHOSTNAME=UbuntuLaptop.local

# Define Options
OPTIONS="-auto -batch -times -rsync -killserver"

# Remove ANY ' (copy: *' Files that Have Been Created
find $FOLDER1 -name '*(copy:*' -type f -exec rm -v '{}'  \;

# Run Unison With The PreDefined Variables Above
unison $FOLDER1 $FOLDER2 $OPTIONS -prefer $FOLDER1 -nodeletion $FOLDER1 -ignore 'Name .*' -ignore 'Name *.default*' -ignore 'Name Schedules*' -ignorenot 'Name .thunderbird/*' -logfile $LOGFILE

# Remove ANY ' (copy: *' Files that Have Been Created
find $FOLDER1 -name '*(copy:*' -type f -exec rm -v '{}'  \;

# Set  Current Time and Date to both Folders
touch $FOLDER1
touch $FOLDER2

# The End
