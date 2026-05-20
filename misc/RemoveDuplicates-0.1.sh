#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
if [ -f /lib/lsb/init-functions ]; then
  source /lib/lsb/init-functions
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_PATH=$FALSE
declare -ig BOL_COLOR=$TRUE

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USR_PREFIX="/usr"

declare -ig EXIT_VAL=$SUCCESS
declare -ag MSG=('Checking File:' 'File Count:' 'of' '[Debug]');
declare -ag EXT_ARRAY=('jpg' 'jpeg' 'gif' 'bmp' 'tiff' 'png');
declare -ag PREFIX_ARRAY=();
declare -ag PREFIX_ARRAY_COUNT=${#PREFIX_ARRAY[@]}

# Define Binary Variables
export DIFF_BIN="$BIN_PREFIX/diff"

# Define Option Variables
export DEV_NULL="/dev/null"
export SEARCH_PREFIX=""

function PATH_ARRAY_BY_LINE()
{
  declare -i INDEX=-1
  while [ $INDEX -lt $PREFIX_ARRAY_COUNT ]; do
    ((INDEX++))
    echo -e "${PREFIX_ARRAY[$((INDEX))]}"
  done
  return $INDEX
};

function INIT_COLORS()
{
	export COLOR_NORMAL="\033[0m"
	export COLOR_BLACK="\033[0;30m"
	export COLOR_RED="\033[0;31m"
	export COLOR_GREEN="\033[0;32m"
	export COLOR_ORANGE="\033[0;33m"
	export COLOR_BLUE="\033[0;34m"
	export COLOR_PURPLE="\033[0;35m"
	export COLOR_CYAN="\033[0;36m"
	export COLOR_LT_GRAY="\033[0;37m"
	export COLOR_DK_GRAY="\033[1;30m"
	export COLOR_LT_RED="\033[1;31m"
	export COLOR_LT_GREEN="\033[1;32m"
        export COLOR_YELLOW="\033[1;33m"
        export COLOR_LT_BLUE="\033[1;34m"
        export COLOR_LT_PURPLE="\033[1;35m"
        export COLOR_LT_CYAN="\033[1;36m"
        export COLOR_WHITE="\033[1;37m"
};

function RUN_DUP_CHECK()
{
  GET_LONGEST_LENGTH
  declare -ig FILE_LEN=$?
  declare -ig TOTAL_COUNT=$(find "$SEARCH_PREFIX" -type f -iname "$SEARCH" | wc -l)
  declare -ig FILE1_COUNT=-1
  declare -ig FILE2_COUNT=-1
  while IFS= read FILE1; do
    ((FILE1_COUNT++))
    FILE2_COUNT=-1
    printf "%b%s " $COLOR_LT_BLUE "${MSG[0]}"
    printf "%b%-$((FILE_LEN))s\t" $COLOR_LT_GREEN "$FILE1"; printf "%b%15s " $COLOR_LT_BLUE "${MSG[1]}"; printf "%b%6s " $COLOR_YELLOW "$FILE1_COUNT"
    printf "%b%3s " $COLOR_LT_BLUE "${MSG[2]}"; printf "%b%-6s " $COLOR_YELLOW "$TOTAL_COUNT"
    printf "%b\n" $COLOR_NORMAL
    while IFS= read FILE2; do
      ((FILE2_COUNT++))
      if [ "$FILE1" != "$FILE2" ]; then
        if [ $BOL_DEBUG -eq $TRUE ]; then printf "%b%6s %b" $COLOR_LT_BLUE "${MSG[3]}" $COLOR_YELLOW; fi
        $DIFF_BIN --report-identical-files "$FILE1" "$FILE2" >$DEV_NULL 2>$DEV_NULL
        if [ $? -eq $SUCCESS ]; then
          echo -e $COLOR_YELLOW"File: "$COLOR_CYAN"$FILE1 "$COLOR_YELLOW"and file: "$COLOR_CYAN"$FILE2 "$COLOR_YELLOW"are the same!"$COLOR_NORMAL
          printf "%b" $COLOR_LT_RED; rm -vf "$FILE2"; printf "%b\n" $COLOR_NORMAL
        fi
        if [ $BOL_DEBUG -eq $TRUE ]; then printf "%b" $COLOR_NORMAL; fi
      fi
    done < <(find "$SEARCH_PREFIX" -type f -iname "$SEARCH")
  done < <(find "$SEARCH_PREFIX" -type f -iname "$SEARCH")
  return $FILE1_COUNT
};

function GET_LONGEST_LENGTH()
{
  declare -i FUNCTION_RETVAL=0
  for DATA in $(find "$SEARCH_PREFIX" -type f -iname "$SEARCH"); do
    if [ ${#DATA} -gt $FUNCTION_RETVAL ]; then FUNCTION_RETVAL=${#DATA}; fi
  done
  return $FUNCTION_RETVAL
};

function DUP_LOOP()
{
  declare -i COUNT=0
  declare LOOP_RETVAL=$SUCCESS
  for DATA in ${EXT_ARRAY[@]}; do
    ((COUNT++))
    export SEARCH="*.$DATA"
    echo -e $COLOR_YELLOW"Searching for "$COLOR_LT_RED"$SEARCH\t"$COLOR_YELLOW"Extention "$COLOR_LT_RED"$COUNT "$COLOR_YELLOW"of "$COLOR_LT_RED"${#EXT_ARRAY[@]}"$COLOR_NORMAL
    RUN_DUP_CHECK
    LOOP_RETVAL=$?
  done
  return $LOOP_RETVAL
};

for i in "$@"; do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
	export DEV_NULL="/dev/stdout"
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
--path=*)
	export BOL_PATH=$TRUE
	PREFIX_ARRAY_COUNT=${#PREFIX_ARRAY[@]}
        PREFIX_ARRAY[$((PREFIX_ARRAY_COUNT))]=./"${i#*=}"
        ;;
*)
	INDEX_VAL=${#EXT_ARRAY[@]}
	EXT_ARRAY[(($INDEX_VAL))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLORS; fi
if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_PATH -eq $TRUE ]; then
  echo -e $COLOR_LT_BLUE"Checking the following paths: "$COLOR_LT_RED
  PATH_ARRAY_BY_LINE
  printf "%b" $COLOR_NORMAL
  while IFS= read TEMP_DATA; do
    export SEARCH_PREFIX="$TEMP_DATA"
    DUP_LOOP
    EXIT_VAL=$?
  done < <(PATH_ARRAY_BY_LINE)
else
  DUP_LOOP
  EXIT_VAL=$?
fi

exit $EXIT_VAL
