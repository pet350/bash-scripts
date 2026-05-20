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
export AUTHOR="Peter Talbott"
export MODIFIED="2022-07-18"

# Define a few more binary variables
for DATA in du sleep find; do
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

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

declare -a NAME_ARRAY=();
declare -a SIZE_ARRAY=();
declare -a LONG_ARRAY=();

function GET_SIZE()
{
    declare -i INDEX=-1
    if [ ${#TARGET_PREFIX} -ne 0 ]; then
	export TARGET_FILENAME="$TARGET_PREFIX"/"$FILENAME"
    else
	export TARGET_FILENAME="$FILENAME"
    fi
    for DATA in $($DU_BIN $OPTIONS "$TARGET_FILENAME" 2>/dev/null); do
	((INDEX++))
	if [ $INDEX -eq 0 ]; then echo $DATA; fi
    done
    return $SUCCESS
};

function GET_ARRAY()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE
    while IFS= read FILENAME; do
	((INDEX++))
	NAME_ARRAY[$((INDEX))]="$FILENAME"
	export OPTIONS="-sh"; SIZE_ARRAY[$((INDEX))]=$(GET_SIZE)
	export OPTIONS="-s";  LONG_ARRAY[$((INDEX))]=$(GET_SIZE)
    done < <(ls -S1 "$TARGET_PREFIX"; RETVAL=$?)
    return $RETVAL
};

function SHOW_ARRAY()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE
    for FILENAME in "${NAME_ARRAY[@]}"; do
	((INDEX++))
	TEMP_SIZE="${SIZE_ARRAY[$((INDEX))]}"
	printf "%4d %8s %-130s\n" "$((INDEX+1))" "$TEMP_SIZE" "$FILENAME"
    done
};

for ARGS in $@; do
    case $ARGS in
	--target=*)	
GET_ARRAY
SHOW_ARRAY

