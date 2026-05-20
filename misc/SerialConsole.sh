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
export VERSION="0.2"

if [ ${#MINICOM_BIN}	-eq 0 ]; then export TEMP="minicom";	export ${TEMP^^}_BIN=$(GET_BIN);	fi
if [ ${#TRUE_BIN}	-eq 0 ]; then export TEMP="true";	export ${TEMP^^}_BIN=$(GET_BIN);        fi

if [ ${#COM_BAUD}	-eq 0 ]; then export COM_BAUD=9600;						fi
if [ ${#COM_PORT}	-eq 0 ]; then export COM_PORT="/dev/ttyS0";					fi
if [ ${#COM_BITS}	-eq 0 ]; then export COM_BITS="8";						fi

if [ ${#BOL_COLOR}	-eq 0 ]; then declare -ig BOL_COLOR=$TRUE;					fi
if [ ${#BOL_INIT}	-eq 0 ]; then declare -ig BOL_INIT=$FALSE;					fi

declare -ag OPT_ARRAY=();
declare -ag COM_ARRAY=();

declare -ig OPT_ARRAY_INDEX=${#OPT_ARRAY[@]}
declare -ig COM_ARRAY_INDEX=${#COM_ARRAY[@]}


for OPTIONS in $@; do
  case $OPTIONS in
    --test)
      export BOL_TEST=$TRUE
      export MINICOM_BIN="$TRUE_BIN"
      ;;
    --baud=*)
      export COM_BAUD="${OPTIONS#*=}"
      ;;
    --port=*)
      export COM_PORT="${OPTIONS#*=}"
      ;;
    --bits=*)
      TEMP="${OPTIONS#*=}"
      if [ $((TEMP)) -eq 7 ] || [ $((TEMP)) -eq 8 ]; then
        export COM_BITS=$((TEMP))
      fi
      unset TEMP
      ;;
    --init)
      export BOL_INIT=$TRUE
      ;;
    -h | --help)
      export BOL_HELP=$TRUE
      ;;
    -d | --debug)
      export BOL_DEBUG=$TRUE
      ;;
    -v | --verbose)
      export BOL_VERBOSE=$TRUE
      export BOL_QUIET=$FALSE
      ;;
    -q | --quiet)
      export BOL_VERBOSE=$FALSE
      export BOL_QUIET=$TRUE
      ;;
    --version)
      echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
      exit $SUCCESS
      ;;
    --bw)
      export BOL_COLOR=$FALSE
      ;;
    --color)
      export BOL_COLOR=$TRUE
      ;;
    --force-color)
      export BOL_FORCE_COLOR=$TRUE
      export BOL_COLOR=$TRUE
      ;;
    *)
      OPT_ARRAY[$((OPT_ARRAY_INDEX))]="$OPTIONS"
      OPT_ARRAY_INDEX=${#OPT_ARRAY[@]}
      ;;
  esac
done

if [ $BOL_INIT -eq $FALSE ]; then export INIT="--noinit"; else export INIT=""; fi

for DATA in $(pgrep minicom); do
    kill $DATA
    $SLEEP_BIN 2
done

for DATA in '-D' $COM_PORT '-b' $COM_BAUD "-"$COM_BITS $INIT ${OPT_ARRAY[@]}; do
  COM_ARRAY[$((COM_ARRAY_INDEX))]="$DATA"
  COM_ARRAY_INDEX=${#COM_ARRAY[@]}
done

if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $MINICOM_BIN ${COM_ARRAY[@]}"; fi
$MINICOM_BIN ${COM_ARRAY[@]}
exit $?
