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
export VERSION="0.6"

# Define Global SYSCTL Boolean Variables
declare -ig BOL_START=$TRUE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RESTART=$FALSE
declare -ig BOL_RELOAD=$FALSE
declare -ig BOL_STATUS=$FALSE
declare -ig BOL_MASK=$FALSE
declare -ig BOL_UNMASK=$FALSE
declare -ig BOL_ENABLE=$FALSE
declare -ig BOL_DISABLE=$FALSE

function INIT_ARRAYS()
{
  declare -ag SYSCTL_OPTION_ARRAY=(	"stop" "restart" "start" \
					"reload" "status" "mask" \
					"unmask" "enable" "disable");

  declare -ag SYSCTL_ENABLE_ARRAY=(	"$BOL_STOP" "$BOL_RESTART" "$BOL_START" \
					"$BOL_RELOAD" "$BOL_STATUS" "$BOL_MASK" \
					"$BOL_UNMASK" "$BOL_ENABLE" "BOL_DISABLE");
  return ${#SYSCTL_OPTION_ARRAY[@]}
};

declare -ig EXIT_VAL=$SUCCESS
declare -ig INDEX_VAL=-1
declare -ig VAR_WAIT=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { service1 service2 service3  } --help"
    exit $EXIT_VAL
fi

function do_HELP()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { service1 service2 service3  }\n"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--help" "Show This Help Section" "--debug" "Show Debug Information"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--verbose" "Output More Details" "--quiet" "Don't Output Anything"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--wait=X" "Wait X Sec Between Commands" "--no-wait" "Don't Wait Between Commands"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--start" "Enable Start Function" "--no-start" "Don't Enable Start Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--stop" "Enable Stop Function" "--no-stop" "Don't Enable Stop Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--restart" "Enable Restart Function" "--no-restart" "Don't Enable Restart Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--reload" "Enable Reload Function" "--no-reload" "Don't Enable Reload Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--status" "Enable Status Function" "--no-status" "Don't Enable Status Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--mask" "Enable Mask Function" "--no-mask" "Don't Enable Mask Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--unmask" "Enable Unmask Function" "--no-unmask" "Don't Enable Unmask Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--enable" "Enable *Enable* Function" "--no-enable" "Don't Enable *Enable* Function"
  printf "%-12s:\t%-26s\t|\t%-12s:\t%-26s\n" "--disable" "Enable *Disable* Function" "--no-disable" "Don't Enable *Disable* Function"
  echo -e "\n"
  exit $SUCCESS
};

# Define Option Variables
export SYSCTL_OPT=""
export EXT_OPT=""

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT Success!"
  else
    log_failure_msg "$SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT Failure!"
  fi
  return $RETVAL
};

function RUN_SYSCTL()
{
  declare -i RETVAL=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Begin Section: $SYSCTL_BIN $SYSCTL_OPT ${ARGS_ARRAY[@]} $EXT_OPT"; fi
  for DATA in ${ARGS_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT"; fi
    $SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT
    export RETVAL=$?
    if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; echo -e ""; fi
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  done
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "End Section: $SYSCTL_BIN $SYSCTL_OPT ${ARGS_ARRAY[@]} $EXT_OPT"; fi
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then echo -e "*************************************************\n\n"; fi
  return $RETVAL
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
	export BOL_LOG_RESULTS=$FALSE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'--start')
	export BOL_START=$TRUE
	;;
'--stop')
	export BOL_STOP=$TRUE
	;;
'--restart')
	export BOL_RESTART=$TRUE
	;;
'--reload')
	export BOL_RELOAD=$TRUE
	;;
'--status')
	export BOL_STATUS=$TRUE
	;;
'--mask')
	export BOL_MASK=$TRUE
	;;
'--unmask')
	export BOL_UNMASK=$TRUE
	;;
'--enable')
	export BOL_ENABLE=$TRUE
	;;
'--disable')
	export BOL_DISABLE=$TRUE
	;;
'--no-start')
        export BOL_START=$FALSE
        ;;
'--no-stop')
        export BOL_STOP=$FALSE
        ;;
'--no-restart')
        export BOL_RESTART=$FALSE
        ;;
'--no-reload')
        export BOL_RELOAD=$FALSE
        ;;
'--no-status')
        export BOL_STATUS=$FALSE
        ;;
'--no-mask')
        export BOL_MASK=$FALSE
        ;;
'--no-unmask')
        export BOL_UNMASK=$FALSE
        ;;
'--no-enable')
        export BOL_ENABLE=$FALSE
        ;;
'--no-disable')
        export BOL_DISABLE=$FALSE
        ;;
*)
	(( INDEX_VAL++))
	ARGS_ARRAY[(($INDEX_VAL))]="$i"
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

declare -ig INDEX=-1
INIT_ARRAYS

for TEMP_DATA in ${SYSCTL_ENABLE_ARRAY[@]}; do
  ((INDEX++))
  BOL_TEMP=$((TEMP_DATA))
  export SYSCTL_OPT="${SYSCTL_OPTION_ARRAY[$((INDEX))]}"
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] $SYSCTL_OPT Boolean is:\t\t$BOL_TEMP"; fi
  if [ $BOL_TEMP -eq $TRUE ]; then
    RUN_SYSCTL
    TEMP_VAL=$?
    EXIT_VAL=$((EXIT_VAL+TEMP_VAL))
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[DEBUG] SYSCTL Returned:\t\t$TEMP_VAL\n[DEBUG] EXIT Value:\t\t\t$EXIT_VAL\n\n"; fi
  fi
done

export RETVAL=$((EXIT_VAL))
export SYSCTL_BIN="$RUN_CMD"
export SYSCTL_OPT="$@"
export DATA="Results:"
export EXT_OPT=""

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
unset SYSCTL_BIN
unset SYSCTL_OPT
unset DATA
unset EXT_OPT

exit $EXIT_VAL
