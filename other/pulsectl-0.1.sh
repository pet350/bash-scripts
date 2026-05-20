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

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.2.5"

# Function determines if $SERVICE_NAME is running by the invoking User
function CHECK_SERVICE_UID()
{
  declare -i BOL_CHECK=$FALSE
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1
  declare -i INSTANCE=0
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ] && [ "$USER" == "$WORD" ]; then
        BOL_CHECK=$TRUE
        ((INSTANCE++))
      fi
    done
  done < <($PS_BIN -aux | $GREP_BIN -v $GREP_BIN | $GREP_BIN $SERVICE_NAME)
  echo $BOL_CHECK
  return $INSTANCE
};

function SHOW_BOL()
{
  if [ $BOL_TEMP -eq $TRUE ]; then
    printf "%b" $CLG; printf "True"; printf "%b\n" $CN
  else
    printf "%b" $CLR; printf "False"; printf "%b\n" $CN
  fi
  return $SUCCESS
};

if [ ${#BOL_START_PULSE_AUDIO}	   -eq 0 ]; then declare -ig BOL_START_PULSE_AUDIO=$FALSE; fi
if [ ${#BOL_START_PULSE_EFFECTS}   -eq 0 ]; then declare -ig BOL_START_PULSE_EFFECTS=$FALSE; fi
if [ ${#BOL_STOP_PULSE_AUDIO}      -eq 0 ]; then declare -ig BOL_STOP_PULSE_AUDIO=$FALSE; fi
if [ ${#BOL_STOP_PULSE_EFFECTS}    -eq 0 ]; then declare -ig BOL_STOP_PULSE_EFFECTS=$FALSE; fi
if [ ${#BOL_PULSE_AUDIO_RUNNING}   -eq 0 ]; then export SERVICE_NAME="pulseaudio";		export BOL_PULSE_AUDIO_RUNNING=$(CHECK_SERVICE_UID);		fi
if [ ${#BOL_PULSE_EFFECTS_RUNNING} -eq 0 ]; then export SERVICE_NAME="pulseeffects";		export BOL_PULSE_EFFECTS_RUNNING=$(CHECK_SERVICE_UID);		fi
if [ ${#PULSE_AUDIO_BIN}	   -eq 0 ]; then export TEMP="pulseaudio";    			export PULSE_AUDIO_BIN=$(GET_BIN);				fi
if [ ${#PULSE_EFFECTS_BIN}         -eq 0 ]; then export TEMP="pulseeffects";                    export PULSE_EFFECTS_BIN=$(GET_BIN);	  	  	  	fi
unset TEMP
unset SERVICE_NAME

declare -i RETVA=$SUCCESS
declare -ig CTL_PULSE_EFFECTS=$FALSE
declare -ig CTL_PULSE_AUDIO=$FALSE


function DISPLAY_BOOLEANS()
{
  export BOL_TEMP=$BOL_START_PULSE_AUDIO;	printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Start Pulse Audio:\t"; SHOW_BOL
  export BOL_TEMP=$BOL_STop_PULSE_EFFECTS;	printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Start Pulse Effects:\t"; SHOW_BOL
  export BOL_TEMP=$BOL_ST_PULSE_AUDIO;	        printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Stop  Pulse Audio:\t"; SHOW_BOL
  export BOL_TEMP=$BOL_STOP_PULSE_EFFECTS;      printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Stop  Pulse Effects:\t"; SHOW_BOL
  export BOL_TEMP=$BOL_PULSE_AUDIO_RUNNING;	printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Pulse Audio currently running by: "; printf "%b" $CC; printf "%s: " $USER; SHOW_BOL
  export BOL_TEMP=$BOL_PULSE_EFFECTS_RUNNING;	printf "%b" $CLB; printf "[Info] "; printf "%b" $CY; printf "Pulse Effects currently running by: "; printf "%b" $CC; printf "%s: " $USER; SHOW_BOL
  return $SUCCESS
};

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
        ;;
'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;

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
'-pa' | '--pulse-audio')
	export CTL_PULSE_AUDIO=$TRUE
	;;
'-pe' | '--pulse-effects')
	export CTL_PULSE_EFFECTS=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export PULSE_AUDIO_BIN="$TRUE_BIN"
	export PULSE_EFFECTS_BIN="$TRUE_BIN"
	;;
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
'--enable-root')
        export BOL_ENABLE_ROOT=$TRUE
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
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_START_PULSE_EFFECTS -eq $TRUE ] && [ $BOL_START_PULSE_AUDIO -eq $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $CTL_PULSE_EFFECTS -eq $TRUE ] && [ $CTL_PULSE_AUDIO -eq $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

CHECK_ROOT_USER

if [ $BOL_VERBOSE -eq $TRUE ]; then DISPLAY_BOOLEANS; fi

if [ $BOL_START -eq $TRUE ]; then
  if [ $CTL_PULSE_EFFECTS -eq $TRUE ] && [ $BOL_PULSE_EFFECTS_RUNNING -ne $TRUE ]; then
    $PULSE_EFFECTS_BIN --gapplication-service
    RETVAL=$?
  elif [ $CTL_PULSE_AUDIO -eq $TRUE ] && [ $BOL_PULSE_AUDIO_RUNNING -ne $TRUE ]; then
