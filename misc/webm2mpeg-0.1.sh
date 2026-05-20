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
export AUTHOR="Peter Talbott"
export MODIFIED="2022-09-30"
export WORKING_PREFIX="$(pwd)"

# Define a few more binary variables
for DATA in ffmpeg chown mv find; do
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

if [ ${#DL_PREFIX}	-eq 0 ]; then export DL_PREFIX="/nfs/ubuntuserver/opt/movies/dl";		fi
if [ ${#MOVIE_PREFIX}	-eq 0 ]; then export MOVIE_PREFIX="/nfs/ubuntuserver/opt/movies";		fi
if [ ${#FILE_USER}	-eq 0 ]; then export FILE_USER="www-data";					fi
if [ ${#FILE_GROUP}	-eq 0 ]; then export FILE_GROUP="streaming";					fi
if [ ${#ENCODE_OPTS}	-eq 0 ]; then export ENCODE_OPTS="-c:v libx264 -vf scale=480x360,fps=fps=29.97 -aspect 16:9 -tune zerolatency -preset ultrafast -c:a libmp3lame -movflags faststart";	fi
if [ ${#FILEPAIR[@]}	-eq 0 ]; then declare -A -G FILEPAIR=();					fi


function FINDPAIR_ARRAY()
{
    declare -i PAIR_INDEX=-1
    declare -i FILE_INDEX=0
    declare -i RETVAL=$FAILURE

    while IFS= read FILE1; do
	((PAIR_INDEX++))
	FILE_INDEX=0
	FILEPAIR[$((PAIR_INDEX)),$((FILE_INDEX))]="$FILE1"
	export TEMPNAME="${FILE1%.f251.webm*}"
	export TEMPNAME="${TEMPNAME#$DL_PREFIX/*}"
	export TEMPNAME="${TEMPNAME%'-['*}"
	for FILE2 in "$(ls $DL_PREFIX/*.webm | grep -v f251 | grep $TEMPNAME)"; do
		((FILE_INDEX++))
		FILEPAIR[$((PAIR_INDEX)),$((FILE_INDEX))]="$FILE2"
	done
    done < <(ls $DL_PREFIX/*.webm | grep f251; RETVAL=$?)
    export TOTAL_PAIRS=$((PAIR_INDEX+1))
    return $RETVAL
};

function SHOWPAIR_ARRAY()
{
    declare -i PAIR_INDEX=-1
    declare -i FILE_INDEX=0
    declare -i RETVAL=$FAILURE

    if [ ${#PAIR_INDEX}	-ne 0 ]; then
      while [ $PAIR_INDEX -lt $((TOTAL_PAIRS-1)) ]; do
	RETVAL=$SUCCESS
	((PAIR_INDEX++))
	FILE1="${FILEPAIR[$((PAIR_INDEX)),0]}"
	FILE2="${FILEPAIR[$((PAIR_INDEX)),1]}"
	echo -e "Pair Number: $PAIR_INDEX, File 1: $FILE1"
        echo -e "Pair Number: $PAIR_INDEX, File 2: $FILE2"
	echo ""
      done
    else
      echo "No Pairs Found!"
    fi
    return $RETVAL
};

function RE_ENCODE()
{
    declare -i PAIR_INDEX=-1
    declare -i FILE_INDEX=0
    declare -i RETVAL=$FAILURE

    if [ ${#PAIR_INDEX} -ne 0 ]; then
      while [ $PAIR_INDEX -lt $((TOTAL_PAIRS-1)) ]; do
        ((PAIR_INDEX++))
        FILE1="${FILEPAIR[$((PAIR_INDEX)),0]}"
        FILE2="${FILEPAIR[$((PAIR_INDEX)),1]}"
	export OUTFILE="${FILE1%.f251.webm*}"
	export OUTFILE="${OUTFILE#$DL_PREFIX/*}"
	export OUTFILE="$DL_PREFIX/${OUTFILE%'-['*}.x264lo.mp4"
	echo -e "Encode Target: $OUTFILE"
	$FFMPEG_BIN -i "$FILE1" -i "$FILE2" $ENCODE_OPTS "$OUTFILE"
	RETVAL=$?; COMMAND="$FFMPEG"; LOG_RESULTS
	$CHOWN_BIN $FILE_USER:$FILE_GROUP "$OUTFILE"
	RETVAL=$?; COMMAND="$CHOWN_BIN"; LOG_RESULTS
	echo -e "\n"
      done
    fi
    return $RETVAL
};

FINDPAIR_ARRAY
SHOWPAIR_ARRAY
RE_ENCODE
exit $?
