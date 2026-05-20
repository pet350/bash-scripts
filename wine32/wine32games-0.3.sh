#! /bin/bash
# Simple Script to run WINE Games in  true 32-Bit Architecture and prefix Directory
# By Peter Talbott

VERSION=0.3

# Define Global TRUE/FALSE Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define Global SUCCESS/FAILURE Variables
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Arrays
declare -ag GAME_NAME_ARRAY=();
declare -ag GAME_PATH_ARRAY=();
declare -ag GAME_EXEC_ARRAY=();
declare -ag GAME_OPTS_ARRAY=();
declare -ag GAME_SHORT_NAME_ARRAY=();

# Define Global Integer Variables
declare -ig GAME_NAME_ARRAY_COUNT=0
declare -ig GAME_PATH_ARRAY_COUNT=0
declare -ig GAME_EXEC_ARRAY_COUNT=0
declare -ig GAME_OPTS_ARRAY_COUNT=0
declare -ig GAME_SHORT_NAME_ARRAY_COUNT=0
declare -ig GAME_READ_COUNT=0
declare -ig VAR_UNKNOWN=0
declare -ig ID_INDEX=-1

# Define Global Boolean Variables
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_UNKNOWN=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_VERBOSE_DEBUG=$FALSE
declare -ig BOL_NEW_LINE=$FALSE
declare -ig BOL_LIST_GAME_NAME=$FALSE
declare -ig BOL_LIST_GAME_PATH=$FALSE
declare -ig BOL_LIST_GAME_EXEC=$FALSE
declare -ig BOL_LIST_GAME_OPTS=$FALSE
declare -ig BOL_LIST_GAME_SHORT_NAME=$FALSE
declare -ig BOL_FOUND_GAME_NAME=$FALSE
declare -ig BOL_FIND_GAME_NAME=$FALSE

# Define String Variables
export RUN_CMD="$(basename $0)"
export CONFIG_PREFIX="/usr/local/share/games.d"
export WINEARCH="win32"
export WINEPREFIX="/opt/usr/wine32"
export WINEDEBUG="-all"
export BINPREFIX="/usr/bin"
export WINEBIN="$BINPREFIX/wine"
export VERBOSE=""

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Cannot be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD { --id="##" | --list | --help }"
  exit $FAILURE
fi

# Check To See If Configuration Directoy Exists
if [ ! -d $CONFIG_PREFIX ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Configuration Directory $CONFIG_PREFIX Does Not Exist!"
  exit $FAILURE
fi

# Check To See If There Are Any Files In The Configuration Directoy
if [ $( ls -1 $CONFIG_PREFIX | wc -l) -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: No Config Files Found In $CONFIG_PREFIX!"
  exit $FAILURE
fi

function PARSE_DATA()
{
  declare -i RETVAL=$FAILURE
  TEMP_DATA=""
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA]\t\tREAD_DATA: $READ_DATA"; fi
  case $READ_DATA in
  GAME-TITLE=* | game-title=*)
    TEMP_DATA="${READ_DATA#*=}"
    GAME_NAME_ARRAY[$((READ_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
    if [ $BOL_VERBOSE_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA] [VERBOSE]\tGAME_NAME_ARRAY(READ_INDEX): ${GAME_NAME_ARRAY[$((READ_INDEX))]}"; fi
    RETVAL=$SUCCESS
    ;;
  GAME-PATH=* | game-path=*)
    TEMP_DATA="${READ_DATA#*=}"
    GAME_PATH_ARRAY[$((READ_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
    if [ $BOL_VERBOSE_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA] [VERBOSE]\tGAME_PATH_ARRAY(READ_INDEX): ${GAME_PATH_ARRAY[$((READ_INDEX))]}"; fi
    RETVAL=$SUCCESS
    ;;
  GAME-BINARY=* | game-binary=*)
    TEMP_DATA="${READ_DATA#*=}"
    GAME_EXEC_ARRAY[$((READ_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
    if [ $BOL_VERBOSE_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA] [VERBOSE]\tGAME_EXEC_ARRAY(READ_INDEX): ${GAME_EXEC_ARRAY[$((READ_INDEX))]}"; fi
    RETVAL=$SUCCESS
    ;;
  GAME-OPTIONS=* | game-options=*)
    TEMP_DATA="${READ_DATA#*=}"
    GAME_OPTS_ARRAY[$((READ_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
    if [ $BOL_VERBOSE_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA] [VERBOSE]\tGAME_OPTS_ARRAY(READ_INDEX): ${GAME_OPTS_ARRAY[$((READ_INDEX))]}"; fi
    RETVAL=$SUCCESS
    ;;
  GAME-SHORT-NAME=* | game-short-name=*)
    TEMP_DATA="${READ_DATA#*=}"
    GAME_SHORT_NAME_ARRAY[$((READ_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
    if [ $BOL_VERBOSE_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [PARSE_DATA] [VERBOSE]\tGAME_SHORT_NAME_ARRAY(READ_INDEX): ${GAME_SHORT_NAME_ARRAY[$((READ_INDEX))]}"; fi
    RETVAL=$SUCCESS
    ;;
  *)
    ((VAR_UNKNOWN++))
    RETVAL=$FAILURE
    ;;
  esac
  return $RETVAL
};

function READ_CONFIG_FILES()
{
  declare -i RETVAL=$FAILURE
  declare -i READ_INDEX=-1
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [READ_CONFIG_FILES]\tCONFIG_PREFIX: $CONFIG_PREFIX"; fi
  for FILE_LIST in $(ls -1 $CONFIG_PREFIX); do
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [READ_CONFIG_FILES]\tFILE_LIST: $FILE_LIST"; fi
    ((READ_INDEX++))
    while IFS= read -r line; do
      export READ_DATA="$line"
      PARSE_DATA
    done < <(cat $CONFIG_PREFIX/$FILE_LIST)
  done
  GAME_NAME_ARRAY_COUNT=${#GAME_NAME_ARRAY[@]}
  GAME_PATH_ARRAY_COUNT=${#GAME_PATH_ARRAY[@]}
  GAME_EXEC_ARRAY_COUNT=${#GAME_EXEC_ARRAY[@]}
  GAME_OPTS_ARRAY_COUNT=${#GAME_OPTS_ARRAY[@]}
  GAME_SHORT_NAME_ARRAY_COUNT=${#GAME_SHORT_NAME_ARRAY[@]}
  GAME_READ_COUNT=$((READ_INDEX))
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] [READ_CONFIG_FILES]\tGAME_READ_COUNT: $GAME_READ_COUNT"; fi
  return $READ_INDEX
};

function LIST_GAME_INFO()
{
  declare -i INDEX=-1
  while [ $((INDEX)) -lt $((GAME_READ_COUNT)) ]; do
    ((INDEX++))
    if [ $BOL_LIST_GAME_NAME -eq $TRUE ]; then echo -e "ID: $INDEX\tGame Title:\t${GAME_NAME_ARRAY[$((INDEX))]}"; fi
    if [ $BOL_LIST_GAME_SHORT_NAME -eq $TRUE ]; then echo -e "\tShort Name:\t${GAME_SHORT_NAME_ARRAY[$((INDEX))]}"; fi
    if [ $BOL_LIST_GAME_PATH -eq $TRUE ]; then echo -e "\tDirectory:\t${GAME_PATH_ARRAY[$((INDEX))]}"; fi
    if [ $BOL_LIST_GAME_EXEC -eq $TRUE ]; then echo -e "\tExecutable:\t${GAME_EXEC_ARRAY[$((INDEX))]}"; fi
    if [ $BOL_LIST_GAME_OPTS -eq $TRUE ]; then echo -e "\tOptions:\t${GAME_OPTS_ARRAY[$((INDEX))]}"; fi
    if [ $BOL_NEW_LINE -eq $TRUE ]; then echo -e " "; fi
  done
  return $SUCCESS
};

function FIND_GAME_NAME()
{
  declare -i INDEX=-1
  declare -i RETVAL=$FAILURE
  while [ $((INDEX)) -lt $((GAME_READ_COUNT)) ]; do
    ((INDEX++))
    if [ "$PARSED_NAME" == "${GAME_SHORT_NAME_ARRAY[$((INDEX))]}" ]; then
	export BOL_RUN=$TRUE
	export BOL_FOUND_GAME_NAME=$TRUE
	export ID_INDEX=$((INDEX))
	RETVAL=$SUCCESS
    fi
  done
  return $RETVAL
};

function RUN_GAME()
{
  cd "${GAME_PATH_ARRAY[$((ID_INDEX))]}"
  echo -e "Starting Game: ${GAME_NAME_ARRAY[$((ID_INDEX))]} " "${GAME_OPTS_ARRAY[$((ID_INDEX))]}"
  $WINEBIN "${GAME_EXEC_ARRAY[$((ID_INDEX))]}" "${GAME_OPTS_ARRAY[$((ID_INDEX))]}"
  return $?
};

function do_HELP()
{
  printf "$RUN_CMD Version $VERSION\nHelp Section!\n\n"
  printf "%-15s\t%-25s\n" "--id=##  | --ID=##" "Run Game With Corrisponding ID# (Ex: --ID=3)"
  printf "%-15s\t%-25s\n\n" "--name=* | --NAME=*" "Run Game With Corrisponding Short Name (Ex: --NAME=Solitare)"
  printf "%-15s\t\t%-25s\n" "-h  or --help" "Disply This Help Message"
  printf "%-15s\t%-25s\n\n" "-v  or --verbose" "Be Verbose"
  printf "%-15s\t\t%-25s\n" "-d  or --debug" "Display Debug Info"
  printf "%-15s\t%-25s\n\n" "-dd or --verbose-debug" "Display Verbose Debug Info"
  printf "%-15s\t\t%-25s\n" "--list" "List Game Titles"
  printf "%-15s\t\t%-25s\n" "--list-all" "List Game Title, Short Name, Path, Executable and Options"
  printf "%-15s\t\t%-25s\n" "--list-short" "List Game Title and Short Name"
  printf "%-15s\t\t%-25s\n" "--list-path" "List Game Title and Path"
  printf "%-15s\t\t%-25s\n" "--list-exec" "List Game Title and Executable"
  printf "%-15s\t\t%-25s\n" "--list-opts" "List Game Title and Options"
  echo -e ""
  return $SUCCESS
};

for i in "$@"
do
case $i in
--ID=* | --id=*)
	TEMP="${i#*=}"
	export BOL_RUN=$TRUE
	export ID_INDEX=$((TEMP))
	;;
--NAME=* | --name=*)
	TEMP="${i#*=}"
	export BOL_FIND_GAME_NAME=$TRUE
	export PARSED_NAME="$TEMP"
	;;
'--list-all')
        export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_PATH=$TRUE
        export BOL_LIST_GAME_EXEC=$TRUE
        export BOL_LIST_GAME_OPTS=$TRUE
	export BOL_LIST_GAME_SHORT_NAME=$TRUE
	export BOL_NEW_LINE=$TRUE
        ;;
'--list-short')
        export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_SHORT_NAME=$TRUE
        export BOL_NEW_LINE=$TRUE
        ;;
'--list-path')
        export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_PATH=$TRUE
        export BOL_NEW_LINE=$TRUE
        ;;
'--list-exec')
        export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_EXEC=$TRUE
        export BOL_NEW_LINE=$TRUE
        ;;
'--list-opts')
        export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_OPTS=$TRUE
        export BOL_NEW_LINE=$TRUE
        ;;
'--list')
	export BOL_RUN=$FALSE
        export BOL_LIST_GAME_NAME=$TRUE
        export BOL_LIST_GAME_PATH=$((BOL_LIST_GAME_PATH))
        export BOL_LIST_GAME_EXEC=$((BOL_LIST_GAME_EXEC))
        export BOL_LIST_GAME_OPTS=$((BOL_LIST_GAME_OPTS))
        export BOL_LIST_GAME_SHORT_NAME=$((BOL_LIST_GAME_SHORT_NAME))
        export BOL_NEW_LINE=$((BOL_NEW_LINE))
        ;;
'-d' | '--debug')
	export BOL_DEBUG=$TRUE
	;;
'-dd' | '--verbose-debug')
	export BOL_DEBUG=$TRUE
	export BOL_VERBOSE_DEBUG=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
        export BOL_UNKNOWN=$TRUE
	echo -e "$RUN_CMD Version $VERSION\nUnknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
  do_HELP
  exit $FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
  exit $VAR_UNKNOWN
fi

READ_CONFIG_FILES

if [ $BOL_FIND_GAME_NAME -eq $TRUE ]; then
  FIND_GAME_NAME
  RETVAL=$?
  if [ $RETVAL -eq $SUCCESS ]; then
    BOL_RUN=$TRUE
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Game Found:\t$PARSED_NAME"; fi
  else
    BOL_RUN=$FALSE
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "NOT Found:\t$PARSED_NAME"; fi
  fi
fi

if [ $BOL_LIST_GAME_NAME -eq $TRUE ]; then
  BOL_RUN=$FALSE
  LIST_GAME_INFO
  RETVAL=$?
fi

if [ $BOL_RUN -eq $TRUE ]; then
  RUN_GAME
  RETVAL=$?
  xrandr -s 1366x768
fi

exit $RETVAL
