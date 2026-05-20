#! /bin/bash
## VERY Simple Script to Backup System Files

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

# Define RUN_CMD and VERSION
export RUN_CMD="$(basename $0)"
export VERSION="0.7"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-05-07"

function LOAD_MODULES()
{
  declare -i RETVAL=$SUCCESS
  export COMMAND="$MODPROBE_BIN"

  while IFS= read LINE; do
    $MODPROBE_BIN $VERBOSE $LINE; export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
  done < <(cat $MODFILE)
  return $RETVAL
};

for OPTIONS in $@; do
  case ${OPTIONS,,} in
    'start')            declare -i BOL_START=$TRUE;     declare -i BOL_STOP=$FALSE;;
    'stop')             declare -i BOL_START=$FALSE;    declare -i BOL_STOP=$TRUE;;
    'restart')          declare -i BOL_START=$TRUE;     declare -i BOL_STOP=$TRUE;;
    --help    | -h)     declare -i BOL_START=$FALSE;    declare -i BOL_STOP=$FALSE;     declare BOL_HELP=$TRUE;;
    --verbose | -v)	declare -i BOL_VERBOSE=$TRUE;	export VERBOSE="-v";;
    --debug   | -d)     declare -i BOL_VERBOSE=$TURE;   declare -i BOL_QUIET=$FALSE;    export OUTPUT="/dev/stdout";    export VERBOSE="--verbose";     declare -i BOL_DEBUG=$TRUE;;
  esac
done

if [ ${#BOL_START}		       -eq 0 ]; then declare -i BOL_START=$FALSE;				fi
if [ ${#BOL_STOP}       	       -eq 0 ]; then declare -i BOL_STOP=$FALSE;             			fi
if [ ${#BOL_HELP}       	       -eq 0 ]; then declare -i BOL_HELP=$FALSE;               		 	fi
if [ ${#BOL_VERBOSE}  		       -eq 0 ]; then declare -i BOL_VERBOSE=$FALSE; export VERBOSE='';   	fi
if [ ${#BOL_DEBUG}      	       -eq 0 ]; then declare -i BOL_DEBUG=$FALSE;	              		fi
if [ ${#MODFILE}		       -eq 0 ]; then export MODFILE="/etc/modules";				fi
if [ $BOL_HELP			   -eq $TRUE ]; then do_HELP;	exit $SUCCESS;					fi
if [ $BOL_STOP	         	   -eq $TRUE ]; then UNLOAD_MODULES;						fi
if [ $BOL_START	-eq $TRUE ] && [ -f $MODFILE ]; then LOAD_MODULES;						fi

exit $RETVAL
