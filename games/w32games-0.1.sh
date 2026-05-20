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
export MODIFIED="2022-05-20"
export CURRENT_PREFIX="$(pwd)"
declare -i RETVAL=$SUCCESS

if [ ${#WINE_BIN}	-eq 0 ]; then export TEMP="wine";   export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;      fi
if [ ${#XRANDR_BIN}     -eq 0 ]; then export TEMP="xrandr"; export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;      fi

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
    --verbose | -v)	declare -i BOL_VERBOSE=$TRUE;;
    --help | -h)	declare -i BOL_HELP=$TRUE;;
    --game-prefix=*)	export GAME_PREFIX="${OPTIONS#*=}";;
    --game-bin=*)	export GAME_BIN="${OPTIONS#*=}";;
    --gfx-output=*)	export GFX_OUTPUT="${OPTIONS#*=}";;
    --resolution=*)	export RESOLUTION="${OPTIONS#*=}";;
    --cfg-prefix=*)	export CONFIG_PREFIX="${OPTIONS#*=}";;
    --cfg-file=*)	export CFG_FILE="${OPTIONS#*=}";;
    --wine-arch=*)	export WINEARCH="${OPTIONS#*=}";;
    --wine-prefix=*)	export WINEPREFIX="/opt/usr/wine32";;
    --debug)		declare -i BOL_DEBUG=$TRUE;		export WINEDEBUG="-all";;
    --allow-root)	declare -i BOL_ALLOW_ROOT=$TRUE;;
    --version)		SHOW_HEADER;				exit $SUCCESS;;
    *)			export CFG_FILE="$OPTIONS.cfg";;
  esac
done
SHOW_HEADER
if [ ${#BOL_VERBOSE}				-eq 0 	  ]; then declare -i BOL_VERBOSE=$FALSE;									fi
if [ ${#BOL_HELP}				-eq 0 	  ]; then declare -i BOL_HELP=$FALSE;										fi
if [ ${#BOL_ALLOW_ROOT}				-eq 0 	  ]; then declare -i BOL_ALLOW_ROOT=$FALSE;									fi
if [ ${#CONFIG_PREFIX}				-eq 0 	  ]; then export CONFIG_PREFIX='/etc/w32configs';								fi
if [ $BOL_VERBOSE                          -eq $TRUE  	  ]; then echo -e  "CFG Prefix:\t\t$CONFIG_PREFIX";								fi
if [ ${#CFG_FILE}				-ne 0 	  ]; then export TEMP_FILE="$CONFIG_PREFIX"'/'"$CFG_FILE"; CFG_FILE="$TEMP_FILE";				fi
if [ ${#WINEARCH}				-eq 0 	  ]; then export WINEARCH="win32";										fi
if [ ${#WINEPREFIX}				-eq 0 	  ]; then export WINEPREFIX="/opt/usr/wine32";									fi
if [ $(id -u) -eq 0 ] && [ $BOL_ALLOW_ROOT -eq $FALSE 	  ]; then echo -e "Error: $RUN_CMD Version $VERSION Cannot be ran as ROOT user!"; exit $FAILURE;		fi
if [ $BOL_VERBOSE			   -eq $TRUE  	  ]; then echo -e "Loading config file:\t$CFG_FILE";								fi
if [ -f "$CFG_FILE"				      	  ]; then . "$CFG_FILE";											fi
if [ ${#GAME_PREFIX}	-ne 0 ]; then cd "$GAME_PREFIX"; else echo -e "Error: GAME_PREFIX not defined"; cd "$CURRENT_PREFIX"; exit $FAILURE;				fi
if [ $BOL_VERBOSE                          -eq $TRUE  	  ]; then echo -e "Wine Binary:\t\t$WINE_BIN";									fi
if [ $BOL_VERBOSE -eq $TRUE ] && [ ${#GAME_BIN} -ne 0	  ]; then echo -e "Game Binary:\t\t$GAME_BIN";									fi
if [ ${#GAME_PREFIX} -ne 0 ] && [ $BOL_VERBOSE -eq $TRUE  ]; then echo -e "Game Prefix:\t\t$(pwd)";									fi
if [ ${#GAME_BIN} -ne 0 ]; then $WINE_BIN $GAME_BIN; RETVAL=$?; else echo -e "Error: No Game Binary Defined"; cd "$CURRENT_PREFIX"; exit $FAILURE;			fi
if [ ${#CURRENT_PREFIX}				-ne 0 	  ]; then cd "$CURRENT_PREFIX";											fi
if [ ${#GFX_OUTPUT} -ne 0 ] && [ ${#RESOLUTION} -ne 0     ]; then $XRANDR_BIN --output $GFX_OUTPUT --mode $RESOLUTION;							fi

exit $RETVAL
