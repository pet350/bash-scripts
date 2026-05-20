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

# Define a few more binary variables
for DATA in curl xrandr egrep chown sleep find; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done


export RUN_CMD="$(basename $0)"
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-04-30"
declare -i SCRIPT_RETURN=$SUCCESS

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

function GETMODELINE()
{
    declare -i RETVAL=$FAILURE
    while IFS= read LINE; do
        for WORD in $LINE; do
            case $WORD in
                Modeline)
		    echo "$LINE"
		    RETVAL=$SUCCESS
                    ;;
	    esac
	done
    done < <(gtf 1920 1080 60)
    return $RETVAL
};

function GETMODENAME()
{
    declare -i RETVAL=$FAILURE
    declare -i INDEX=-1
    for DATA in $MODELINE; do
      ((INDEX++))
      if [ $INDEX -eq 1 ]; then echo $DATA; RETVAL=$SUCCESS; fi
    done
    return $RETVAL
};


function GETMODEVALS()
{
    declare -i RETVAL=$FAILURE
    declare -i INDEX=-1
    for DATA in $MODELINE; do
      ((INDEX++))
      if [ $INDEX -gt 1 ]; then
	printf "%s " $DATA
	RETVAL=$SUCCESS
      fi
    done
    printf "\n"
    return $RETVAL
};

function GET_CONNECTED_OUTPUT()
{
    declare -i RETVAL=$FAILURE
    declare -i LINE_INDEX=-1
    declare -i WORD_INDEX=-1
    declare -i BOL_CONN=$FALSE
    while IFS= read LINE; do
	((LINE_INDEX++))
	WORD_INDEX=-1
        for WORD in $LINE; do
            case $WORD in
                'connected') BOL_CONN=$TRUE;;
            esac
        done
	if [ $BOL_CONN -eq $TRUE ]; then
	    RETVAL=$SUCCESS
	    BOL_CONN=$FALSE
	    WORD_INDEX=-1
	    for WORD in $LINE; do
		((WORD_INDEX++))
		if [ $WORD_INDEX -eq 0 ]; then echo -e "$WORD"; fi
	    done
	fi
    done < <($XRANDR_BIN)
    return $RETVAL
};

for OPTIONS in $@; do
    case $OPTIONS in
	-v | --verbose)		declare -i BOL_VERBOSE=$TRUE;;
    esac
done

if [ $BOL_VERBOSE -eq $TRUE ]; then  SHOW_HEADER; echo ''; 	fi
if [ ${#DEVICE}		-eq 0 ]; then export DEVICE=$(GET_CONNECTED_OUTPUT);						fi
if [ ${#MODELINE}	-eq 0 ]; then export MODELINE=$(GETMODELINE);							fi
if [ ${#MODENAME}	-eq 0 ]; then export MODENAME=$(GETMODENAME);							fi
if [ ${#MODEVALS}	-eq 0 ]; then export MODEVALS="$(GETMODEVALS)";							fi

if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Output Device: $DEVICE";							fi
if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Mode Line: $MODELINE\nMode Name: $MODENAME\nMode Values: $MODEVALS\n"; 	fi
if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $XRANDR_BIN --newmode $MODENAME $MODEVALS"; 			fi
$XRANDR_BIN --newmode "$MODENAME" $MODEVALS; RETVAL=$?; COMMAND="$XRANDR_BIN --newmode"
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; echo '';									fi

if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $XRANDR_BIN --addmode $DEVICE $MODENAME";			fi
$XRANDR_BIN --addmode $DEVICE $MODENAME; RETVAL=$?; COMMAND="$XRANDR_BIN --addmode"
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; echo '';                                                                       fi

if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $XRANDR_BIN --output $DEVICE --mode $MODENAME";			fi
$XRANDR_BIN --output $DEVICE --mode "$MODENAME"; RETVAL=$?; COMMAND="$XRANDR_BIN  --output"
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; echo '';                                                                       fi

