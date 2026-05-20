#!/bin/bash
# Script to "Clean" /var/log folder
# By: Peter Talbott

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
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_VERBOSE=$FALSE

# Define String Variables
export RUN_CMD="$(basename $0)"
export PREFIX="/var/log"

# Define Intiger Variables
declare -ig VAR_COUNT=0

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

if [ ! -d $PREFIX ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: $PREFIX Does Not Exist!"
  exit $FAILURE
fi

if [ $(ls -1 $PREFIX | wc -l) -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: $PREFIX Is Empty!"
  exit $FAILURE
fi

declare -ag EXTENTION_ARRAY=(".gz" ".xz" ".old" ".journal~" ".0" ".1" ".2" ".3" ".4" ".5" ".6" ".7" ".8" ".9" ".10");

for TEMP_EXT in ${EXTENTION_ARRAY[@]}; do
  echo -e "Extention: $TEMP_EXT"
  for TEMP_NAME in $(find $PREFIX -name "*$TEMP_EXT"); do
    rm -v $TEMP_NAME
  done
done

