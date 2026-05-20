#!/bin/bash
# cfgbak.sh Configuration Backup Script
# Prerequisite: multipart-tar.sh
#     Script that carries out he backup job
# Shell Script By: Peter Talbott

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
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in st klist curl egrep chown sleep cat wc find true; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

for OPTIONS in $@; do
    case $OPTIONS in
	--force-color)		declare -i BOL_FORCE_COLOR=$TRUE;;
	--date-filename)	declare -i DATE_FILENAME=$TRUE;;
	*)			declare -x CMD_LINE="$CMD_LINE $OPTIONS"
    esac
done

function SHOW_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success. Return Value: $RETVAL"
  else
    echo -e "Failure. Return Value: $RETVAL"
  fi
};

function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  CLB_TEXT; printf "%-24s" $RUN_CMD; CY_TEXT; printf "Version: "; CC_TEXT; printf "%-4s" $VERSION; CN_TEXT; printf "\n"
  CLB_TEXT; printf "By: "; CLR_TEXT; printf "%-20s" "$AUTHOR"; CLB_TEXT; printf "Dated: "; CLR_TEXT; printf "%-20s" "$MODIFIED"; CN_TEXT; printf "\n"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

function DEBUG_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Starting: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_EXEC_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Executing: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_FOUND_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Found: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_INFO_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Information: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};


function DEBUG_DONE_MESSAGE()
{
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n"
  fi
  return $RETVAL
};

function CHECK_PREFIX()
{
    declare -i RETVAL=$FAILURE
    declare -x CHECK="$1"
    if [ -d "$CHECK" ]; then
        echo -e "$CHECK"
        RETVAL=$SUCCESS
    fi
    return $RETVAL
};

function BACKUP_ONE_MULTIPART_TAR_PER_SOURCE()
{
  declare -i INDEX=-1
  for SOURCE in ${SOURCE_ARRAY[@]}; do
      ((INDEX++))
      DEBUG_INFO_MESSAGE "Index: $INDEX Source Prefix: $SOURCE"
      TARGET_PREFIX="$NFS_PREFIX/$NFS_SERVER/opt/sys.bak/$HOSTNAME/$DOW"
      DEBUG_INFO_MESSAGE "Index: $INDEX Target Prefix: $TARGET_PREFIX"
      if [ ! -d "$TARGET_PREFIX" ]; then mkdir -p "$TARGET_PREFIX"; fi
      $BAK_SCRIPT --all --source="$SOURCE" --target="$TARGET_PREFIX/${SOURCE##*/}" $CMD_LINE
      declare -i RETVAL=$?
      DEBUG_DONE_MESSAGE "Backup of: $SOURCE returned $RETVAL"
  done
  return $RETVAL
};

function BACKUP_ONE_MULTIPART_TAR_FOR_ALL_SOURCE()
{
  declare -i INDEX=-1
  for SOURCE in ${SOURCE_ARRAY[@]}; do
      ((INDEX++))
      if [ $INDEX -eq 0 ]; then
	declare -x APPEND=""
      else
	declare -x APPEND="--append"
      fi
      declare -x INCLUDE_PATH="--include-path"
      DEBUG_INFO_MESSAGE "Index: $INDEX Source Prefix: $SOURCE"
      TARGET_PREFIX="$NFS_PREFIX/$NFS_SERVER/opt/sys.bak/$HOSTNAME/$DOW"
      DEBUG_INFO_MESSAGE "Index: $INDEX Target Prefix: $TARGET_PREFIX"
      if [ ! -d "$TARGET_PREFIX" ]; then mkdir -p "$TARGET_PREFIX"; fi
      $BAK_SCRIPT --all $INCLUDE_PATH $APPEND --source="$SOURCE" --target="$TARGET_PREFIX/$(date +%A)-Backup"
      declare -i RETVAL=$?
      DEBUG_DONE_MESSAGE "Backup of: $SOURCE returned $RETVAL"
  done
  return $RETVAL
};

if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;                                     		fi
if [ ${#BAK_SCRIPT}		-eq 0 ]; then declare -x BAK_SCRIPT="/usr/local/sbin/multipart-tar.sh";		fi
if [ ${#HOSTNAME}		-eq 0 ]; then declare -x HOSTNAME=$(hostname --fqdn);				fi
if [ ${#SOURCE_LIST}		-eq 0 ]; then declare -x SOURCE_LIST="		$(CHECK_PREFIX /etc)		$(CHECK_PREFIX /boot)			\
 $(CHECK_PREFIX /usr/local/scripts)	$(CHECK_PREFIX /var/lib/samba) 		$(CHECK_PREFIX /var/lib/sss) 	$(CHECK_PREFIX /var/lib/www)		\
 $(CHECK_PREFIX /var/lib/krb5)		$(CHECK_PREFIX /usr/local/sbin)		$(CHECK_PREFIX /srv)		$(CHECK_PREFIX /usr/local/share)	\
 $(CHECK_PREFIX /var/lib/mysql)		$(CHECK_PREFIX /var/lib/dhcp)		$(CHECK_PREFIX /var/lib/named)	$(CHECK_PREFIX /var/lib/bind)		\
 $(CHECK_PREFIX /lib/modules/$(uname -r))";									fi
if [ ${#NFS_PREFIX}		-eq 0 ]; then declare -x NFS_PREFIX="/nfs";					fi
if [ ${#DOW}			-eq 0 ]; then declare -i DOW=$(date +%w);					fi
if [ ${#NFS_SERVER}		-eq 0 ]; then declare -x NFS_SERVER="rodc.gigaware.lan";			fi
if [ ${#DATE_FILENAME}		-eq 0 ]; then declare -i DATE_FILENAME=$FALSE;					fi

declare -i INDEX=-1
for SOURCE in $SOURCE_LIST; do
    ((INDEX++))
    declare -a SOURCE_ARRAY[$((INDEX))]="$SOURCE"
done

if [ $DATE_FILENAME -eq $TRUE ]; then
    BACKUP_ONE_MULTIPART_TAR_FOR_ALL_SOURCE
    declare -i RETVAL=$?
else
    BACKUP_ONE_MULTIPART_TAR_PER_SOURCE
    declare -i RETVAL=$?
fi

exit $RETVAL
