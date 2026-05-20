#!/bin/bash
# Shell Script By: Peter Talbott
# 2021-07-20, 2021-08-30

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
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2021-08-30"

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --mysql-user=*) 		 export MYSQL_USER="${OPTIONS#*=}";;
    --mysql-pass=*)		 export MYSQL_PASS="${OPTIONS#*=}";;
    --backup-prefix=*)		 export BACKUP_PREFIX="${OPTIONS#*=}";;
    --backup-path=*)		 export BACKUP_PATH="${OPTIONS#*=}";;
    --nfs-server=*)		 export NFS_SERVER="${OPTIONS#*=}";;
    --nfs-export=*)		 export NFS_EXPORT="${OPTIONS#*=}";;
    --max-fail=*)		 export MAX_FAIL="${OPTIONS#*=}";;
    --no-warn-error)		 export BOL_WARN_ERROR=$FALSE;;
    --no-mount)			 export BOL_NFS=$FALSE;;
    --verbose)			 export VERBOSE="-v";				export BOL_VERBOSE=$TRUE;;
    --cfg-file=*)		 export CFG_FILE="${OPTIONS#*=}";;
    --quiet)			 export VERBOSE=" ";				export BOL_QUIET=$TRUE;;
    --test)			 export XZ_BIN=$TRUE_BIN;			export DUMP=$TRUE_BIN;;
    --help)			 export BOL_HELP=$TRUE;;
    --version)			 SHOW_HEADER;					exit $SUCCESS;;
  esac
done

# Define String Variables if NOT Already Defined
if [ ${#MYSQL_USER}	-eq 0 ]; then export MYSQL_USER="BackupAdmin";								fi
if [ ${#MYSQL_PASS}	-eq 0 ]; then export MYSQL_PASS="Cr33p1ngD34th";							fi
if [ ${#BACKUP_PREFIX}	-eq 0 ]; then export BACKUP_PREFIX="/mnt/bak";								fi
if [ ${#BACKUP_PATH}	-eq 0 ]; then export BACKUP_PATH="$BACKUP_PREFIX/$(hostname --fqdn)/database";				fi
if [ ${#NFS_SERVER}	-eq 0 ]; then export NFS_SERVER="lxc.gigaware.lan";							fi
if [ ${#NFS_EXPORT}	-eq 0 ]; then export NFS_EXPORT="/opt/bak";								fi
if [ ${#VERBOSE}	-eq 0 ]; then export VERBOSE="--verbose";								fi
if [ ${#DUMP}		-eq 0 ]; then export DUMP="$MYSQLDUMP_BIN";								fi
if [ ${#CFG_FIlE}	-eq 0 ]; then export CFG_FILE="/etc/mysql.backup.cfg";							fi

# Define Integer Variables if NOT Already Defined
if [ ${#BOL_NFS}	-eq 0 ]; then declare -ig BOL_NFS=$TRUE;								fi
if [ ${#BOL_BAK}	-eq 0 ]; then declare -ig BOL_BAK=$TRUE;								fi
if [ ${#BOL_WARN_ERROR} -eq 0 ]; then declare -ig BOL_WARN_ERROR=$TRUE;								fi
if [ ${#THREADS}	-eq 0 ]; then declare -ig THREADS=2;									fi
if [ ${#MAX_FAIL}	-eq 0 ]; then declare -ig MAX_FAIL=3;									fi
if [ $BOL_QUIET		-eq $FALSE ]; then echo -e "$RUN_CMD\t\t\tVersion: $VERSION\n";						fi

# Defing Global Arrys
declare -ag DATABASES=();

# Load Config File IF It Exists
if [ -f $CFG_FILE ]; then
  if [ $BOL_QUIET	    -eq $FALSE ]; then
    echo -e "[Info] Found config file:\t$CFG_FILE"
    echo -e "[Info] Loading values from config file\n"
  fi
  . $CFG_FILE
fi

function BACKUP_JOB()
{
  declare -i FUNCTION_RETURN=$FAILURE
  BAK_FILENAME="$(date +%A)-$CURRENT_DB.sql.xz"
  BAK_FULL_NAME="$BACKUP_PATH/$BAK_FILENAME"
  COMMAND="$DUMP"
  if [ $BOL_QUIET         -eq $FALSE ]; then
    echo -e "Creating Backup: $BAK_FULL_NAME"
    echo -e "Failure Count: $FAIL_COUNT of $MAX_FAIL"
  fi
  $DUMP -u $MYSQL_USER --databases $CURRENT_DB --password=$MYSQL_PASS | $XZ_BIN --compress --threads=$THREADS $VERBOSE >$BAK_FULL_NAME
  FUNCTION_RETURN=${PIPESTATUS[0]}
  if [ $BOL_WARN_ERROR -eq $FALSE ] && [ $FUNCTION_RETURN -eq 1 ]; then FUNCTION_RETURN=0; fi
  return $FUNCTION_RETURN
};

# Function to loop through Backup Job(s)
function BACKUP_LOOP()
{
  declare -i RETVAL=$FAILURE
  declare -i FAIL_COUNT=0
  declare -i BOL_LOOP=$TRUE

  for CURRENT_DB in ${DATABASES[@]}; do
    BOL_LOOP=$TRUE
    FAIL_COUNT=0
    while [ $BOL_LOOP -eq $TRUE ]; do
      BACKUP_JOB
      RETVAL=$?
      if [ $BOL_QUIET -eq $FALSE ]; then printf "Return Value: (%s) " $RETVAL; LOG_RESULTS; echo -e '';					fi
      if [ $RETVAL  -eq $SUCCESS ] || [ $FAIL_COUNT -eq $MAX_FAIL ]; then BOL_LOOP=$FALSE; else ((FAIL_COUNT++)); BOL_LOOP=$TRUE;	fi
    done
  done

  return $RETVAL
};

# Self Explanitory
function SHOW_INFO()
{
  export PASS_CHARS=""
  declare -i LEN=0 
  while [ $((LEN)) -lt ${#MYSQL_PASS} ]; do
    ((LEN++))
    PASS_CHARS=$PASS_CHARS'*'
  done
  echo -e "[Info] Database List:\t\t${DATABASES[@]}"
  echo -e "[Info] Database User:\t\t$MYSQL_USER"
  echo -e "[Info] Database Pass:\t\t$PASS_CHARS"
  echo -e "[Info] NFS Export:\t\t$NFS_SERVER:$NFS_EXPORT"
  echo -e "[Info] Backup Path:\t\t$BACKUP_PATH"
  echo -e "[Info] mysql Binary:\t\t$MYSQL_BIN"
  echo -e "[Info] mysqldump Binary:\t$DUMP"
  echo -e "[Info] xz Binary:\t\t$XZ_BIN"
  echo -e ""
  return $SUCCESS
};

function MOUNT_NFS()
{
  declare -i RETVAL=$SUCCESS
  if [ ! -d $BACKUP_PREFIX ]; then mkdir -p $BACKUP_PREFIX;									fi
  export COMMAND="$MOUNT_BIN $NFS_SERVER:$NFS_EXPORT $BACKUP_PREFIX"
  if [ $BOL_QUIET         -eq $FALSE ]; then echo -e "Mounting NFS Export $NFS_SERVER:$NFS_EXPORT To $BACKUP_PREFIX";		fi
  $MOUNT_BIN "$NFS_SERVER:$NFS_EXPORT" "$BACKUP_PREFIX"
  RETVAL=$?
  if [ $BOL_QUIET         -eq $FALSE ]; then LOG_RESULTS; echo -e '';								fi
  if [ ! -d $BACKUP_PATH ]; then mkdir -p $BACKUP_PATH;										fi
  return $RETVAL
};

function UNMOUNT_NFS()
{
  declare -i RETVAL=$SUCCESS
  export COMMAND="$UMOUNT_BIN $BACKUP_PREFIX"
  if [ $BOL_QUIET         -eq $FALSE ]; then echo -e "UnMounting NFS Export $NFS_SERVER:$NFS_EXPORT From $BACKUP_PREFIXf";	fi
  $UMOUNT_BIN "$BACKUP_PREFIX"
  RETVAL=$?
  if [ $BOL_QUIET         -eq $FALSE ]; then LOG_RESULTS; echo -e '';								fi
  return $RETVAL
};

# Function will enumerate databases and store them into the DATABASE Array
function GET_DATABASES()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i INDEX=-1
  while IFS= read LINE; do
    case $LINE in
      '#mysql50#lost+found' | 'Database' | 'performance_schema' | 'information_schema')
        # Do nothing when $LINE equals any of the above
        ;;
      *)
        ((INDEX++))
        DATABASES[$((INDEX))]="$LINE"
        FUNCTION_RETURN=$SUCCESS
        ;;
    esac
  done < <(echo -e "SHOW DATABASES;" | $MYSQL_BIN -u "$MYSQL_USER" --password="$MYSQL_PASS")
  return $FUNCTION_RETURN
};

GET_DATABASES
if [ $BOL_QUIET         -eq $FALSE ]; then SHOW_INFO;                                                                           fi
if [ $BOL_NFS		-eq $TRUE  ]; then MOUNT_NFS;										fi
if [ $BOL_BAK		-eq $TRUE  ]; then BACKUP_LOOP;										fi
if [ $BOL_NFS		-eq $TRUE  ]; then UNMOUNT_NFS;										fi


