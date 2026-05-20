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
for DATA in ffmpeg sleep find; do
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

function SET_FILENAMES()
{
  export NTSC_MPEG="./${FILENAME%.avi*}.mpeg"
  export NTSC_MP4="./${FILENAME%.avi*}.mp4"
  export SOURCE="./$FILENAME"
  return $SUCCESS
};

# Define some default behaviors
declare -i BOL_AVI2DVD=$TRUE
declare -i BOL_DVD2MP4=$TRUE
declare -i BOL_POSTPROCESS=$FALSE

function AVI2DVD()
{
  echo -e "Source: $SOURCE"
  echo -e "MPEG: $NTSC_MPEG"
  echo -e "MP4: $NTSC_MP4"
  $SLEEP_BIN 2
  $FFMPEG_BIN -i "$SOURCE" $NTSC_OPTS "$NTSC_MPEG"
  export RETVAL=$?
  $SLEEP_BIN 1
  if [ $RETVAL -ne 0 ]; then
     echo -e "$FFMPEG_BIN Error code: $RETVAL"
     $SLEEP_BIN 2
     exit $RETVAL
  else
     echo -e "$FFMPEG_BIN first encode Source to NTSC MPEG returned $?"
  fi
  return $RETVAL
};

function DVD2MP4()
{

   echo -e "$FFMPEG_BIN Second encode NTSC MPEG to MP4 starting"
   $SLEEP_BIN 1
   $FFMPEG_BIN -i "$NTSC_MPEG" $FFMIN264 "$NTSC_MP4"
   export RETVAL=$?
   $SLEEP_BIN 2
   if [ $RETVAL -eq 0 ]; then
       $SLEEP_BIN 2
       echo -e "Finished Second encode of $SOURCE. Return Value $RETVAL\n\n"
   else
       echo -e "$FFMPEG_BIN Error code: $RETVAL"
       $SLEEP_BIN 2
       exit $RETVAL
   fi
   return $RETVAL
};

function POSTPROCESS()
{
   rm -fv "$NTSC_MPEG"
   mv -v  "$SOURCE" ..
   mv -v  "$NTSC_MP4" "$TARGET_PREFIX"
   chown 33:1001 "$TARGET_PREFIX" -vR
   chmod g+rw "$TARGET_PREFIX" -vR
};

for ARGS in $@; do
  case $ARGS in
    --version)		SHOW_HEADER;	exit $SUCCESS;;
    --config=*)		export CFG_FILE="${ARGS#*=}";;
    --filename=*)	export FILENAME="${ARGS#*=}";;
    --mpeg=*)		export NTSC_MPEG="${ARGS#*=}";;
    --mp4=*)		export NTSC_MP4="${ARGS#*=}";;
    '--avi2dvd')        declare -i BOL_AVI2DVD=$TRUE;;
    '--dvd2mp4')        declare -i BOL_DVD2MP4=$TRUE;;
    '--postprocess')    declare -i BOL_POSTPROCESS=$TRUE;;
    '--no-avi2dvd')	declare -i BOL_AVI2DVD=$FALSE;;
    '--no-dvd2mp4')	declare -i BOL_DVD2MP4=$FALSE;;
    '--no-postprocess') declare -i BOL_POSTPROCESS=$FALSE;;
  esac
done

if [ ${#CFG_FILE} -ne 0 ] && [ -f 	"$CFG_FILE"   ]; then . "$CFG_FILE";                                                                            				fi
if [ ${#FILENAME}				-eq 0 ]; then SHOW_HEADER; echo -e "Error: No filename specified!"; exit $FAILURE; 							fi
if [ ${#FFMIN264} 	     			-eq 0 ]; then export FFMIN264="-c:v libx264 -pix_fmt yuv420p -aspect 16:9 -c:a libmp3lame -movflags faststart -preset ultrafast";	fi
if [ ${#NTSC_OPTS}      			-eq 0 ]; then export NTSC_OPTS="-target ntsc-dvd -aspect 16:9";										fi
if [ ${#NTSC_MPEG} -eq 0 ] || [ ${#NTSC_MP4}	-eq 0 ]; then SET_FILENAMES;														fi
if [ $BOL_AVI2DVD		-eq		$TRUE ]; then AVI2DVD;															fi
if [ $BOL_DVD2MP4		-eq		$TRUE ]; then DVD2MP4;															fi
if [ $BOL_POSTPROCESS		-eq		$TRUE ]; then POSTPROCESS;														fi

exit $?
