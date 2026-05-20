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
export MODIFIED="2022-07-18"

# Define a few more binary variables
for DATA in mount umount grep find; do
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

function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

if [ ${#MOUNT_PREFIX}	-eq 0 ]; then declare -x MOUNT_PREFIX="/var/lib/jellyfin/catalog";						fi
if [ ${#MOUNT_ARRAY[@]} -eq 0 ]; then declare -a MOUNT_ARRAY=("$MOUNT_PREFIX/movies" "$MOUNT_PREFIX/music" "$MOUNT_PREFIX/porn"); 	fi

for DIRECTORY in ${MOUNT_ARRAY[@]}; do
    $MOUNT_BIN | $GREP_BBIN $DIRECTORY >/dev/null 2>/dev/null
    if [ $? -ne $SUCCESS ]; then $MOUNT_BIN $DIRECTORY 2>/dev/null; fi
done

exit $SUCCESS
