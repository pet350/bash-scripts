#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEMP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_LOG_RESULTS=$TRUE

# Define Global SYSCTL Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_STATUS=$FALSE
declare -ig BOL_ENABLE=$FALSE
declare -ig BOL_DISABLE=$FALSE

export BaseDN="dc=gigaware,dc=lan"

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export NFS_PREFIX="/nfs"

# Define Binary Variables
export GREP_BIN="$BIN_PREFIX/grep"
export NMAP_BIN="$USER_PREFIX$BIN_PREFIX/nmap"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export IPCALC_BIN="$BIN_PREFIX/ipcalc"
export IFCONFIG_BIN="$SBIN_PREFIX/ifconfig"
export MOUNT_BIN="$SBIN_PREFIX/mount.nfs"
export MNT_BIN="$BIN_PREFIX/mount"
export UMOUNT_BIN="$BIN_PREFIX/umount"
export LDAPSEARCH_BIN="$USER_PREFIX$BIN_PREFIX/ldapsearch"
# Define Option Variables
export SYSCTL_OPT=""
export MOUNT_OPT="-s"
export SUBNET=""

# Define Global Integer Variables
declare -ig EXIT_VAL=$SUCCESS
declare -ig RETVAL=$SUCCESS
declare -ig INDEX_VAL=-1
declare -ig VAR_WAIT=1

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "Success!"
  else
    log_failure_msg "Failure!"
  fi
  return $RETVAL
};

