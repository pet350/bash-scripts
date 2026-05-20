#!/bin/bash

if [ ${#TRUE}	-eq 0 ]; then /bin/true;  declare -i TRUE=$?;	fi
if [ ${#FALSE}	-eq 0 ]; then /bin/false; declare -i FALSE=$?;	fi
declare -i OPT_SELECT=0;

function HELP()
{
	echo -e "--file=<filename>\tInput filename (or Environment Variable INPUT_FILE)"
	echo -e "--cut=<seconts>\t\tTime in Seconds to cut from the end of media (or Environment Variable CUT_SEC)"
	echo -e "--out-path=<pathname>\tOptional select directory to wite output files"
	echo -e "--encode-aac\t\tReencode the video x264 / AAC"
	echo -e "--encode-mp3\t\tReencode the video x264 / MP3"
	return  0;
};

for OPTION in $@; do
  case $OPTION in
    --file=*)
	INPUT_FILE="${OPTION#*=}"
	;;
    --cut=*)
	CUT_SEC="${OPTION#*=}"
	;;
    --out-path=*)
	OUT_PATH="${OPTION#*=}"
	;;
    --help)
	HELP
	exit 0
	;;
    --encode-aac)
	OPT_SELECT=1
	;;
    --encode-mp3)
	OPT_SELECT=2
	;;
    *)
	echo -e "Ignoring unknown option: $OPTION"
	;;
  esac
done

if [ ${#CUT_SEC}	-eq 0 ]; then echo -e "No time to cut specified!";	exit 0;	fi
if [ ${#INPUT_FILE}	-eq 0 ]; then echo -e "No input file!";			exit 0; fi

DURATION=$(ffprobe -i "$INPUT_FILE" -show_entries format=DURATION -v quiet -of csv="p=0")
NEW_DURATION=$(echo "$DURATION - $CUT_SEC" | bc)

OUTPUT_FILE="${INPUT_FILE%.*}_cut_${CUT_SEC}_Seconds.mp4"
if [ ${#OUT_PATH}	-ne 0 ]; then
    OUTPUT_FILE="${OUTPUT_FILE##*/}"
    OUTPUT_FILE="$OUT_PATH/$OUTPUT_FILE"
fi
declare -a ENC_OPT=("-c copy" " -c:v libx264 -c:a aac" " -c:v libx264 -c:a mp3");
FFOPTS="${ENC_OPT[$OPT_SELECT]}"

echo -e "Input File:\t$INPUT_FILE"
echo -e "Output File:\t$OUTPUT_FILE"
echo -e "Duration:\t$DURATION"
echo -e "Seconds to cut:\t$CUT_SEC"
echo -e "New Duration:\t$NEW_DURATION"

echo -e "Executing:\tffmpeg -i $INPUT_FILE -t $NEW_DURATION  $FFOPTS  $OUTPUT_FILE"

ffmpeg -i "$INPUT_FILE" -t "$NEW_DURATION" $FFOPTS  "$OUTPUT_FILE"
