#! /bin/bash
### By: Peter Talbott 2019-08-15
### Modified 2020-01-04

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
export VERSION="0.2"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $SUCCESS
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { app1 app2 app3  } --help"
    exit $SUCCESS
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Executable Binaries
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export LSMOD_BIN="$BIN_PREFIX/lsmod"
export GREP_BIN="$BIN_PREFIX/egrep"
export APT_BIN="$USER_PREFIX$BIN_PREFIX/apt"
export MODPROBE_BIN="$SBIN_PREFIX/modprobe"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export FALSE_BIN="$BIN_PREFIX/false"

# Define String Variables
export VERBOSE=""
export INSTALLED=""
export LIST="list"
export EXCLUDE_OPT="i386"

# Define Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_WAIT=1
declare -ig EXITVAL=$FAILURE
declare -ig CMDLINE_INDEX=-1

# Define Global Arrays
declare -ag APP_ARRAY=();

function GET_LIST()
{
  declare -i RETVAL=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Parsing Output From: ($APT_BIN $LIST $INSTALLED 2>/dev/null | $GREP_BIN -v $EXCLUDE_OPT | $GREP_BIN $TEMP_APP)"; fi
  while IFS= read -r line; do
    DATA="${line%%/*}"
    echo -e "$DATA"
  done< <($APT_BIN $LIST $INSTALLED 2>/dev/null | $GREP_BIN -v "$EXCLUDE_OPT" | $GREP_BIN "$TEMP_APP")
  RETVAL=$?
  return $RETVAL
}

function do_HELP()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [Package Name]\n"
  printf "%-26s:\t%-48s\n" "[Package Name]" "Search Apt For Packages Matching [Package Name]"
  printf "%-26s:\t%-48s\n" "-d  or --debug" "Show Debug Information"
  printf "%-26s:\t%-48s\n" "-h  or --help" "Show This Help Section"
  printf "%-26s:\t%-48s\n" "-i  or --installed" "Only Display Packages If They Are Installed"
  printf "%-26s:\t%-48s\n" "-ni or --not-installed" "Only Display Packages If They Are NOT Installed"
  printf "%-26s:\t%-48s\n" "-t  or --test" "Run Through All The Steps But Dont Execute Them"
  printf "%-26s:\t%-48s\n" "-v  or --verbose" "Output More Details"
  printf "%-26s:\t%-48s\n\n" '--ignore="[Package Name]"' "Ignore Any Results Matching [Package Name]"
  exit $SUCCESS
};

for i in "$@"
do
case $i in
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export MODPROBE_BIN=$FALSE_BIN
	export APT_BIN=$FALSE_BIN
	export GREP_BIN=$FALSE_BIN
	;;
'-i' | '--installed')
	export INSTALLED="--installed"
	;;
'-ni' | '--not-installed')
	export EXCLUDE_OPT="$EXCLUDE_OPT|installed"
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_DEBUG=$TRUE
        ;;
--ignore=*)
        export EXCLUDE_OPT="$EXCLUDE_OPT|${i#*=}"
	;;
-w=* | --wait=*)
        X="${i#*=}"
        export VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
*)
        (( CMDLINE_INDEX++ ))
	APP_ARRAY[$((CMDLINE_INDEX))]="$i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

for DATA in ${APP_ARRAY[@]}; do
  export TEMP_APP="$DATA"
  GET_LIST
  EXITVAL=$?
done

exit $EXITVAL
