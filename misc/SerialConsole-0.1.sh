#!/bin/bash


export RUN_CMD="$(basename $0)"
export VERSION="0.1"

for PREFIX in /bin /sbin /usr/bin /usr/sbin; do
  for BIN in true minicom; do
    if [ -f $PREFIX/$BIN ]; then
      export ${BIN^^}_BIN=$PREFIX/$BIN
    fi
  done
done

if [ ${#COM_BAUD}	-eq 0 ]; then export COM_BAUD=9600;		fi
if [ ${#COM_PORT}	-eq 0 ]; then export COM_PORT="/dev/ttyS0";	fi
if [ ${#COM_BITS}	-eq 0 ]; then export COM_BITS="8";		fi

declare -ag OPT_ARRAY=();
declare -ag COM_ARRAY=();

declare -ig OPT_ARRAY_INDEX=${#OPT_ARRAY[@]}
declare -ig COM_ARRAY_INDEX=${#COM_ARRAY[@]}


for OPTIONS in $@; do
  case $OPTIONS in
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
    *)
      OPT_ARRAY[$((OPT_ARRAY_INDEX))]="$OPTIONS"
      OPT_ARRAY_INDEX=${#OPT_ARRAY[@]}
      ;;
  esac
done

for DATA in '-D' $COM_PORT '-b' $COM_BAUD "-"$COM_BITS ${OPT_ARRAY[@]}; do
  COM_ARRAY[$((COM_ARRAY_INDEX))]="$DATA"
  COM_ARRAY_INDEX=${#COM_ARRAY[@]}
done

$MINICOM_BIN ${COM_ARRAY[@]}
exit $?
