#!/bin/bash
# Script to "Autostart" any scripts in .Autostart,d folder
# By: Peter Talbott

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
declare -ig BOL_ROOT_CHECK=$TRUE

# Define String Variables
export RUN_CMD="$(basename $0)"
export PREFIX="/home/$(whoami)/.config/.Autostart.d"

# Define Intiger Variables
declare -ig VAR_COUNT=0

for i in "$@"
do
case $i in
'--no-root-check')
	export BOL_ROOT_CHECK=$FALSE
	;;
'-v' | '--verbose')
        export BOL_VERBOSE=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_ROOT_CHECK -eq $TRUE ]; then
  # Check That ROOT Is Not Trying To Run This Script
  if [ $(id -u) -eq 0 ]; then
    echo -e "$RUN_CMD Version $VERSION\nError: Cannot be ran as ROOT user!"
    exit $FAILURE
  fi
fi


if [ ! -d $PREFIX ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: $PREFIX Does Not Exist!"
  exit $FAILURE
fi

if [ $(ls -1 $PREFIX | wc -l) -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: $PREFIX Is Empty!"
  exit $FAILURE
fi

for TEMP in $(ls -1 $PREFIX/*); do
  (( VAR_COUNT++ ))
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $TEMP"; fi
  $TEMP &
done

echo -e "Total Count: $VAR_COUNT"
exit $SUCCESS


