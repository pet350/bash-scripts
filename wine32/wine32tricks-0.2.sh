#! /bin/bash
# Simple Script to run WINETRICKS in true 32-Bit Architecture and prefix Directory

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

export VERSION=0.2
export RUN_CMD="$(basename $0)"
export WINEARCH="win32"
export WINEPREFIX="/opt/wine32"
export WINEDEBUG="-all"
export BINPREFIX="/usr/bin"
export WINEBIN="$BINPREFIX/winetricks"

declare -ag SCRIPT_OPTIONS=();
declare -ig SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]}
declare -ig BOL_ALLOW_ROOT=$FALSE

for ARGS in "$@"; do
  case $ARGS in
    -h | --help)	export BOL_HELP=$TRUE;		export VERBOSE="";		export BOL_DEBUG=$FALSE;	export BOL_VERBOSE=$FALSE;	export BOL_LOG_RESULTS=$FALSE;;
    -d | --debug)	export VERBOSE="--verbose";	export BOL_DEBUG=$TRUE;		export BOL_VERBOSE=$TRUE;	export BOL_LOG_RESULTS=$TRUE;;
    -v | --verbose) 	export VERBOSE="--verbose";	export BOL_VERBOSE=$TRUE;	export BOL_LOG_RESULTS=$TRUE;;
    -q | --quiet)	export VERBOSE="";	export BOL_VERBOSE=$FALSE;	export BOL_LOG_RESULTS=$FALSE;;
    --allow-root)	export BOL_ALLOW_ROOT=$TRUE;;
    --version)		echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott";	exit $SUCCESS;;
    --bw)		export BOL_COLOR=$FALSE;;
    --color)		export BOL_COLOR=$TRUE;;
    *)			SCRIPT_OPTION_COUNT=${#SCRIPT_OPTIONS[@]};	SCRIPT_OPTIONS[$((SCRIPT_OPTION_COUNT))]="$ARGS";;
  esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi
if [ $BOL_ALLOW_ROOT -eq $FALSE ]; then REQUIRE_NON_ROOT_USER; fi

$WINEBIN ${SCRIPT_OPTIONS[@]}
RETVAL=$?

exit $RETVAL
