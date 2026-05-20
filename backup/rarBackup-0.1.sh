#!/bin/bash
# Script for Full Data Backup as RAR Files
# By: Peter Talbott

## Do the backup Job with these options:
## -as          Synchronize archive contents
## -r           Recurse subdirectories
## -rr10        Add data recovery record
## -s           Create solid groups
## -m0          Set compression level (0-store)
## -ow          Save file owner and group
## -ol          Save symbolic links as the link instead of the file
## -v512M       Create volumes with size=512Mb
## -vn          Traditional Names (.rar, .r00, .r01, etc.)
## -y           Assume Yes on all queries

# Source LSB function library.
source /lib/lsb/init-functions

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

# Define Boolean Variables and set Default Values
declare -ig BOL_RUN=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_REMOVE_OLD=$TRUE
declare -ig BOL_DO_BACKUP=$TRUE
declare -ig BOL_DO_CHOWN=$TRUE
declare -ig BOL_DO_CHMOD=$TRUE

# Define String Variables
export RUN_CMD="$(basename $0)"
export BIN_PREFIX="/bin"
export USR_PREFIX="/usr"
export BAK_PREFIX="/opt/data.bak"
export RAR_BIN="$USR_PREFIX$BIN_PREFIX/rar"
export CHOWN_BIN="$BIN_PREFIX/chown"
export CHMOD_BIN="$BIN_PREFIX/chmod"
export ROOT_USER="root"
export ROOT_GROUP="root"
export FILE_PERMISSIONS="0600"

# Define Integer Variables
declare -ig VAR_COMPRESSION_LEVEL=0
declare -ig VAR_VOLUME_SIZE=512
declare -ig VAR_UNKNOWN=0
declare -ig VAR_BACKUP_INDEX=0

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
  exit $FAILURE
fi

# Define Global Arrays
declare -ag RAR_OPTION_ARRAY=("u" "-r" "-rr10" "-s" "-m$((VAR_COMPRESSION_LEVEL))" "-ow" "-ol" "-v$((VAR_VOLUME_SIZE))M" "-y");
declare -ag RAR_SOURCE_PATH_ARRAY=("/opt/prod/mp3drive" "/opt/prod/storage" "/opt/video/movies" "/opt/prod/tmp" "/opt/prod/roms");
declare -ag RAR_DESTIN_PATH_ARRAY=("$BAK_PREFIX/mp3drive.bak" "$BAK_PREFIX/storage.bak" "$BAK_PREFIX/movies.bak" "$BAK_PREFIX/porn.bak" "$BAK_PREFIX/roms.bak:");
declare -ag RAR_DESTIN_NAME_ARRAY=("mp3drive" "storage" "movies" "porn" "roms");

function CheckDestin()
{
  export DESTINATION="${RAR_DESTIN_PATH_ARRAY[$((VAR_BACKUP_INDEX))]}"
  export ARCHIVE_NAME="${RAR_DESTIN_NAME_ARRAY[$((VAR_BACKUP_INDEX))]}"
  export SOURCE_PATH="${RAR_SOURCE_PATH_ARRAY[$((VAR_BACKUP_INDEX))]}"
  if [ ! -d $DESTINATION ]; then mkdir -p $DESTINATION; fi
  return $?
};

function AssembleOPTS()
{
  export OPTIONS=""
  for DATA in ${RAR_OPTION_ARRAY[@]}; do
    export OPTIONS="$OPTIONS $DATA"
  done
  return $SUCCESS
};

function doBACKUP()
{
  declare -i RETVAL=$FAILURE
  CheckDestin
  AssembleOPTS
  if [ $BOL_REMOVE_OLD -eq $TRUE ]; then rm -vR $DESTINATION/$ARCHIVE_NAME*; fi
  if [ $BOL_DO_BACKUP -eq $TRUE ]; then $RAR_BIN $OPTIONS $DESTINATION/$ARCHIVE_NAME $SOURCE_PATH; fi
  RETVAL=$?
  if [ $BOL_DO_CHOWN -eq $TRUE ]; then $CHOWN_BIN -vR $ROOT_USER:$ROOT_GROUP $DESTINATION/$ARCHIVE_NAME*; fi
  if [ $BOL_DO_CHMOD -eq $TRUE ]; then $CHMOD_BIN -vR $FILE_PERMISSIONS $DESTINATION/$ARCHIVE_NAME*; fi
  return $RETVAL
};

for i in "$@"
do
case $i in
'--keep-old')
	export BOL_REMOVE_OLD=$FALSE
	;;
'--skip-backup')
	export BOL_DO_BACKUP=$FALSE
	;;
'--skip-chown')
	export BOL_DO_CHOWN=$FALSE
	;;
'--skip-chmod')
	export BOL_DO_CHMOD=$FALSE
	;;
'--mp3drive')
	export BOL_RUN=$TRUE
        export VAR_BACKUP_INDEX=0
        ;;
'--storage')
        export BOL_RUN=$TRUE
        export VAR_BACKUP_INDEX=1
        ;;
'--movies')
        export BOL_RUN=$TRUE
        export VAR_BACKUP_INDEX=2
        ;;
'--porn')
	export BOL_RUN=$TRUE
        export VAR_BACKUP_INDEX=3
	;;
'--roms')
        export BOL_RUN=$TRUE
        export VAR_BACKUP_INDEX=4
        ;;
'-v' | '--verbose')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
        export BOL_HELP=$TRUE
        ;;
*)
        (( VAR_UNKNOWN++ ))
        echo -e "$RUN_CMD Version $VERSION\nUnknown Parameter $i"
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

if [ $BOL_RUN -eq $FALSE ]; then
        echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD --help"
        exit $FAILURE
fi

if [ $BOL_RUN -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
        doBACKUP
        RETVAL=$?
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "RAR Backup of Index: $VAR_BACKUP_INDEX Successful!"
else
        log_failure_msg "RAR Backup of Index: $VAR_BACKUP_INDEX Failure!"
fi

exit $RETVAL
## Done!



