#!/bin/bash
# Script for Full MySQL Database Backup
# By: Peter Talbott

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
declare -ig BOL_BZIP_OUT=$TRUE
declare -ig BOL_DO_BACKUP=$TRUE
declare -ig BOL_DO_CHOWN=$TRUE
declare -ig BOL_DO_CHMOD=$TRUE

# Define String Variables
export RUN_CMD="$(basename $0)"
export DOW=$(date +%w)
export BIN_PREFIX="/bin"
export USR_PREFIX="/usr"
export BAK_PREFIX="/opt/bak/sql/database/sql"
export SQL_SUFFIX="sql"
export BZIP_SUFFIX="bz2"
export SQL_SERVICE="mysql"
export VERBOSE=""

# Define Binary Variables
export MYSQLDUMP_BIN="$USR_PREFIX$BIN_PREFIX/mysqldump"
export BZIP_BIN="$BIN_PREFIX/bzip2"
export CHOWN_BIN="$BIN_PREFIX/chown"
export CHMOD_BIN="$BIN_PREFIX/chmod"
export PGREP_BIN="$BIN_PREFIX/pgrep"

# File System Variables
export ROOT_USER="root"
export ROOT_GROUP="root"
export FILE_PERMISSIONS="0600"

# SQL Variables
export SQL_USER="root"
export SQL_PASS="Thund3rstruck!"

# Define Integer Variables
declare -ig VAR_UNKNOWN=0

# Define Global Arrays
declare -ag SQL_DATABASE_ARRAY=("cacti" "mysql" "phpmyadmin" "sys" "zm" "ZoneMinder");

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD { start | --help }"
  exit $FAILURE
fi

# Check If MYSQL is Running
$PGREP_BIN $SQL_SERVICE >/dev/null
if [ $? -ne $SUCCESS ]; then
  echo -e "MYSQL Service NOT Running!\nAttempting To Start MYSQL...\n"
  systemctl start $SQL_SERVICE
  if [ $? -ne $SUCCESS ]; then
    echo -e "MYSQL Did NOT Start!"
    exit $FAILURE
  else
    echo -e "MYSQL Started Successfully!"
  fi
fi

function doBACKUP()
{
  for DB in ${SQL_DATABASE_ARRAY[@]}; do
    BACKUP_FILE="$BAK_PREFIX/$DOW-$DB.$SQL_SUFFIX"
    if [ $BOL_DO_BACKUP -eq $FALSE ]; then MYSQLDUMP_BIN="$BIN_PREFIX/false"; fi
    if [ $BOL_BZIP_OUT -eq $TRUE ]; then BACKUP_FILE="$BACKUP_FILE.$BZIP_SUFFIX"; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%-12s\t%-20s\n" "Database:" "$DB"; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%-12s\t%-20s\n" "Backup File:" "$BACKUP_FILE"; fi
    if [ $BOL_BZIP_OUT -eq $TRUE ]; then $MYSQLDUMP_BIN -u $SQL_USER -p $DB --password=$SQL_PASS 2>/dev/null | $BZIP_BIN >$BACKUP_FILE
    else $MYSQLDUMP_BIN -u $SQL_USER -p $DB --password=$SQL_PASS >$BACKUP_FILE 2>/dev/null; fi
    RETVAL=$?
  done
  return $RETVAL
};

function doSTART()
{
  declare -i RETVAL=$FAILURE
  doBACKUP
  RETVAL=$?
  if [ $BOL_DO_CHOWN -eq $TRUE ]; then $CHOWN_BIN -R $ROOT_USER:$ROOT_GROUP $BAK_PREFIX/*.$SQL_SUFFIX* $VERBOSE; fi
  if [ $BOL_DO_CHMOD -eq $TRUE ]; then $CHMOD_BIN -R $FILE_PERMISSIONS $BAK_PREFIX/*.$SQL_SUFFIX* $VERBOSE; fi
  return $RETVAL
};

function do_HELP()
{
   printf "%-15s %-8s %-3s\n%-16s\n\n" "$RUN_CMD" "Version: " "$VERSION" "HELP! Section!"
   printf "%-10s\t\t%-20s\n" "start" "Required Parameter"
   printf "%-10s\t\t%-20s\n" "-h | --help" "Display This Message"
   printf "%-10s\t\t%-20s\n\n" "-v | --verbose" "Show Verbose Messages"
   printf "%-10s\t\t%-20s\n" "--skip-backup" "Don't Actually Backup SQL Databases"
   printf "%-10s\t\t%-20s\n" "--skip-chown" "Don't Change Ownership Of Backup Files"
   printf "%-10s\t\t%-20s\n" "--skip-chmod" "Don't Change Permissions Of Backup Files"
   printf "%-10s\t\t%-20s\n\n" "--no-bzip" "Do Not Compress Backup Files"

   return $SUCCESS
};


for i in "$@"
do
case $i in
'--no-bzip')
	export BOL_BZIP_OUT=$FALSE
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
'start')
	export BOL_RUN=$TRUE
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
        doSTART
        RETVAL=$?
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "SQL Backup Successful!"
else
        log_failure_msg "SQL Backup Failure!"
fi

exit $RETVAL
## Done!



