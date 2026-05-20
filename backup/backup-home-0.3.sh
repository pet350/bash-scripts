#!/bin/bash
## VERRY Simple Script to Backup User Files

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


if [ $(id -u) -ne 0 ]; then
	echo "Must be ran as root!"
	exit 1
fi

export VERSION=0.3

# Define Global TRUE/FALSE and SUCCESS/FAILURE
declare -ig TRUE=1
declare -ig FALSE=0
declare -ig SUCCESS=0
declare -ig FAILURE=1

export DOW=$(date +%w)
export RUN_CMD="$(basename $0)"

export HOME_PREFIX="/opt/prod/home"
export BACKUP_PREFIX="/opt/home.bak"
export BACKUP_SUFFIX=".tar"
export COMPRESSED_SUFFIX=".tar.gz"

export NIGHTLY_MAX_FILE_SIZE="2M"

declare -ag USER_ARRAY=();
declare -ig RETVAL=$FAILURE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_WEEKLY=$FALSE
declare -ig BOL_NIGHTLY=$FALSE
declare -ig BOL_RUN=$TRUE
declare -ig BOL_HELP=$FALSE

# Work Around For Now:
# Daily Backup Takes Hours with ceratin user folders
# Disable the Daily Backup and Run the Weekly 3x a Week.
if [ $DOW -eq 6 ]; then BOL_WEEKLY=$TRUE; fi
if [ $DOW -eq 4 ]; then BOL_WEEKLY=$TRUE; fi
if [ $DOW -eq 2 ]; then BOL_WEEKLY=$TRUE; fi

# Function to populate USER_ARRAY
function storeUSERS()
{
  INDEX=-1
  for TEMP_USERS in $(ls -1 $HOME_PREFIX); do
    ((INDEX++))
     USER_ARRAY[$((INDEX))]="$TEMP_USERS"
  done
  return $INDEX
};

# Function to create a backup of entire HOME/$USER folders
function WEEKLY_BACKUP()
{
  storeUSERS
  for USERNAME in ${USER_ARRAY[@]}; do
    BACKUP_PATH="$HOME_PREFIX/$USERNAME"
    COMPRESSED_FILENAME="$BACKUP_PREFIX/$DOW-$USERNAME$COMPRESSED_SUFFIX"
    if [ -f $COMPRESSED_FILENAME ]; then rm $COMPRESSED_FILENAME; fi
    tar czfv "$COMPRESSED_FILENAME" "$BACKUP_PATH" 2>/dev/null
  done
  return $SUCCESS
}

# Function to create a backup of HOME/$USER smaller than NIGHTLY_MAX_FILE_SIZE
function NIGHTLY_BACKUP()
{
  storeUSERS
  for USERNAME in ${USER_ARRAY[@]}; do
    BACKUP_PATH="$HOME_PREFIX/$USERNAME"
    ARCHIVE_FILENAME="$BACKUP_PREFIX/$DOW-$USERNAME$BACKUP_SUFFIX"
    COMPRESSED_FILENAME="$BACKUP_PREFIX/$DOW-$USERNAME$COMPRESSED_SUFFIX"
    if [ -f $ARCHIVE_FILENAME ]; then rm $ARCHIVE_FILENAME; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then
	printf "Backup Path:\t\t%-25s\nArchive Filename:\t%-25s\nCompressed Filename:\t%-25s\n\n" "$BACKUP_PATH" "$ARCHIVE_FILENAME" "$COMPRESSED_FILENAME"
	OPTIONS="ufv"
    else
	OPTIONS="uf"
    fi
    while IFS= read -r line; do
      tar $OPTIONS "$ARCHIVE_FILENAME" "$line" 2>/dev/null
    done < <( find $BACKUP_PATH -size $NIGHTLY_MAX_FILE_SIZE )
    if [ -f $COMPRESSED_FILENAME ]; then rm $COMPRESSED_FILENAME; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then
	OPTIONS="czfv"
    else
	OPTIONS="czf"
    fi
    tar $OPTIONS "$COMPRESSED_FILENAME" "$ARCHIVE_FILENAME" 2>/dev/null
    if [ -f $ARCHIVE_FILENAME ]; then rm $ARCHIVE_FILENAME; fi
  done
  return $SUCCESS
};

# Check To See If There Are Any Command Line Options Present
for i in "$@"
do
case $i in
'-v' | '--verbose')
	BOL_VERBOSE=$TRUE
	;;
'-h' | '--help')
	BOL_HELP=$TRUE
	;;
'-n' | '--nightly')
	BOL_NIGHTLY=$TRUE
	;;
'-w' | '--weekly')
	BOL_WEEKLY=$TRUE
	;;
esac
done

if [ $BOL_WEEKLY -eq $TRUE ]; then
  BOL_NIGHTLY=$FALSE
  WEEKLY_BACKUP
  RETVAL=$?
fi

if [ $BOL_NIGHTLY -eq $TRUE ]; then
  NIGHTLY_BACKUP
  RETVAL=$?
fi

exit $RETVAL
