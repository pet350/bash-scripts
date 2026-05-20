#!/bin/bash
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
	--force-color)		declare -i BOL_COLOR=$TRUE;			declare -i BOL_FORCE_COLOR=$TRUE;;
	--bw)			declare -i BOL_COLOR=$FALSE;			declare -i BOL_FORCE_COLOR=$FALSE;;
	--test)			declare -i BOL_TEST=$TRUE;			declare -x TAR_BIN=$TRUE_BIN;;
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

if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;                                     		fi
if [ ${#HOSTNAME}		-eq 0 ]; then declare -x HOSTNAME=$(hostname --fqdn);				fi

if [ ${#BACKUP_LIST}		-eq 0 ]; then declare -x BACKUP_LIST="		$(CHECK_PREFIX /etc)		$(CHECK_PREFIX /boot)					\
 $(CHECK_PREFIX /usr/local/scripts)	$(CHECK_PREFIX /var/lib/samba) 		$(CHECK_PREFIX /var/lib/sss) 	$(CHECK_PREFIX /var/lib/www)				\
 $(CHECK_PREFIX /var/lib/krb5)		$(CHECK_PREFIX /usr/local/sbin)		$(CHECK_PREFIX /srv)		$(CHECK_PREFIX /var/www)				\
 $(CHECK_PREFIX /var/lib/mysql)		$(CHECK_PREFIX /var/lib/dhcp)		$(CHECK_PREFIX /var/lib/named)	$(CHECK_PREFIX /var/lib/bind)				\
 $(CHECK_PREFIX /var/lib/tomcat)	$(CHECK_PREFIX /var/lib/tomcat9)	$(CHECK_PREFIX /usr/local/bin)	$(CHECK_PREFIX /lib/modules/$(uname -r))";		fi

if [ ${#NFS_PREFIX}		-eq 0 ]; then declare -x NFS_PREFIX="/nfs";					fi
if [ ${#DOW}			-eq 0 ]; then declare -i DOW=$(date +%w);					fi
if [ ${#NFS_SERVER}		-eq 0 ]; then declare -x NFS_SERVER="rodc.gigaware.lan";			fi
if [ ${#NFS_EXPORT}		-eq 0 ]; then declare -x NFS_EXPORT="opt/sys.bak";				fi
if [ ${#BAK_FILENAME}		-eq 0 ]; then declare -x BAK_FILENAME="backup.tar.xz";				fi

# Reassemble list without all the spaces
for TEMP in $BACKUP_LIST; do
    TEMP_LIST="$TEMP_LIST $TEMP/*"
done

declare -x BACKUP_LIST="$TEMP_LIST"
declare -x BACKUP_TARGET="$NFS_PREFIX/$NFS_SERVER/$NFS_EXPORT/$HOSTNAME/$DOW"

if [ ! -d "$BACKUP_TARGE" ]; then
    mkdir -p -v "$BACKUP_TARGET"
fi

unset TEMP TEMP_LIST

SHOW_HEADER
INFO_MESSAGE "Hostname: $HOSTNAME"
INFO_MESSAGE "Backup List: $BACKUP_LIST"
INFO_MESSAGE "Backup Target: $BACKUP_TARGET/$BAK_FILENAME"
INFO_MESSAGE "Backup Binary: $TAR_BIN"
INFO_MESSAGE "Options: --xz -cvf"
INFO_EXEC_MESSAGE "$TAR_BIN --xz $CMD_LINE -cvf $BACKUP_LIST $BACKUP_TARGET/$BAK_FILENAME"

CY_TEXT; $TAR_BIN --xz $CMD_LINE -cvf $BACKUP_LIST "$BACKUP_TARGET"/"$BAK_FILENAME"; declare -i RETVAL=$?; CN_TEXT

exit $RETVAL
