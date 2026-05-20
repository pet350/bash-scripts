#!/bin/bash
## VERRY Simple Script to Backup User Files

if [ $(id -u) -ne 0 ]; then
	echo "Must be ran as root!"
	exit 1
fi

export VERSION=0.1

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

function storeUSERS()
{
  INDEX=-1
  for TEMP_USERS in $(ls -1 $HOME_PREFIX); do
    ((INDEX++))
     USER_ARRAY[$((INDEX))]="$TEMP_USERS"
  done
  return $INDEX
};

function NIGHTLY_BACKUP()
{
  storeUSERS
  declare -a FILE_LIST=();
  declare -i INDEX=-1
  declare -i COUNT=-1
  QUOTE="'"
  for USERNAME in ${USER_ARRAY[@]}; do
    FILE_LIST=();
    TEMP=""
    INDEX=-1
    BACKUP_PATH="$HOME_PREFIX/$USERNAME"
    ARCHIVE_FILENAME="$BACKUP_PREFIX/$DOW-$USERNAME$BACKUP_SUFFIX"
    COMPRESSED_FILENAME="$BACKUP_PREFIX/$DOW-$USERNAME$COMPRESSED_SUFFIX"
    printf "Backup Path: %-25s\tArchive Filename: %-25s\n" "$BACKUP_PATH" "$ARCHIVE_FILENAME"
    while IFS= read -r line; do
      ((INDEX++))
      FILE_LIST[$((INDEX))]="$line"
    done < <( find $BACKUP_PATH -size $NIGHTLY_MAX_FILE_SIZE )
    if [ -f $ARCHIVE_FILENAME ]; then rm $ARCHIVE_FILENAME; fi
    COUNT=-1
    while [ $COUNT -lt $INDEX ]; do
      ((COUNT++))
      TEMP="${FILE_LIST[$((COUNT))]}"
      tar ufv "$ARCHIVE_FILENAME" "$TEMP"
    done
    #tar czfv $ARCHIVE_FILENAME $LONG_STRING
  done
};

NIGHTLY_BACKUP
