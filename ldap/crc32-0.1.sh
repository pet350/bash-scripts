#! /bin/bash
### By: Peter Talbott 2019-08-15

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

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { config-file.ldif }"
    exit $FAILURE
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export TMP_PREFIX="/tmp"

export TEMP_FILE="$TMP_PREFIX/ldif32.tmp"

declare -ig RETVAL=$FAILURE

for FILE_NAMES in $@; do
  grep -v '^#' "$FILE_NAMES" > $TEMP_FILE
  for DATA in $(rhash -C "$TEMP_FILE"); do echo -e "" >/dev/null; done
  RETVAL=$?
  printf "%-20s: CRC32 Checksum: %-20s\n" "$FILE_NAMES" "$DATA"
  rm $TEMP_FILE
done

printf "\n"
if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "$SYSCTL_BIN $SYSCTL_OPT $@ Success!"
else
        log_failure_msg "$SYSCTL_BIN $SYSCTL_OPT $@ Failure!"
fi

exit $RETVAL
