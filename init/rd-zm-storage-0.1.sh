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

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit $FAILURE
fi

declare -ag UUID_ARRAY=( "f5ce6cbd-52a7-4a01-82a8-a13eb3ed8ad2" "898fa432-f42a-4405-8c69-3bb5eab3a1b5" );
declare -ag MOUNT_ARRAY=( "/var/lib/zm0" "/var/lib/zm1" );
declare -ag RD_ARRAY=();
declare -ag RD_DEVICE_ARRAY=();

if [ ${#RD_SIZE}	-eq 0 ]; then	declare -ig RD_SIZE=128;					fi

function CHECK_MOUNT()
{
  for DATA in ${MOUNT_ARRAY[@]}; do
    $MOUNT_BIN | $GREP_BIN "$DATA" >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      echo -e "Error $DATA already mounted!"
      exit $FAILURE
    fi
  done
  return $SUCCESS
};

function DO_ATTACH()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i INDEX=-1
  for DATA in $( $RAPIDDISK_BIN --attach $((RD_SIZE)) ); do
    ((INDEX++))
    if [ $INDEX -eq 10 ]; then
      echo $DATA
      FUNCTION_RETURN=$SUCCESS
    fi
  done
  return $FUNCTION_RETURN
};

function DO_CACHE_MAP()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i INDEX=-1
  declare -i WORD_INDEX=-1
  for DATA in ${UUID_ARRAY[@]}; do
    ((INDEX++))
    WORD_INDEX=-1
    export RD_DEVICE=$(DO_ATTACH)
    RD_ARRAY[$((INDEX))]="$RD_DEVICE"
    for WORD in $($RAPIDDISK_BIN --cache-map $RD_DEVICE $($BLKID_BIN --uuid $DATA) wa ); do
      FUNCTION_RETURN=$?
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 11 ]; then
        RD_DEVICE_ARRAY[$((INDEX))]="$WORD"
        if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%b" $CLB; printf "[Info] " printf "%b" $CLG; printf "RapidDisk Device Name: "; printf "%b" $CY; printf "%s" $WORD; printf "%b" $CN; fi
      fi
    done
    if [ $BOL_DEBUG -eq $TRUE ]; then
      printf "%b" $CLB; printf "[Debug] "; printf "%b" $CC
      $RAPIDDISK_BIN --list
      printf "%b" $CN
    fi
  done
  return $FUNCTION_RETURN
};

function DO_MOUNT()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i INDEX=-1
  export NAME_PREFIX="/dev/mapper"
  for RD_NAME in ${RD_DEVICE_ARRAY[@]}; do
    ((INDEX++))
    DEVICE_NAME="$NAME_PREFIX/$RD_NAME"
    $MOUNT_BIN "$DEVICE_NAME" "${MOUNT_ARRAY[$((INDEX))]}" >/dev/null 2>/dev/null 3>/dev/null
    FUNCTION_RETURN=$?
  done
  return $FUNCTION_RETURN
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
        export BOL_VERBOSE=$FALSE
        ;;
'-v' | '--verbose')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-t' | '--test')
        export BOL_TEST=$TRUE
        export MOUNT_BIN="$TRUE_BIN"
	export UMOUNT_BIN="$TRUE_BIN"
        export RAPIDDISK_BIN="$TRUE_BIN"
	export SWAPON_BIN="$TRUE_BIN"
        ;;
'--debug')
	export BOL_DEBUG=$TRUE
	;;
'--version')
        SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
        exit $SUCCESS
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
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
        export BOL_WAIT=$TRUE
        ;;
--rapid-disk-size=*)
        X="${i#*=}"
	RAPID_DISK_SIZE=$((X))
	;;
'--no-wait')
        export BOL_WAIT=$FALSE
        ;;
*)
        ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
        ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
        SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
        ;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER

if [ $BOL_START -eq $TRUE ]; then
  CHECK_MOUNT
  DO_CACHE_MAP
  DO_MOUNT
fi
