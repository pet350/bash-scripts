#!/bin/bash
# Script to "Autostart" any scripts in .Autostart,d folder
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
VERSION=0.2

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
if [ ${#BOL_START}	-eq 0 ]; then declare -ig BOL_START=$FALSE;	fi
if [ ${#BOL_STOP}	-eq 0 ]; then declare -ig BOL_STOP=$FALSE;	fi
if [ ${#BOL_HELP}	-eq 0 ]; then declare -ig BOL_HELP=$FALSE;	fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -ig BOL_VERBOSE=$FALSE;	fi
if [ ${#BOL_ROOT_CHECK}	-eq 0 ]; then declare -ig BOL_ROOT_CHECK=$TRUE;	fi

# Define String Variables
export RUN_CMD="$(basename $0)"
export PREFIX="$HOME/.config/.Autostart.d"
export SYMLINK="$HOME/autostart"

if [ ! -f "$PREFIX"  ]; then mkdir -p "$PREFIX"; fi
if [ ! -L "$SYMLINK" ]; then ln -sf "$PREFIX" "$SYMLINK"; fi

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


