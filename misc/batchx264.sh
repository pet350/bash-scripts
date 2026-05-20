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
export VERSION="0.2.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEMP=$FALSE
declare -ig BOL_FILENAME=$FALSE
declare -ig BOL_PATH=$FALSE
declare -ig BOL_LOG_RESULTS=$TRUE

# Define Global Boolean Variables IF their not already set by environment
if [ ${#BOL_DEBUG}	-eq 0 ]; then	declare -ig BOL_DEBUG=$TRUE;	fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then	declare -ig BOL_VERBOSE=$TRUE;	fi
if [ ${#BOL_WAIT}	-eq 0 ]; then	declare -ig BOL_WAIT=$TRUE;	fi
if [ ${#BOL_RENAME}	-eq 0 ]; then	declare -ig BOL_RENAME=$TRUE;	fi

# Define Global SYSCTL Boolean Variables
declare -ig BOL_COLOR=$TRUE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_FFMPEG=$FALSE
declare -ig BOL_ENABLE_ROOT=$FALSE


# Define Global Integer Variables
declare -i  RETVAL=$SUCCESS
declare -ig EXIT_VAL=$RETVAL
declare -ig CMD_LINE_COUNT=$#
declare -ig INDEX_VAL=-1
declare -ig PATH_INDEX=-1
declare -ig VAR_WAIT=1
declare -ag FIND_PATH=();

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export LOCAL_PREFIX="/local"

# Define Binary Variables
export FIND_BIN="$USER_PREFIX$BIN_PREFIX/find"
export MENCODER_BIN="$USER_PREFIX$BIN_PREFIX/mencoder"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export FFMPEG_BIN="$USER_PREFIX$BIN_PREFIX/ffmpeg"
export TEST_BIN="$BIN_PREFIX/true"

export X264_SUFFIX="[x264]"
export X264_EXT_SUFFIX="[x264 and xvid]"
export ENCODE_SCRIPT="$USER_PREFIX$LOCAL_PREFIX$SBIN_PREFIX/encode.sh"

declare -ag SCRIPT_OPTIONS=("--ffmpeg" "--verbose" "--debug" "--veryfast");

function APPEND_OPTIONS()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i OPT_COUNT=0
  if [ ${#ADDITIONAL_OPTIONS} -gt 0 ]; then
    FUNCTION_RETURN=$SUCCESS
    for WORD in $ADDITIONAL_OPTIONS; do
        OPT_COUNT=${#SCRIPT_OPTIONS[@]}
        SCRIPT_OPTIONS[$((OPT_COUNT))]="$WORD"
    done
  fi
  return $FUNCTION_RETURN
};

function initialize_color()
{
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Enabling Colorized Text Output"; fi
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
	return $SUCCESS
};

function CHECK_CMD_LINE()
{
  if [ $CMD_LINE_COUNT -eq 0 ]; then
    echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: $VERSION"$COLOR_LT_GREEN"\nUsage:"$COLOR_LT_BLUE" $RUN_CMD [options] --help\n"$COLOR_NORMAL
    exit $SUCCESS
  fi
  return $SUCCESS
};


function CHECK_ROOT_USER()
{
  if [ $(id -u) -eq 0 ]; then
    SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
    SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="--enable-root"
  fi
  return $SUCCESS
};

function CHECK_PREFIX()
{
  declare -i PREFIX_LENGTH=${#X264_PREFIX}
  declare -i RETVAL=$FAILURE

  TEST_SUFFIX="${X264_PREFIX:((PREFIX_LENGTH-6)):6}"
  TEST_EXT_SUFFIX="${X264_PREFIX:((PREFIX_LENGTH-15)):15}"
  if [ "$TEST_SUFFIX" == "$X264_SUFFIX" ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" $X264_SUFFIX Suffix detected at the end of $X264_PREFIX\n\n"$COLOR_NORMAL; fi
    RETVAL=$SUCCESS
  elif [ "$TEST_EXT_SUFFIX" == "$X264_EXT_SUFFIX" ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" $X264_EXT_SUFFIX Suffix detected at the end of $X264_PREFIX\n\n"$COLOR_NORMAL; fi
    RETVAL=$SUCCESS
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" $X264_SUFFIX Suffix not detected at the end of $X264_PREFIX\n\n"$COLOR_NORMAL; fi
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function FILE_LOOP()
{
  declare -i SCRIPT_RETVAL=$FAILURE
  declare -i FILE_COUNT=0
  while IFS= read FILE_DATA; do
    export TARGET_FILENAME="${FILE_DATA#*/}"
    ((FILE_COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" Found Filename: $TARGET_FILENAME. Filename Count / Prefix Count: $FILE_COUNT / $PREFIX_COUNT"$COLOR_NORMAL; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" Execuiting: $ENCODE_SCRIPT --file=$TARGET_FILENAME --path=$X264_PREFIX ${SCRIPT_OPTIONS[@]}"$COLOR_NORMAL; fi
    $ENCODE_SCRIPT --file="$TARGET_FILENAME" --path="$X264_PREFIX" ${SCRIPT_OPTIONS[@]}
    SCRIPT_RETVAL=$?
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" $ENCODE_SCRIPT Return Value: $SCRIPT_RETVAL"$COLOR_NORMAL; fi
  done < <(find "$X264_PREFIX" -name "$FIND_FILE")
  return $SCRIPT_RETVAL
};

function PATH_LOOP()
{
  declare -i FUNCTION_RETVAL=$SUCCESS
  declare -i FILE_LOOP_RETVAL=$SUCCESS
  declare -i CHECK_PREFIX_RETVAL=$SUCCESS
  declare -i PREFIX_COUNT=0
  while IFS= read PREFIX_DATA; do
    export X264_PREFIX="$PREFIX_DATA"
    ((PREFIX_COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" Found Path Prefix: $X264_PREFIX. Prefix Count: $PREFIX_COUNT"$COLOR_NORMAL; fi
    FILE_LOOP
    FILE_LOOP_RETVAL=$?
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" File Loop Return Value: $FILE_LOOP_RETVAL"$COLOR_NORMAL; fi
    if [ $FILE_LOOP_RETVAL -eq $FAILURE ]; then FUNCTION_RETVAL=$FAILURE; fi
    CHECK_PREFIX
    CHECK_PREFIX_RETVAL=$?
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" Check Prefix Return Value: $CHECK_PREFIX_RETVAL"$COLOR_NORMAL; fi
    if [ $CHECK_PREFIX_RETVAL -eq $FAILURE ]; then
      if [ $FILE_LOOP_RETVAL -eq $SUCCESS ]; then
        if [ $BOL_TEST -ne $TRUE ] && [ $BOL_RENAME -eq $TRUE ]; then
          printf $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE; mv -v "$X264_PREFIX" "$X264_PREFIX $X264_SUFFIX"; echo -e $COLOR_NORMAL
        else
          echo -e $COLOR_LT_GREEN"[$RUN_CMD]"$COLOR_LT_BLUE" --test and/or --no-rename option used, Not adding suffix: $X264_SUFFIX"$COLOR_NORMAL
        fi
      fi
    fi
  done < <(ls -Nd1 $FIND_PREFIX)
  return $FUNCTION_RETVAL
};

function do_HELP()
{
  echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_YELLOW"\tVersion: $VERSION"$COLOR_LT_BLUE"\nUsage: $RUN_CMD [options]\n"$COLOR_NORMAL
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--help" "Show This Help Section" "--debug" "Show Debug Information"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--verbose" "Output More Details" "--quiet" "Don't Output Anything"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--file=<name>" "File Name or Pattern" "--path=<path>" "Search Path <path>"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--test" "Enable Test Mode" "--copy-audio" "Copy, do not encode audio stream"
  echo -e "\n"
  exit $SUCCESS
};


for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
        export BOL_LOG_RESULTS=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
        export BOL_LOG_RESULTS=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_DEBUG=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	;;
'--copy-audio')
        SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
        SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="--copy-audio"
	;;
'-t' | '--test')
	SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
	SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="--test"
	export BOL_TEST=$TRUE
	export MENCODER_BIN="$TEST_BIN"
	export FFMPEG_BIN="$TEST_BIN"
	;;
--file=*)
	export BOL_FILENAME=$TRUE
        export FIND_FILE="${i#*=}"
	;;
--path=*)
	export BOL_PATH=$TRUE
        export FIND_PREFIX="${i#*=}"
        ;;
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
'--mp3-audio')
	export ADDITIONAL_OPTIONS="-c:a libmp3lame -q:a 2"
	APPEND_OPTIONS
	;;
'--no-rename')
	export BOL_RENAME=$FALSE
	;;
'--rename')
	export BOL_RENAME=$TRUE		## Default in this version
	;;
*)
	SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
        SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then initialize_color; fi
CHECK_CMD_LINE

if [ $BOL_FILENAME -ne $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_PATH -ne $TRUE ]; then export FIND_PREFIX='*'; fi
if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

CHECK_ROOT_USER
if [ $BOL_DEBUG -eq $TRUE ]; then
  echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" Initial Script Options: ${SCRIPT_OPTIONS[@]}"$COLOR_NORMAL
  echo -e $COLOR_LT_GREEN"[$RUN_CMD] "$COLOR_YELLOW"[Debug]"$COLOR_LT_RED" Start Loop By Executing: ls -Nd1 $FIND_PREFIX"$COLOR_NORMAL
  echo -e $COLOR_YELLOW; ls -Nd1 $FIND_PREFIX; echo -e $COLOR_NORMAL
fi
PATH_LOOP
exit $?
