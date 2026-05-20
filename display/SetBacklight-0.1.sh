#! /bin/bash
### By: Peter Talbott 2019-07-21

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD --percent=XXX --verbose --help"
    exit 1
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export BL_PREFIX="/sys/class/backlight/intel_backlight"

# Define Binaries
export CAT_BIN="$BIN_PREFIX/cat"

# Define String Values
export MAX_BRIGHTNESS_STRING="$($CAT_BIN $BL_PREFIX/max_brightness)"
export ACTUAL_BRIGHTNESS_STRING="$($CAT_BIN $BL_PREFIX/actual_brightness)"

# Define Integer Variables
declare -ig MAX_BRIGHTNESS=$((MAX_BRIGHTNESS_STRING))
declare -ig ACT_BRIGHTNESS=$((ACTUAL_BRIGHTNESS_STRING))
declare -ig SET_BRIGHTNESS=0
declare -ig VAR_UNKNOWN=0
declare -ig RETVAL=$FAILURE

# Define Boolean Variables
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

for i in "$@"
do
case $i in
'-v' | '--verbose')
        export BOL_VERBOSE=$TRUE
        export VERBOSE="--verbose"
        ;;
-p=* | --percent=*)
        X="${i#*=}"
        declare -i VAR_PERCENT=$((X))
	SET_BRIGHTNESS=$(( MAX_BRIGHTNESS*VAR_PERCENT/100 ))
	export BOL_RUN=$TRUE
        ;;
*)
        (( VAR_UNKNOWN++ ))
        echo -e "Unknown Parameter $i"
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

if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Maximum Brightness:\t$MAX_BRIGHTNESS\nCurrent Brightness:\t$ACT_BRIGHTNESS\n"; fi

if [ $BOL_RUN -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Setting Brightness:\t$SET_BRIGHTNESS\n"; fi
  echo "$SET_BRIGHTNESS" >"$BL_PREFIX/brightness"
  RETVAL=$?
fi

exit $RETVAL
