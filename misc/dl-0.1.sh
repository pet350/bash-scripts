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


declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.3"
declare -x AUTHOR="Peter Talbott"
declare -x MODIFIED="2023-09-12"

declare -a BOL=('0' '0');
declare -a NAMES=();
declare -a URL_ARRAY=();
declare -a NAME_ARRAY=();
declare -a GUYS=("cumshot" "cum-shot" "boy" "his" "-male" "-man" "-men" "husband"	\
		 "dick" "guy" "brother" "son" "stepson" "cock" "penis-" "uncle" "him"	\
		 "jiz" "he-" "trans" "wang" "shlong" "blowjob" "handjob" "footjob"	\
		 "balls" "johnson" "erection" "testicle" "trans" "trannies" "shemale"	);

declare -i INDEX=-1
declare -i URL_INDEX=-1
declare -i NAME_ARRAY_INDEX=-1
declare -i START_PAGE=1
declare -i END_PAGE=5

# Define a few more binary variables
for DATA in curl  egrep chown sleep find; do
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


if [ ${#BASE_URL}	-eq 0 ]; then declare -x BASE_URL="https://www.pornhub.com";					fi
if [ ${#CH_OWNER}	-eq 0 ]; then declare -x CH_OWNER="www-data";							fi
if [ ${#CH_GROUP}	-eq 0 ]; then declare -x CH_GROUP="streaming";							fi
if [ ${#MV_PREFIX}	-eq 0 ]; then declare -x MV_PREFIX="/var/lib/jellyfin/catalog/porn";				fi
if [ ${#OPTS}		-eq 0 ]; then declare -x OPTS="--embed-thumbnail --geo-bypass --force-ipv4 --yes-playlist --retries 20 --restrict-filenames --continue --no-overwrites --no-warnings --console-title --merge-output-format mp4 --no-check-certificate";	fi
if [ ${#BIN}		-eq 0 ]; then declare -x BIN="/usr/bin/yt-dlp";							fi
if [ ${#PAGE}		-eq 0 ]; then declare -i PAGE=1;								fi

function SHOW_DEFAULT()
{
    SHOW_HEADER
    echo -e "Nothing to do! for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

function  NO_MEN()
{
    for LIST in ${GUYS[@]}; do
        if [ ${#EXCLUDE_LIST} -eq 0 ]; then
            export EXCLUDE_LIST="$LIST"
        else
            export EXCLUDE_LIST="$EXCLUDE_LIST|$LIST"
        fi
    done
    return $SUCCESS
};


function DIVIDER()
{
    declare -i COUNT=0
    declare -i MAX=110
    while [ $COUNT -lt $MAX ]; do
        ((COUNT++))
        printf "-"
    done
    printf "\n"
    return $SUCCESS
};

function GET_NAME_ARRAY()
{
    DIVIDER
    echo -e "Populating Name Aray"
    NAME_ARRAY[$((INDEX))]=$($BIN $OPTS --get-filename $DATA; declare -a RETVAL=$?)
    printf "Page: %-2s\nINDEX: %-2s\nURL: %-78s\nName: %-90s\n" "$PAGE" "$INDEX" "$DATA" "${NAME_ARRAY[$((INDEX))]}" 
    DIVIDER
    return $RETVAL
};

function GET_URL_ARRAY()
{
  echo -e "Populating URL Array"
  declare -x TEMP_NAME=""
  while IFS= read LINE; do
    BOL[0]=$FALSE
    BOL[1]=$FALSE
    for WORD in $LINE; do
        if [ ${BOL[0]} -eq $TRUE ]; then
            if [ ${BOL[1]} -eq $TRUE ]; then
                #printf "%s " $WORD
		/bin/true
            fi
            case ${WORD:0:4} in
                'href')
		    TEMP=${WORD:5}
		    if [ "$TEMP" != '"javascript:void(0)"' ] && [ "$TEMP" != "$TEMP_NAME" ]; then
                       ((INDEX++))
		       NAMES[$((INDEX))]=${WORD:5}
		       TEMP_NAME=${WORD:5}
                    fi
		    #printf "%s " ${WORD:5}
                    BOL[1]=$TRUE
                    ;;
            esac
            LEN=${#WORD}
            case ${WORD:$((LEN-1))} in
                '>')
                    #printf "\n"
                    BOL[0]=$FALSE
                    BOL[1]=$FALSE
                    ;;
            esac

        fi
        case $WORD in
            '<a')
                BOL[0]=$TRUE
                ;;
            '">')
                # printf "\n"
                BOL[0]=$FALSE
		BOL[1]=$FALSE
                ;;
        esac
    done
  done < <(curl "$BASE_URL/video/search?search=$SEARCH&page=$PAGE" 2>/dev/null; declare -i RETVAL=$?)

  for DATA in ${NAMES[@]}; do
    TEMP=${DATA:1}
    LEN=${#TEMP}
    TEMP=${TEMP:0:$((LEN-1))}
    case ${TEMP:0:15} in
        '/view_video.php')
		((URL_INDEX++))
		URL_ARRAY[$((URL_INDEX))]="$BASE_URL$TEMP"
		;;
    esac
  done
  echo -e "Stored ${#URL_ARRAY[@]} URLs"
  return $RETVAL
};

function DOWNLOAD()
{
  declare INDEX=-1
  for DATA in ${URL_ARRAY[@]}; do
    ((INDEX++))
    GET_NAME_ARRAY
    declare -i BOL_DL=$TRUE
    for FILE_NAME in ${NAME_ARRAY[@]}; do
	BOL_DL=$TRUE
        TEMP=${FILE_NAME:0:1}
        TEMP="$MV_PREFIX/${TEMP^^}"
        TARGET="$TEMP/$FILE_NAME"
	ls "$TARGET" >/dev/null 2>/dev/null
	TEST=$?
        NOMEN=$(echo "$TARGET" | egrep -v $EXCLUDE_LIST | wc -l)
	if [ $TEST -eq $SUCCESS ] || [ $NOMEN -eq 0 ]; then BOL_DL=$FALSE; fi
    done
    if [ $BOL_DL -eq $TRUE ]; then
        echo -e "Attempt to download from URL: $DATA"
        echo -e "Target file name: ${NAME_ARRAY[$((INDEX))]}"
        $BIN $OPTS $VERBOSE "$DATA"
        declare -i RETVAL=$?
	if [ $RETVAL -eq $SUCCESS ]; then MOVE_FILE; fi
    else
        echo -e "Skipping download, Either File exists: $TARGET or it was on the Exclude list\n"
        ls -lh "$TARGET"
    fi
  done
  return $RETVAL
};

function MOVE_FILE()
{
  DIVIDER
  printf "Changing ownership and moving files"
  for DATA in $(ls *.mp4); do
    chown -v $CH_OWNER:$CH_GROUP $DATA
    TEMP=${DATA:0:1}
    TEMP="$MV_PREFIX/${TEMP^^}"
    mv -v $DATA $TEMP
    declare -i RETVAL=$?
  done
  DIVIDER
  return $RETVAL
};

if [ ${#SEARCH}         -eq 0 ]; then SHOW_DEFAULT; exit $SUCCES;  fi
declare -i PAGE=$START_PAGE
NO_MEN
while [ $PAGE -ne $END_PAGE ]; do
    DIVIDER
    printf "Page %-2s of %-2s\n" $PAGE $END_PAGE
    GET_URL_ARRAY
    DOWNLOAD
    MOVE_FILE
    ((PAGE++))
done
