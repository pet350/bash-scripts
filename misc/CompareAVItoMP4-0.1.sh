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
export MODIFIED="2022-06-13"
declare -i SCRIPT_RETURN=$SUCCESS

# Define a few more binary variables
for DATA in mediainfo clear find; do
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

# Self Explanitory Function
function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\t\tDated: $MODIFIED"
  return $SUCCESS
};

# Another Self Explanitory Function
function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

# Function will display all information with a colored format
function SHOW_INFO()
{
  SHOW_DATE_TIME; printf "\n"
  CDA_TEXT; printf "+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+\n"; CN_TEXT
  CDA_TEXT; printf "| "; CLB_TEXT; printf "%3s: " $TYPE; CLR_TEXT; printf "%4s / %4s " $COUNT $TOTAL; CLB_TEXT; printf "File name: "; CY_TEXT; printf "%-185s" "$FILENAME"; CDA_TEXT; printf "\t|\n"; CN_TEXT
  CDA_TEXT; printf "| "; CLB_TEXT; printf "General Run Time: "; CLR_TEXT; printf "%12s" "$GENERAL_DURATION"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Size: "; CLR_TEXT; printf "%16s" "$GENERAL_SIZE"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Format: "; CLR_TEXT; printf "%16s" "$GENERAL_FORMAT"; CDA_TEXT; printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t|\n"; CN_TEXT 
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    CDA_TEXT; printf "| "; CLB_TEXT; printf "Video Run Time:   "; CLR_TEXT; printf "%12s" "$VIDEO_DURATION"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Size: "; CLR_TEXT; printf "%16s" "$VIDEO_SIZE"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Format: "; CLR_TEXT; printf "%16s" "$VIDEO_FORMAT"; CDA_TEXT; printf "| "
    CLB_TEXT; printf "Codec: "; CLR_TEXT; printf "%10s" "$VIDEO_CODEC"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Bit Rate: "; CLR_TEXT; printf "%13s" "$VIDEO_BIT_RATE"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Resolution: "; CLR_TEXT; printf "%sX %s " "$VIDEO_WIDTH" "$VIDEO_HEIGHT"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Rate "; CLR_TEXT; printf "%23s %14s" "$FRAME_RATE" "$SCAN_TYPE"; CDA_TEXT; printf "\t|\n"; CN_TEXT
    CDA_TEXT; printf "| "; CLB_TEXT; printf "Audio Run Time:   "; CLR_TEXT; printf "%12s" "$AUDIO_DURATION"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Size: "; CLR_TEXT; printf "%16s" "$AUDIO_SIZE"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Format: "; CLR_TEXT; printf "%16s" "$AUDIO_FORMAT"; CDA_TEXT; printf "| "
    CLB_TEXT; printf "Codec: "; CLR_TEXT; printf "%10s" "$AUDIO_CODEC"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Bit Rate: "; CLR_TEXT; printf "%13s" "$AUDIO_BIT_RATE"; printf "%11s %26s " "$BIT_RATE_MODE" "$AUDIO_MODE"; CDA_TEXT; printf "| "; CLB_TEXT; printf "Sampling Rate: "; CLR_TEXT; printf "%13s" "$SAMPLE_RATE"; CDA_TEXT; printf "\t\t\t|\n"; CN_TEXT
  fi
  CDA_TEXT; printf "+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+\n"; CN_TEXT

  return $SUCCESS
};

# Gets the current "VALUE" of the current "FILED" from mediainfo
function GET_VALUE()
{
  declare -i FUNC_RET=$FAILURE
  declare -i INDEX=-1
  declare -i BOL_VALUE=$FALSE
  for WORD in $DATA; do
    ((INDEX++))
    if [ $INDEX -gt 1 ] && [ $BOL_VALUE -eq $TRUE ]; then printf "%s " $WORD; FUNC_RET=$SUCCESS;	fi
    case $WORD in
      ':')	declare -i BOL_VALUE=$TRUE;;
    esac
  done
  if [ $FUNC_RET -eq $SUCCESS ]; then printf "\n";			fi
  return $FUNC_RET
};

# Gets the current "FIELD" from mediainfo
function GET_FIELD()
{
  declare -i FUNC_RET=$FAILURE
  declare -i INDEX=-1
  declare -i BOL_FIELD=$TRUE
  for WORD in $DATA; do
    ((INDEX++))
    case $WORD in
      ':')	declare -i BOL_FIELD=$FALSE;;
    esac
    if [ $INDEX -lt 4 ] && [ $BOL_FIELD -eq $TRUE ]; then printf "%s " $WORD; FUNC_RET=$SUCCESS;	fi
  done
  if [ $FUNC_RET -eq $SUCCESS ]; then printf "\n";                      fi
  return $FUNC_RET
};

# Stored Information into various strings based on mediainfo
function GET_INFO()
{
  declare -i BOL_GENERAL=$FALSE
  declare -i BOL_VIDEO=$FALSE
  declare -i BOL_AUDIO=$FALSE

  while IFS= read DATA; do
    export FIELD="$(GET_FIELD)"
    case "$FIELD" in
      'General ')	BOL_GENERAL=$TRUE;	BOL_VIDEO=$FALSE;	BOL_AUIDO=$FALSE;;
      'Video ')		BOL_GENERAL=$FALSE;	BOL_VIDEO=$TRUE;	BOL_AUDIO=$FALSE;;
      'Audio ')		BOL_GENERAL=$FALSE;	BOL_VIDEO=$FALSE;	BOL_AUDIO=$TRUE;;
      'Frame rate ')	  if [ $BOL_VIDEO   -eq $TRUE ]; then	export  FRAME_RATE="$(GET_VALUE)";	fi;;
      'Scan type ')	  if [ $BOL_VIDEO   -eq $TRUE ]; then 	export  SCAN_TYPE="$(GET_VALUE)";	fi;;
      'File size ')	  if [ $BOL_GENERAL -eq $TRUE ]; then 	export  GENERAL_SIZE="$(GET_VALUE)";	fi;;
      'Width ')		  if [ $BOL_VIDEO   -eq $TRUE ]; then	export  VIDEO_WIDTH="$(GET_VALUE)";	fi;;
      'Height ')	  if [ $BOL_VIDEO   -eq $TRUE ]; then   export  VIDEO_HEIGHT="$(GET_VALUE)";	fi;;
      'Bit rate mode ')   if [ $BOL_AUDIO   -eq $TRUE ]; then	export  BIT_RATE_MODE="$(GET_VALUE)";	fi;;
      'Sampling rate ')   if [ $BOL_AUDIO   -eq $TRUE ]; then   export  SAMPLE_RATE="$(GET_VALUE)";	fi;;
      'Format settings ') if [ $BOL_AUDIO   -eq $TRUE ]; then   export  AUDIO_MODE="$(GET_VALUE)"; 	fi;;
      'Stream size ')
        if [ $BOL_VIDEO         -eq $TRUE ]; then export VIDEO_SIZE="$(GET_VALUE)";			fi
        if [ $BOL_AUDIO         -eq $TRUE ]; then export AUDIO_SIZE="$(GET_VALUE)";			fi
        ;;
      'Duration ')
	if [ $BOL_GENERAL	-eq $TRUE ]; then export GENERAL_DURATION="$(GET_VALUE)";		fi
	if [ $BOL_VIDEO		-eq $TRUE ]; then export VIDEO_DURATION="$(GET_VALUE)";			fi
	if [ $BOL_AUDIO		-eq $TRUE ]; then export AUDIO_DURATION="$(GET_VALUE)";			fi
	;;
      'Codec ID ')
	if [ $BOL_VIDEO         -eq $TRUE ]; then export VIDEO_CODEC="$(GET_VALUE)";         		fi
	if [ $BOL_AUDIO         -eq $TRUE ]; then export AUDIO_CODEC="$(GET_VALUE)";         		fi
	;;
      'Format ')
	if [ $BOL_GENERAL       -eq $TRUE ]; then export GENERAL_FORMAT="$(GET_VALUE)";			fi
        if [ $BOL_VIDEO         -eq $TRUE ]; then export VIDEO_FORMAT="$(GET_VALUE)";           	fi
        if [ $BOL_AUDIO         -eq $TRUE ]; then export AUDIO_FORMAT="$(GET_VALUE)";           	fi
	;;
      'Bit rate ')
	if [ $BOL_VIDEO         -eq $TRUE ]; then export VIDEO_BIT_RATE="$(GET_VALUE)";         	fi
        if [ $BOL_AUDIO         -eq $TRUE ]; then export AUDIO_BIT_RATE="$(GET_VALUE)";         	fi
        ;;

    esac
  done < <($MEDIAINFO_BIN "$FILENAME")
  return $SUCCESS
};

# Will get total number of MPEG files with the samer filename as it's AVI counterpart
function GET_MPG_TOTAL()
{
  declare -ag MPG_ARRAY=();
  declare MPG_INDEX=0
  while IFS= read RAW_DATA; do
    export TEST_MPEG_FILENAME="${RAW_DATA%.*}.$OUT_EXT"
    if [ -f "$TEST_MPEG_FILENAME" ]; then
      MPG_ARRAY[$((MPG_INDEX))]="$TEST_MPEG_FILENAME\n"
      ((MPG_INDEX++))
    fi
  done < <($FIND_BIN "$MOVIE_PREFIX" -type f -iname '*.avi')
  echo $((MPG_INDEX))
  return $SUCCESS
};

# Show contents of MPG_ARRAY correctly formatted
function SHOW_ARRAY()
{
  declare -i INDEX=-1
  while IFS= read LINE; do
    ((INDEX++))
    if [ $INDEX -eq 0 ]; then
      echo "$LINE"
    else
      echo "${LINE:1}"
    fi
  done < <(echo -e "${MPG_ARRAY[@]}")
  return $SUCCESS
};

# Same as MAIN_LOOP but based off of MPG_ARRAY
# This way its not getting info of AVI files that dont have a MPEG counterpart
function QUICK_LOOP()
{
  declare -i AVI_COUNT=0
  declare -i MPG_COUNT=0

  GET_MPG_TOTAL >/dev/null
  while IFS= read DATA; do
    for STRING in INPUT AVI_FILENAME MPEG_FILENAME AVI_LENGTH MPEG_LENGTH AVI_SIZE MPEG_SIZE; do
      unset $STRING
    done
    export AVI_FILENAME="${DATA%.*}.avi"
    export MPEG_FILENAME="$DATA"

    if [ -f "$AVI_FILENAME" ]; then
      ((AVI_COUNT++))
      export FILENAME="$AVI_FILENAME"
      GET_INFO
      export AVI_LENGTH="$GENERAL_DURATION"
      export AVI_SIZE="$GENERAL_SIZE"
      export TYPE="AVI"
      export COUNT=$AVI_COUNT
      export TOTAL=$AVI_TOTAL
      if [ $BOL_QUIET   -ne $TRUE ]; then SHOW_INFO;    fi
    fi
    if [ -f "$MPEG_FILENAME" ]; then
      ((MPG_COUNT++))
      export FILENAME="$MPEG_FILENAME"
      GET_INFO
      export MPEG_LENGTH="$GENERAL_DURATION"
      export MPEG_SIZE="$GENERAL_SIZE"
      export TYPE="$OUT_EXT"
      export COUNT=$MPG_COUNT
      export TOTAL=$MPG_TOTAL
      if [ $BOL_QUIET   -ne $TRUE ]; then SHOW_INFO;    fi
    fi
    if [ ${#AVI_LENGTH} -ne 0 ] && [ ${#MPEG_LENGTH} -ne 0 ]; then
      printf "AVI %25s Runtime: %15s; MPEG %25s Runtime: %15s; are " "$AVI_FILENAME" "$AVI_LENGTH" "$MPEG_FILENAME" "$MPEG_LENGTH"
      if [ "$AVI_LENGTH" == "$MPEG_LENGTH" ]; then
        printf "the same\n"
        if [ $BOL_DELETE -eq $TRUE ]; then
          CC_TEXT; rm -vf "$AVI_FILENAME"; CN_TEXT
        else
          printf "NOT Deleting %25s, to enable append --delete to the command line.\n" "$AVI_FILENAME"
        fi
      else
	printf "different\n"
      fi
    fi
    if [ $BOL_QUIET -ne $TRUE ]; then printf "\n\n"; fi
  done < <(SHOW_ARRAY)
};

# Much more thorough and time consuming than the QUICK_LOOP. This is the default LOOP
function MAIN_LOOP()
{
  declare -i AVI_COUNT=0
  declare -i MPG_COUNT=0

  while IFS= read DATA; do
    for STRING in INPUT AVI_FILENAME MPEG_FILENAME AVI_LENGTH MPEG_LENGTH AVI_SIZE MPEG_SIZE; do
      unset $STRING
    done
    export AVI_FILENAME="$DATA"
    export MPEG_FILENAME="${DATA%.*}.$OUT_EXT"

    if [ -f "$AVI_FILENAME" ]; then
      ((AVI_COUNT++))
      export FILENAME="$AVI_FILENAME"
      GET_INFO
      export AVI_LENGTH="$GENERAL_DURATION"
      export AVI_SIZE="$GENERAL_SIZE"
      export TYPE="AVI"
      export COUNT=$AVI_COUNT
      export TOTAL=$AVI_TOTAL
      if [ $BOL_QUIET	-ne $TRUE ]; then SHOW_INFO;	fi
    fi
    if [ -f "$MPEG_FILENAME" ]; then
      ((MPG_COUNT++))
      export FILENAME="$MPEG_FILENAME"
      GET_INFO
      export MPEG_LENGTH="$GENERAL_DURATION"
      export MPEG_SIZE="$GENERAL_SIZE"
      export TYPE="$OUT_EXT"
      export COUNT=$MPG_COUNT
      export TOTAL=$MPG_TOTAL
      if [ $BOL_QUIET   -ne $TRUE ]; then SHOW_INFO;    fi
    fi
    if [ ${#AVI_LENGTH} -ne 0 ] && [ ${#MPEG_LENGTH} -ne 0 ]; then
      printf "AVI %25s Runtime: %15s; MPEG %25s Runtime: %15s; are " "$AVI_FILENAME" "$AVI_LENGTH" "$MPEG_FILENAME" "$MPEG_LENGTH"
      if [ "$AVI_LENGTH" == "$MPEG_LENGTH" ]; then
        printf "the same\n"
        if [ $BOL_DELETE -eq $TRUE ]; then
          CC_TEXT; rm -vf "$AVI_FILENAME"; CN_TEXT
        else
          printf "NOT Deleting %25s, to enable append --delete to the command line.\n" "$AVI_FILENAME"
        fi
      else
        printf "different\n"
      fi
    fi
    if [ $BOL_QUIET -ne $TRUE ]; then printf "\n\n"; fi
  done < <($FIND_BIN "$MOVIE_PREFIX" -type f -iname '*.avi')
};

for OPTIONS in $@; do
  case $OPTIONS in
    -d | --delete)		declare -i BOL_DELETE=$TRUE;;
    -v | --verbose)		declare -i BOL_VERBOSE=$TRUE;		declare -i BOL_QUIET=$FALSE;;
    -q | --quiet)		declare -i BOL_VERBOSE=$FALSE;		declare -i BOL_QUIET=$TRUE;;
    -h | --help)		declare -i BOL_HELP=$TRUE;;
    -u | --quick)		declare -i BOL_QUICK=$TRUE;;
    --version)			SHOW_HEADER;		exit $SUCCESS;;
  esac
done

if [ ${#MOVIE_PREFIX}	-eq 0	  ]; then export MOVIE_PREFIX="/opt/movies";								fi
if [ ${#BOL_DELETE}	-eq 0	  ]; then declare -i BOL_DELETE=$FALSE;									fi
if [ ${#BOL_HELP}	-eq 0	  ]; then declare -i BOL_HELP=$FALSE;									fi
if [ ${#BOL_QUIET}	-eq 0	  ]; then declare -i BOL_QUIET=$FALSE;									fi
if [ ${#BOL_VERBOSE}	-eq 0	  ]; then declare -i VOL_VERBOSE=$FALSE;								fi
if [ ${#BOL_COLOR}	-eq 0	  ]; then declare -i BOL_COLOR=$TRUE;									fi
if [ ${#BOL_QUICK}	-eq 0	  ]; then declare -i BOL_QUICK=$FALSE;									fi
if [ ${#OUT_EXT}	-eq 0	  ]; then export OUT_EXT="mp4";										fi
if [ ${#AVI_TOTAL}	-eq 0	  ]; then declare -i AVI_TOTAL=$($FIND_BIN "$MOVIE_PREFIX" -type f -iname '*.avi' | wc -l);		fi
if [ ${#MPG_TOTAL}	-eq 0	  ]; then declare -i MPG_TOTAL=$(GET_MPG_TOTAL);							fi
if [ $BOL_COLOR		-eq $TRUE ]; then INIT_COLOR_SHORTHAND;										fi
if [ $BOL_VERBOSE	-eq $TRUE ]; then SHOW_HEADER;											fi
if [ $BOL_QUICK		-eq $TRUE ]; then QUICK_LOOP; export RETVAL=$?; else MAIN_LOOP; RETVAL=$?;					fi

exit $RETVAL
## End of script!!
