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
export VERSION="0.5"

# Define Global Arrays
declare -ag FIND_PATH=();
declare -ag MENCODER_ADDITIONAL_ARRAY=();
declare -ag FFMPEG_OPT=("-c:v" "libx264" "-pix_fmt" "yuv420p" "-movflags" "faststart");

# Define Global Boolean Variables
declare -ig BOL_FILENAME=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_FFMPEG=$FALSE
declare -ig BOL_ENABLE_ROOT=$FALSE

# Define Global Integer Variables
declare -i  RETVAL=$SUCCESS
declare -ig EXIT_VAL=$RETVAL
declare -ig INDEX_VAL=-1
declare -ig PATH_INDEX=-1
declare -ig VAR_WAIT=1
declare -ig MENCODER_ADDITIONAL_ARRAY_INDEX=${#MENCODER_ADDITIONAL_ARRAY[@]}

# Define Directoy Prefix String Variables
export USER_PREFIX="$USR_PREFIX"

# Define Binary Variables
export FIND_BIN="$USER_PREFIX$BIN_PREFIX/find"
export TEST_BIN="$BIN_PREFIX/true"

# Define Option Variables
export OUT_EXT="out"
export FIND_OPT="-iname"
export FIND_PATH=""
export EXT_OPT=""

# Define MENCODER Boolean Variabled
declare -ig BOL_XVIDLO_PASS1=$FALSE
declare -ig BOL_XVIDLO_PASS2=$FALSE
declare -ig BOL_XVIDHI_PASS1=$FALSE
declare -ig BOL_XVIDHI_PASS2=$FALSE
declare -ig BOL_X264HI_PASS1=$FALSE
declare -ig BOL_X264HI_PASS2=$FALSE
declare -ig BOL_X264LO_PASS1=$FALSE
declare -ig BOL_X264LO_PASS2=$FALSE
declare -ig BOL_ALT_HI_PASS1=$FALSE
declare -ig BOL_ALT_HI_PASS2=$FALSE

function SHOW_IN_OUT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    SHOW_DATE_TIME; echo -e $COLOR_LT_BLUE"[Info] "$COLOR_LT_GREEN"Input File:\t"$COLOR_YELLOW"$INPUT_FILES"$COLOR_NORMAL
    SHOW_DATE_TIME; echo -e $COLOR_LT_BLUE"[Info] "$COLOR_LT_GREEN"Output File:\t"$COLOR_YELLOW"$OUTPUT_FILE"$COLOR_NORMAL"\n\n"
  fi
  return $SUCCESS
};

function FFMPEG_ENCODE()
{
  export OUTPUT_FILE="${INPUT_FILES%.*}.$OUT_EXT"
  export COMMAND=$FFMPEG_BIN

  SHOW_IN_OUT
  if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e "Executing: $FFMPEG_BIN -i $INPUT_FILES ${FFMPEG_OPT[@]} $OUTPUT_FILE"; fi
  printf "%b" $CC; $FFMPEG_BIN -i "$INPUT_FILES" ${FFMPEG_OPT[@]} "$OUTPUT_FILE"
  export RETVAL=$?
  printf "%b" $CN
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi

  return $?
};

function AV_ENCODE()
{
  declare -i BOL_ENABLE=$FALSE
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1
  declare -i MENCODER_ADDITIONAL_ARRAY_INDEX=${#MENCODER_ADDITIONAL_ARRAY[@]}

  export OUTPUT_FILE="${INPUT_FILES%.*}.$OUT_EXT"
  export COMMAND=$MENCODER_BIN
  SHOW_IN_OUT
  INIT_ARRAYS
  for TEMP_BOL in ${MENCODER_ENABLE_ARRAY[@]}; do
    ((INDEX++))
    BOL_ENABLE=$((TEMP_BOL))
    MENCODER_OPT="${MENCODER_OPTION_ARRAY[$((INDEX))]}"
    MENCODER_OUT="${MENCODER_OUTPUT_ARRAY[$((INDEX))]}"
    if [ $MENCODER_ADDITIONAL_ARRAY_INDEX -gt 0 ]; then MENCODER_OPT="$MENCODER_OPT ${MENCODER_ADDITIONAL_ARRAY[@]}"; fi
    if [ $BOL_ENABLE -eq $TRUE ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $COLOR_LT_BLUE"Executing: "$COLOR_YELLOW"$MENCODER_BIN $INPUT_FILES $MENCODER_OPT -o $MENCODER_OUT"$COLOR_NORMAL; fi
      printf "%b" $CC; $MENCODER_BIN "$INPUT_FILES" $MENCODER_OPT "-o" "$MENCODER_OUT"
      export RETVAL=$?
      printf "%b" $CN
      if [ $BOL_LOG_RESULTS -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
    fi
  done
  return $RETVAL
};

function INIT_ARRAYS()
{
  declare -ag MENCODER_OPTION_ARRAY=( \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac pcm " \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts preset=medium " \
 "-nosub -noautosub -of lavf -lavfopts format=mp4 -oac lavc -ovc lavc -lavcopts aglobal=1:vglobal=1:acodec=libfaac:vcodec=mpeg4:abitrate=128:vbitrate=640:keyint=250:mbd=1:vqmax=10:lmax=10:vpass=1:turbo -af lavcresample=44100,volnorm=1 -vf harddup,scale=720:480 " \
 "-nosub -noautosub -of lavf -lavfopts format=mp4 -oac lavc -ovc lavc -lavcopts aglobal=1:vglobal=1:acodec=libfaac:vcodec=mpeg4:abitrate=128:vbitrate=640:keyint=250:mbd=1:vqmax=10:lmax=10:vpass=2 -af lavcresample=44100,volnorm=1 -vf harddup,scale=720:480 " \
 "-nosub -noautosub -ovc x264 -x264encopts pass=1:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac pcm " \
 "-nosub -noautosub -ovc x264 -x264encopts pass=2:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac copy " \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000 -ofps 30 -vf scale=720:480 -af volnorm=1 -nosound " \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000 -ofps 30 -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts  cbr:br=64:vol=2 " \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac pcm " \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts cbr:br=192 " );

  declare -ag MENCODER_OUTPUT_ARRAY=(	"/dev/null" "$OUTPUT_FILE" "$OUTPUT_FILE" "$OUTPUT_FILE" \
					"/dev/null" "$OUTPUT_FILE" "/dev/null" "$OUTPUT_FILE" \
					"/dev/null" "$OUTPUT_FILE" );

  declare -ag MENCODER_ENABLE_ARRAY=(	"$BOL_XVIDLO_PASS1" "$BOL_XVIDLO_PASS2" "$BOL_X264HI_PASS1" "$BOL_X264HI_PASS2" \
					"$BOL_X264LO_PASS1" "$BOL_X264LO_PASS2" "$BOL_XVIDHI_PASS1" "$BOL_XVIDHI_PASS2" \
					"$BOL_ALT_HI_PASS1" "$BOL_ALT_HI_PASS2");

  return ${#MENCODER_OPTION_ARRAY[@]}
};

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] --help\n"
    exit $EXIT_VAL
fi

function do_HELP()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options]\n"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--help" "Show This Help Section" "--debug" "Show Debug Information"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--verbose" "Output More Details" "--quiet" "Don't Output Anything"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--wait=X" "Wait X Sec Between Commands" "--no-wait" "Don't Wait Between Commands"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--file=<name>" "File Name or Pattern" "--path=<path>" "Search Path <path>"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--xvidlo" "XVID Lo Encoding" "--xvidhi" "XVID Hi Encoding"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--x264lo" "X264 Lo Encoding" "--x264hi" "X264 Hi Encoding"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--alt" "Alternate XVID" "--ffmpeg" "Use FFMPEG for Encoding"
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--test" "Enable Test Mode" "--enable-root" "Allow Root User"
  echo -e "\n"
  exit $SUCCESS
};


for i in "$@"
do
case $i in
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
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export MENCODER_BIN="$TEST_BIN"
	export FFMPEG_BIN="$TEST_BIN"
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
--file=*)
	export BOL_FILENAME=$TRUE
        export FILENAME="${i#*=}"
	;;
--path=*)
	((PATH_INDEX++))
        FIND_PATH[$((PATH_INDEX))]="${i#*=}"
        ;;
'--xvidlo')
	export BOL_ENABLE=$TRUE
	export BOL_XVIDLO_PASS1=$TRUE
	export BOL_XVIDLO_PASS2=$TRUE
	export OUT_EXT="avi"
	;;
'--xvidhi')
        export BOL_ENABLE=$TRUE
        export BOL_XVIDHI_PASS1=$TRUE
        export BOL_XVIDHI_PASS2=$TRUE
	export OUT_EXT="avi"
        ;;
'--alt')
	export BOL_ENABLE=$TRUE
	export BOL_ALT_HI_PASS1=$TRUE
	export BOL_ALT_HI_PASS2=$TRUE
	export OUT_EXT="avi"
	;;
'--x264lo')
        export BOL_ENABLE=$TRUE
	export BOL_X264LO_PASS1=$TRUE
	export BOL_X264LO_PASS2=$TRUE
	export OUT_EXT="mp4"
	;;
'--x264hi')
        export BOL_ENABLE=$TRUE
        export BOL_X264HI_PASS1=$TRUE
        export BOL_X264HI_PASS2=$TRUE
	export OUT_EXT="mp4"
        ;;
'--ffmpeg')
	export BOL_ENABLE=$TRUE
	export BOL_FFMPEG=$TRUE
	export OUT_EXT="mp4"
	;;
'--copy-audio')
	FFMPEG_INDEX=${#FFMPEG_OPT[@]}
	FFMPEG_OPT[$((FFMPEG_INDEX))]="-c:a"
	((FFMPEG_INDEX++))
	FFMPEG_OPT[$((FFMPEG_INDEX))]="copy"
	;;
'--veryfast')
	FFMPEG_INDEX=${#FFMPEG_OPT[@]}
        FFMPEG_OPT[$((FFMPEG_INDEX))]="-preset"
        ((FFMPEG_INDEX++))
        FFMPEG_OPT[$((FFMPEG_INDEX))]="veryfast"
	;;
'--veryslow')
        FFMPEG_INDEX=${#FFMPEG_OPT[@]}
        FFMPEG_OPT[$((FFMPEG_INDEX))]="-preset"
        ((FFMPEG_INDEX++))
        FFMPEG_OPT[$((FFMPEG_INDEX))]="veryslow"
        ;;
'--lossless')
        FFMPEG_INDEX=${#FFMPEG_OPT[@]}
        FFMPEG_OPT[$((FFMPEG_INDEX))]="-crf"
        ((FFMPEG_INDEX++))
        FFMPEG_OPT[$((FFMPEG_INDEX))]="0"
	;;
'--enable-root')
	export BOL_ENABLE_ROOT=$TRUE
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
*)
        FFMPEG_INDEX=${#FFMPEG_OPT[@]}
        FFMPEG_OPT[$((FFMPEG_INDEX))]="$i"
	MENCODER_ADDITIONAL_ARRAY_INDEX=${#MENCODER_ADDITIONAL_ARRAY[@]}
	MENCODER_ADDITIONAL_ARRAY[$((MENCODER_ADDITIONAL_ARRAY_INDEX))]="$i"
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_FILENAME -ne $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_ENABLE -ne $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi
CHECK_ROOT_USER

if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $COLOR_LT_BLUE"[Debug] "$COLOR_YELLOW"$FIND_BIN" "${FIND_PATH[@]}" "$FIND_OPT" "$FILENAME"$COLOR_NORMAL; fi
while IFS= read TEMP_NAME; do
  export INPUT_FILES="$TEMP_NAME"
  if [ $BOL_FFMPEG -eq $TRUE ]; then
    FFMPEG_ENCODE
    export RETVAL=$?
  else
    AV_ENCODE
    export RETVAL=$?
  fi
  export EXIT_VAL=$RETVAL
done < <($FIND_BIN "${FIND_PATH[@]}" "$FIND_OPT" "$FILENAME")

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
exit $EXIT_VAL