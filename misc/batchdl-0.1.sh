#!/bin/bash
# Script to downlad a list from youtube as mp3s
# By: Pter Talbott

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh) $XEN_FUNCTIONS; do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

# Define global binary variables
export DL_BIN="/usr/local/bin/youtube-dl"

# Define global arrays
declare -ag FILE_LIST=();
declare -ag DL_OPTS=( "-f" "140" "-x" "--audio-format=mp3" "--continue" );

declare -ig FILE_LIST_COUNT=${#FILE_LIST[@]}

function BATCH_DOWNLOAD()
{
  declare -i FUNCT_RETURN=$FAILUE
  declare -i COUNT=0
  for DL_URL in $DL_LIST; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "\nDownload Count: %s\n" $COUNT; fi
    TEMP=$($DL_BIN ${DL_OPTS[@]} "${DL_URL%&list=*}" --get-filename 2>/dev/null); FILE_NAME="${TEMP%.m4a*}"; unset TEMP
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Full URL: %s\n" $DL_URL; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Download URL: %s\n" ${DL_URL%&list=*}; fi
    printf "Attempting to download: %s " "$FILE_NAME"
    $DL_BIN ${DL_OPTS[@]} "${DL_URL%&list=*}" >/dev/null 2>/dev/null
    FUNCT_RETURN=$?
    if [ $FUNCT_RETURN -eq $SUCCESS ]; then
      printf "Success!\n"
    else
      printf "Failure!\n"
    fi
    $SLEEP_BIN 2
  done
  return $FUNCT_RETURN
};


for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
*)
	FILE_LIST_COUNT=${#FILE_LIST[@]}
        FILE_LIST[$((FILE_LIST_COUNT))]="$i"
	;;
esac
done

FILE_LIST_COUNT=${#FILE_LIST[@]}
if [ $BOL_HELP -eq $TRUE ] || [ $FILE_LIST_COUNT -lt 1 ]; then DO_HELP; fi

while IFS= read LINE; do
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Adding: $LINE to URL List"; fi
  export DL_LIST="$DL_LIST $LINE"
done < <(cat ${FILE_LIST[@]})

BATCH_DOWNLOAD | tee -a /tmp/dl/log
exit $?
