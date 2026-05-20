#!/bin/bash
# Script to downlad a list from youtube as mp3s
# By: Pter Talbott

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.4"

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
export DEV_NULL="/dev/null"
export DEV_STDOUT="/dev/stdout"

# Define global arrays
declare -ag FILE_LIST=();
declare -ag DL_OPTS=( "-f" "140" "-x" "--audio-format=mp3" "--continue" );
declare -ag HELP_ARRAY=( "--version" "Display Version information and exit.\n" \
  "-h" "or --help Display this help message.\n" "--wait=NN" "Wait NN Seconds between downloads.\n" "-v" \
  "or --verbose Display more information.\n" "-d" "or --debug Display debug information.\n" \
  "--append=XX" "Append XX to download options.\n" "--name-only" "Just display filenames.\n" \
  "-nd" "or --no-defaults Do not add default string.\n" "[File]" "Filename with URL list." );

# Define global integer variables
declare -ig URL_TOTAL=0
declare -ig START_COUNT=0
declare -ig FILE_LIST_COUNT=${#FILE_LIST[@]}
declare -ig DL_OPTS_COUNT=${#DL_OPTS[@]}
declare -ig BOL_DL=$TRUE

# Define these variables only if thier not already set by environment
if [ ${#VAR_WAIT}	-eq 0 ]; then declare -ig VAR_WAIT=2;		fi
if [ ${#BOL_WAIT}	-eq 0 ]; then declare -ig BOL_WAIT=$TRUE;	fi
if [ ${#MSG_OUT}	-eq 0 ]; then export MSG_OUT="$DEV_NULL";	fi
if [ ${#ERR_OUT}	-eq 0 ]; then export ERR_OUT="$DEV_NULL";	fi

function BATCH_DOWNLOAD()
{
  declare -i FUNCT_RETURN=$FAILUE
  declare -i COUNT=0
  for DL_URL in $DL_LIST; do
    ((COUNT++))
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      printf "%b" $CLB; printf "\nDownload Count: "
      printf "%b" $CY;  printf "%s of %s\n" $COUNT $URL_TOTAL
      printf "%b" $CN
    fi
    TEMP=$($DL_BIN ${DL_OPTS[@]} "${DL_URL%&list=*}" --get-filename 2>/dev/null); FILE_NAME="${TEMP%.m4a*}"; unset TEMP
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      printf "%b" $CLB; printf "Full URL: "
      printf "%b" $CY;  printf "%s\n" $DL_URL
      printf "%b" $CLB; printf "Download URL: "
      printf "%b" $CY;  printf "%s\n" ${DL_URL%&list=*}
    fi
    printf "%b" $CLB; printf "Attempting to download: "
    printf "%b" $CY;  printf "%s " "$FILE_NAME"
    printf "%b" $CC
    if [ $BOL_DL -eq $TRUE ]; then
      $DL_BIN ${DL_OPTS[@]} "${DL_URL%&list=*}" >$MSG_OUT 2>$ERR_OUT
      FUNCT_RETURN=$?
      printf "%b" $CN
      if [ $FUNCT_RETURN -eq $SUCCESS ]; then
        printf "%b" $CLG; printf "Success!\n"
      else
        printf "%b" $CLR; printf "Failure!\n"
      fi
    fi
    printf "%b\n" $CN
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  done
  return $FUNCT_RETURN
};


for i in "$@"; do
  case $i in
    '-h' | '--help')
	export BOL_HELP=$TRUE
	;;
    '-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	export MSG_OUT="$DEV_STDOUT"
	;;
    '-d' | '--debug')
	export BOL_DEBUG=$TRUE
	export BOL_VERBOSE=$TRUE
	export MSG_OUT="$DEV_STDOUT"
	export ERR_OUT="$DEV_STDOUT"
	;;
    '--no-wait')
	export BOL_WAIT=$FALSE
	;;
    '--name-only')
	export BOL_VERBOSE=$TRUE
	export BOL_DEBUG=$FALSE
	export BOL_WAIT=$FALSE
	export BOL_DL=$FALSE
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
    '-nd' | '--no-defaults')
	DL_OPTS=( "--continue" );
	;;
    -w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
        ;;
    --append=*)
	DL_OPTS_COUNT=${#DL_OPTS[@]}
	DL_OPTS[$((DL_OPTS_COUNT))]="${i#*=}"
	;;
    --start=*)
	export START_COUNT="${i#*=}"
	;;
    *)
	if [ -f "$i" ]; then
	  FILE_LIST_COUNT=${#FILE_LIST[@]}
          FILE_LIST[$((FILE_LIST_COUNT))]="$i"
	else
	  echo -e "Error filename $i does not exist!"
	fi
	;;
  esac
done

FILE_LIST_COUNT=${#FILE_LIST[@]}
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi
if [ $FILE_LIST_COUNT -lt 1 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { options } Filename1 Filename2 --help"
    exit $SUCCESS
fi

# Assemble DL_LIST
while IFS= read LINE; do
  ((URL_TOTAL++))
  if [ $URL_TOTAL -gt $((START_COUNT-1)) ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "URL# $URL_TOTAL: $LINE added to download List"; fi
    export DL_LIST="$DL_LIST $LINE"
  fi
done < <(cat ${FILE_LIST[@]})

BATCH_DOWNLOAD | tee -a /tmp/dl.log
exit $?
