#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.2"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEMP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_FILENAME=$FALSE
declare -ig BOL_LOG_RESULTS=$TRUE

# Define Global SYSCTL Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RESTART=$FALSE
declare -ig BOL_RELOAD=$FALSE
declare -ig BOL_STATUS=$TRUE
declare -ig BOL_MASK=$FALSE
declare -ig BOL_UNMASK=$FALSE
declare -ig BOL_ENABLE=$FALSE
declare -ig BOL_TEST=$FALSE

# Define Global Integer Variables
declare -i  RETVAL=$SUCCESS
declare -ig EXIT_VAL=$RETVAL
declare -ig INDEX_VAL=-1
declare -ig PATH_INDEX=-1
declare -ig VAR_WAIT=1
declare -ag FIND_PATH=();

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Binary Variables
export FIND_BIN="$USER_PREFIX$BIN_PREFIX/find"
export MENCODER_BIN="$USER_PREFIX$BIN_PREFIX/mencoder"
export SLEEP_BIN="$BIN_PREFIX/sleep"

# Define Option Variables
export OUT_EXT="out"
export FIND_OPT="-name"
export FIND_PATH=""
export EXT_OPT=""

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

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$EXT_OPT Success!"
  else
    log_failure_msg "$EXT_OPT Failure!"
  fi
  return $RETVAL
};

function AV_ENCODE()
{
  declare -i BOL_ENABLE=$FALSE
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1

  export OUTPUT_FILE="${INPUT_FILES%.*}.$OUT_EXT"
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Input File:\t\t$INPUT_FILES\nOutput File:\t\t$OUTPUT_FILE\n\n"; fi
  INIT_ARRAYS
  for TEMP_BOL in ${MENCODER_ENABLE_ARRAY[@]}; do
    ((INDEX++))
    BOL_ENABLE=$((TEMP_BOL))
    MENCODER_OPT="${MENCODER_OPTION_ARRAY[$((INDEX))]}"
    MENCODER_OUT="${MENCODER_OUTPUT_ARRAY[$((INDEX))]}"
    if [ $BOL_ENABLE -eq $TRUE ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $MENCODER_BIN $INPUT_FILES $MENCODER_OPT $MENCODER_OUT"; fi
      $MENCODER_BIN "$INPUT_FILES" $MENCODER_OPT "$MENCODER_OUT"
      export RETVAL=$?
      if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
    fi
  done
  return $RETVAL
};

function INIT_ARRAYS()
{
  declare -ag MENCODER_OPTION_ARRAY=( \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac pcm -o" \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts preset=medium -o" \
 "-nosub -noautosub -of lavf -lavfopts format=mp4 -oac lavc -ovc lavc -lavcopts aglobal=1:vglobal=1:acodec=libfaac:vcodec=mpeg4:abitrate=128:vbitrate=640:keyint=250:mbd=1:vqmax=10:lmax=10:vpass=1:turbo -af lavcresample=44100,volnorm=1 -vf harddup,scale=720:480 -o" \
 "-nosub -noautosub -of lavf -lavfopts format=mp4 -oac lavc -ovc lavc -lavcopts aglobal=1:vglobal=1:acodec=libfaac:vcodec=mpeg4:abitrate=128:vbitrate=640:keyint=250:mbd=1:vqmax=10:lmax=10:vpass=2 -af lavcresample=44100,volnorm=1 -vf harddup,scale=720:480 -o" \
 "-nosub -noautosub -ovc x264 -x264encopts pass=1:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac pcm -o" \
 "-nosub -noautosub -ovc x264 -x264encopts pass=2:bitrate=1000 -vf scale=720:480 -af volnorm=1 -oac copy -o" \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000 -ofps 30 -vf scale=720:480 -af volnorm=1 -nosound -o" \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000 -ofps 30 -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts  cbr:br=64:vol=2 -o" \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac pcm -o" \
 "-nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts cbr:br=192 -o" );

  declare -ag MENCODER_OUTPUT_ARRAY=(	"/dev/null" "$OUTPUT_FILE" "$OUTPUT_FILE" "$OUTPUT_FILE" \
					"/dev/null" "$OUTPUT_FILE" "/dev/null" "$OUTPUT_FILE" \
					"/dev/null" "$OUTPUT_FILE" );

  declare -ag MENCODER_ENABLE_ARRAY=(	"$BOL_XVIDLO_PASS1" "$BOL_XVIDLO_PASS2" "$BOL_X264HI_PASS1" "$BOL_X264HI_PASS2" \
					"$BOL_X264LO_PASS1" "$BOL_X264LO_PASS2" "$BOL_XVIDHI_PASS1" "$BOL_XVIDHI_PASS2" \
					"$BOL_ALT_HI_PASS1" "$BOL_ALT_HI_PASS2");

  return ${#MENCODER_OPTION_ARRAY[@]}
};

if [ $(id -u) -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\n[WARNING] Shouldn't be ran as root"
fi

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
  printf "%-15s:\t%-26s\t|\t%-15s:\t%-26s\n" "--alt" "Alternate XVID" "" ""
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
	export MENCODER_BIN="$BIN_PREFIX/true"
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
esac
done

if [ $BOL_FILENAME -ne $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_ENABLE -ne $TRUE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] $FIND_BIN" "${FIND_PATH[@]}" "$FIND_OPT" "$FILENAME"; fi
while IFS= read TEMP_NAME; do
  export INPUT_FILES="$TEMP_NAME"
  AV_ENCODE
  export RETVAL=$?
  export EXIT_VAL=$RETVAL
done < <($FIND_BIN "${FIND_PATH[@]}" "$FIND_OPT" "$FILENAME")

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then LOG_RESULTS; fi
exit $EXIT_VAL