#! /bin/bash
# Simple Script to CHROOT to TARGET Directory
# By Peter Talbott

VERSION=0.1

# Define Global TRUE/FALSE Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define Global SUCCESS/FAILURE Variables
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define String Variables
export RUN_CMD="$(basename $0)"

declare -ag BIND_ARRAY=("proc" "dev" "sys" "run");

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD (mount Point)"
  exit $FAILURE
fi

for TEMP in ${BIND_ARRAY[@]}; do
  if [ ! -d $1/$TEMP ]; then
    echo -e "$RUN_CMD Version $VERSION\nError: Directory $1/$TEMP Does Not Exist!"
    exit $FAILURE
  else
    mount --bind /$TEMP $1/$TEMP
  fi
done

chroot $1/

