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
export MODIFIED="2022-07-13"
declare -i SCRIPT_RETURN=$SUCCESS

# Define a few more binary variables
for DATA in mysql st host find; do
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

for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --help    | -h)     declare -i BOL_HELP=$TRUE;;
    --debug   | -d)     declare -i BOL_VERBOSE=$TURE;   declare -i BOL_QUIET=$FALSE;    export VERBOSE="-v";;
    --verbose | -v)     declare -i BOL_VERBOSE=$TURE;   declare -i BOL_QUIET=$FALSE;    export VERBOSE="-v";;
    --quiet   | -q)     declare -i BOL_VERBOSE=$FALSE;  declare -i BOL_QUIET=$TRUE;     export VERBOSE="";                declare -i BOL_DEBUG=$FALSE;;
    --color)            declare -i BOL_COLOR=$TRUE;;
    --bw)               declare -i BOL_COLOR=$FALSE;;
    --version)		declare -i BOL_VERSION=$TRUE;;
    --size=*)           declare -i SIZE=${OPTIONS#*=};;
    --password=*)       export PASSWORD=${OPTIONS#*=};;
    --username=*)       export USERNAME="${OPTIONS#*=}";;
    --cfg-file=*)       export CFG_FILE="${OPTIONS#*=}";;
    --cutoff=*)         export CUTOFF="${OPTIONS#*=}";;
  esac
done

if [ ${#BOL_VERSION}	-eq 0 ]; then declare -i BOL_VERSION=$FALSE;							fi
if [ ${#BOL_COLOR}	-eq 0 ]; then declare -i BOL_COLOR=$TRUE;							fi
if [ $BOL_COLOR     -eq $TRUE ]; then INIT_COLOR_SHORTHAND;								fi
if [ ${#USERNAME}       -eq 0 ]; then export USERNAME="root";								fi
if [ ${#PASSWORD}       -eq 0 ]; then export PASSWORD="Thund3rstruck!"							fi
if [ ${#YESTERDAY}	-eq 0 ]; then export YESTERDAY=$(date  --date="2 days ago" +"%Y-%m-%d");			fi
if [ ${#CUTOFF}		-eq 0 ]; then export CUTOFF="$YESTERDAY";							fi
if [ $BOL_VERSION   -eq $TRUE ]; then SHOW_HEADER; exit $SUCCESS;	 						fi
echo "PURGE BINARY LOGS BEFORE '"$CUTOFF"';" | $MYSQL_BIN --progress-reports --user="$USERNAME" --password="$PASSWORD"; fi