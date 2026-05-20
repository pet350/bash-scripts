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
for DATA in brctl st host find; do
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

function SET_STP()
{							# Start the function definition
  for DATA in $($BRCTL_BIN show); do			# Loop through storing each word from 'brctl show' into DATA
    $BRCTL_BIN show $DATA >/dev/null 2>/dev/null	# Try 'brctl show $DATA' only a bridge name will be successful
    if [ $? -eq $SUCCESS ]; then			# Test to see if it was Successful
      if [ ${#ON_OFF} -ne 0 ]; then			# Check to see if there is anything stored in ON_OFF
	$BRCTL_BIN stp "$DATA" $ON_OFF			# Everything Check out. Go ahead and set STP for bridge either On or Off
        declare -i RETVAL=$?				# Store the return value from previous command into RETVAL
      fi						# End 'IF' statment for checking 'ON_OFF'
    fi							# End the 'IF' statement for checking if '$DATA' is a bridge device
  done							# Done with Loop
  return $RETVAL					# Return value stored in RETVAL
};							# End of function definition

for OPTIONS in $@; do					# Loop through all command prompt options storing them to OPTIONS
    case ${OPTIONS,,} in				# A way to parse what is stored in '$OPTIONS' (converted to all lowercase letters)
      'start' | 'on')	export ON_OFF="on";;		# 'start' or 'on' set bridges stp on
      'stop' | 'off')	export ON_OFF="off";;   	# 'stop' or 'off' set bridges stp off
      -v | --verbose)	declare -i BOL_VERBOSE=$TRUE;;	# Set Boolean Verbose True
      *)		unset ON_OFF;;			# Anything else unset controlling variable
    esac						# Done with case statement
done							# done with loop

if [ ${#BOL_VERBOSE} -eq 0 ]; then declare BOL_VERBOSE=$FALSE;	fi
SHOW_HEADER						# Call the SHOW_HEADER Function
SET_STP							# Call the SET_STP function
declare -i EXIT_VAL=$?
if [ $BOL_VERBOSE -eq $TRUE ]; then $BRCTL_BIN show; fi
exit $EXIT_VAL
