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

function COLOR_SHORTHAND()
{
  if [ ${#COLOR_CYAN}           -ne 0 ]; then export CC="$COLOR_CYAN";          else export CC=' ';     fi
  if [ ${#COLOR_NORMAL}		-ne 0 ]; then export CN="$COLOR_NORMAL";	else export CN=' ';	fi
  if [ ${#COLOR_YELLOW}		-ne 0 ]; then export CY="$COLOR_YELLOW";	else export CY=' ';	fi
  if [ ${#COLOR_LT_BLUE}	-ne 0 ]; then export CLB="$COLOR_LT_BLUE";	else export CLB=' ';	fi
  if [ ${#COLOR_LT_GREEN}	-ne 0 ]; then export CLG="$COLOR_LT_GREEN";	else export CLG=' ';	fi
  return $SUCCESS
};

declare -ag INFO_ARRAY=("--help" "Show This Help Section" "\n" "--debug" "Show Debug Information" "\n" "--verbose" "Output More Detail" "\n" "--quiet" "Output Little to Nothing" "\n" \
  "--wait=X" "Wait X Sec Between Commands" "\n" "--no-wait" "Don't Wait Between Commands" "\n"   "--start" "Enable Start Function" "\n" "--no-start" "Don't Enable Start Function" "\n" \
  "--stop" "Enable Stop Function" "\n" "--no-stop" "Don't Enable Stop Function" "\n" "--restart" "Enable Restart Function" "\n" "--no-restart" "Don't Enable Restart Function" "\n" \
  "--reload" "Enable Reload Function" "\n" "--no-reload" "Don't Enable Reload Function" "\n" "--status" "Enable Status Function" "\n" "--no-status" "Don't Enable Status Function" "\n" \
  "--mask" "Enable Mask Function" "\n" "--no-mask" "Don't Enable Mask Function" "\n" "--unmask" "Enable Unmask Function" "\n" "--no-unmask" "Don't Enable Unmask Function" "\n" \
  "--enable" "Enable *Enable* Function" "\n" "--no-enable" "Don't Enable *Enable* Function" "\n" "--disable" "Enable *Disable* Function"  "\n" "--no-disable" "Don't Enable *Disable* Function");

function do_HELP()
{
  declare -i TEMP_LEN=0
  declare -i SWITCH_LEN=0
  declare -i COMMAND_LEN=0
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { service1 service2 service3  }\n"
  # First nested loop to get longest string length of both "switch" and "command"
  while IFS= read LINE; do
    INDEX=-1
    unset COMMAND
    unset SWITCH
    for DATA in $LINE; do
      ((INDEX++))
      if [ $INDEX -eq 0 ]; then
        SWITCH="$DATA"
        TEMP_LEN=${#SWITCH}
        if [ $TEMP_LEN -gt $SWITCH_LEN ]; then SWITCH_LEN=$((TEMP_LEN)); fi
      else
	COMMAND="$COMMAND $DATA"
	TEMP_LEN=${#COMMAND}
	if [ $TEMP_LEN -gt $COMMAND_LEN ]; then COMMAND_LEN=$((TEMP_LEN)); fi
      fi
    done
    unset DATA
  done < <(echo -e ${INFO_ARRAY[@]})

  LINE_INDEX=-1
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    unset SWITCH
    unset COMMAND
    for DATA in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then
        SWITCH="$DATA"
      else
        COMMAND="$COMMAND $DATA"
      fi
    done
    printf "%b" $CLG; printf "%-$((SWITCH_LEN+1))s" "$SWITCH";	printf "%b:\t" $CN; printf "%b" $CY; printf "%-$((COMMAND_LEN+1))s"	"$COMMAND"; printf "%b" $CN
    if [ $LINE_INDEX -eq 0 ]; then
      printf "\t|\t"
    else
      printf "\n"
      LINE_INDEX=-1
    fi
  done < <(echo -e "${INFO_ARRAY[@]}")
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
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
'--force-color')
	export BOL_FORCE_COLOR=$TRUE
        export BOL_COLOR=$TRUE
        ;;
*)
	(( INDEX_VAL++))
	ARGS_ARRAY[(($INDEX_VAL))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; COLOR_SHORTHAND; fi
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
