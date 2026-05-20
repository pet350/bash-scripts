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

# Define global string variables
export DEV_NULL="/dev/null"

# Define global string variables if not already set by environment
if [ ${#CONFIG_PATH}	-eq 0 ]; then export CONFIG_PATH="/etc/local/fs";	fi
if [ ${#FIND_BIN}	-eq 0 ]; then export FIND_BIN="/bin/find";		fi
if [ ${#OUTPUT}		-eq 0 ]; then export OUTPUT="$DEV_NULL";		fi

if [ $($FIND_BIN $CONFIG_PATH -iname '*.conf' | $WC_BIN -l) -eq 0 ]; then
  echo -e "Error! No mount configuration files found in $CONFIG_PATH"
  exit $FAILURE
fi

function MAIN_LOOP()
{
  declare -i FUNCTION_RETURN=$SUCCESS

  while IFS= read LINE; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Loading configuration file: $LINE"; fi
    unset DEVICE
    unset TARGET
    unset OPTIONS
    . $LINE
    if [ ${#DEVICE} -ne 0 ] && [ ${#TARGET} -ne 0 ]; then
      $MOUNT_BIN | $GREP_BIN $TARGET >$OUTPUT 2>$DEV_NULL 3>$DEV_NULL
      if [ $? -ne $SUCCESS ]; then
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $MOUNT_BIN $OPTIONS $DEVICE $TARGET"; fi
        $MOUNT_BIN $OPTIONS $DEVICE $TARGET >$OUTPUT 2>$DEV_NULL 3>$DEV_NULL
        FUNCTION_RETURN=$?
      else
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$TARGET: Already mounted."; fi
      fi
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Error in configuration file: $LINE!"; fi
    fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "\n"; fi
  done < <($FIND_BIN $CONFIG_PATH -iname '*.conf')
  return $FUNCTION_RETURN
};

for i in "$@"; do
  case $i in
    '-h' | '--help')
	export BOL_HELP=$TRUE
	;;
    '-d' | '--debug')
	export BOL_DEBUG=$TRUE
	export BOL_VERBOSE=$TRUE
        export OUTPUT="/dev/stdout"
	;;
    '-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
  esac
done

if [ $BOL_COLOR		-eq $TRUE	]; then INIT_COLOR_SHORTHAND;			fi
if [ $BOL_HELP		-eq $TRUE	]; then DO_HELP;				fi
if [ $(id -u)		-ne 0	  	]; then CHECK_ROOT_USER;			fi

MAIN_LOOP
exit $?
