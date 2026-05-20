#!/bin/bash
# mcli.sh - Remote Unlock
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
export MODIFIED="2023-08-15"

# Define a few more binary variables
for DATA in mcli curl egrep chown sleep cat; do
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

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

function SET_PROMPT()
{
    declare -i INDEX=-1
    declare -i BOL_SET=$FALSE
    unset TEMP_PROMPT
    for WORD in ${LINE,,}; do
        ((INDEX++))
        if [ $INDEX -eq 0 ] && [ $WORD == 'prompt'  ]; then declare -i BOL_SET=$TRUE;		fi
	if [ $INDEX -ne 0 ] && [ $BOL_SET -eq $TRUE ]; then TEMP_PROMPT="$TEMP_PROMPT $WORD";	fi
    done
    if [ $BOL_SET -eq $TRUE ]; then declare -i RETVAL=$SUCCESS; else declare -i RETVAL=$FAILURE; fi
    echo -e "$TEMP_PROMPT"
    return $RETVAL
};

function SET_SUFFIX()
{
    declare -i INDEX=-1
    declare -i BOL_SET=$FALSE
    unset TEMP_SUFFIX
    for WORD in ${LINE,,}; do
        ((INDEX++))
        if [ $INDEX -eq 0 ] && [ $WORD == 'suffix'  ]; then declare -i BOL_SET=$TRUE;           fi
        if [ $INDEX -ne 0 ] && [ $BOL_SET -eq $TRUE ]; then TEMP_SUFFIX="$TEMP_SUFFIX $WORD";   fi
    done
    if [ $BOL_SET -eq $TRUE ]; then declare -i RETVAL=$SUCCESS; else declare -i RETVAL=$FAILURE; fi
    echo -e "$TEMP_SUFFIX"
    return $RETVAL
};

if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;                     		fi
if [ ${#MCLI_PROMPT}	-eq 0 ]; then declare -x MCLI_PROMPT="mcli";				fi

declare -i BOL_PROMPT=$FALSE
declare -i BOL_SUFFIX=$FALSE
declare -i BOL_RESULTS=$FALSE
declare -i BOL_HELP=$FALSE

while [ $TRUE -eq $TRUE ]; do
    CLB_TEXT; printf "%s# " $MCLI_PROMPT
    CLR_TEXT; read LINE
    CN_TEXT;
    unset OPTIONS
    declare -i BOL_EXECUTE=$TRUE
    for WORD in ${LINE,,}; do
        case $WORD in
	    'quit' | 'exit')		CN_TEXT;				break 2;;
	    'prompt')			declare -i BOL_EXECUTE=$FALSE;		declare -i BOL_PROMPT=$TRUE;;
	    'suffix')			declare -i BOL_EXECUTE=$FALSE;		declare -i BOL_SUFFIX=$TRUE;;
	    'help')			declare -i BOL_EXECUTE=$FALSE;		declare -i BOL_HELP=$TRUE;;
	    'results')			((BOL_RESULTS++)); if [ $BOL_RESULTS -gt 1 ]; then declare -i BOL_RESULTS=0; fi;;
	    *)				declare -x OPTIONS="$OPTIONS $WORD";;
	esac
    done
    if [ $BOL_PROMPT	-eq $TRUE ]; then declare -x MCLI_PROMPT=$(SET_PROMPT);		declare -i BOL_PROMPT=$FALSE;						fi
    if [ $BOL_SUFFIX	-eq $TRUE ]; then declare -x MCLI_SUFFIX=$(SET_SUFFIX);		declare -i BOL_SUFFIX=$FALSE;						fi
    if [ $BOL_HELP	-eq $TRUE ]; then $MCLI_BIN 'help'; declare -i RETVAL=$?;	declare -i BOL_HELP=$FALSE;						fi
    if [ $BOL_EXECUTE	-eq $TRUE ] && [  ${#OPTIONS}  -ne 0 ]; then $MCLI_BIN $OPTIONS $MCLI_SUFFIX;	declare -i RETVAL=$?; else RETVAL=$SUCCESS;		fi
    if [ $BOL_EXECUTE	-eq $TRUE ] && [ $BOL_RESULTS -eq $TRUE ]; then LOG_RESULTS;										fi
done

exit $RETVAL

