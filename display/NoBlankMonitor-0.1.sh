#! /bin/bash
# Simple Script To Disable Screen Blanking Built Into XSERVER
### By: Peter Talbott 2019-06-06

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ ${#DISPLAY}    -eq 0 ]; then export DISPLAY=:0; 			fi
if [ ${#XAUTHORITY} -eq 0 ]; then export XAUTHORITY=~/.Xauthority; 	fi

export PREFIX="/usr/bin"
export XSET_BIN="$PREFIX/xset"

declare -ag XSET_CMD_ARRAY=("s" "s" "s" "-dpms" "q");
declare -ag XSET_OPT_ARRAY=("blank" "0" "noblank" " " " ");

declare -ig INDEX=-1
declare -ig RETVAL=$FAILURE

for TEMP_CMD in ${XSET_CMD_ARRAY[@]}; do
  ((INDEX++))
  TEMP_OPT="${XSET_OPT_ARRAY[$((INDEX))]}"
  $XSET_BIN $TEMP_CMD $TEMP_OPT
  RETVAL=$?
done

exit $RETVAL
