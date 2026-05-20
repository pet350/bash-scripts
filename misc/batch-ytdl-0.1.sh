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
export MODIFIED="2022-09-11"

# Define a few more binary variables
for DATA in curl yt_dlp sleep find; do
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

for OPTIONS in $@; do
    case $OPTIONS in
        --debug)			declare -i BOL_DEBUG=$TRUE;;
	--verbose)			declare -i BOL_VERBOSE=$TRUE;;
        --help)				declare -i BOL_HELP=$TRUE;;
	--base-url=*)			export BASE_URL="${OPTIONS#*=}";;
	--search=*)			export SEARCH_ITEM="${OPTIONS#*=}";;
    esac
done

# Declare Strings if not already defined
if [ ${#BASE_URL}	-eq 0 ]; then 	export BASE_URL="https://www.youporn.com";			fi
if [ ${#SEARCH_STRING}	-eq 0 ]; then 	export SEARCH_STRING="/search/?search-btn=&query=";		fi
if [ ${#WATCH_STRING}	-eq 0 ]; then 	export WATCH_STRING="/watch";					fi
if [ ${#DLOPTS}		-eq 0 ]; then	export DLOPTS="--embed-thumbnail --geo-bypass --force-ipv4 \
						--yes-playlist --retries 20 --restrict-filenames   \
						--continue --no-overwrites --no-warnings           \
						--console-title --merge-output-format mp4          \
						--no-check-certificate --verbose";			fi
# Define Arrays if not defioned already
if [ ${#LIST_ARRAY[@]}	-eq 0 ]; then 	declare -g -a LIST_ARRAY=();					fi

function GET_LIST_TOTAL()
{
    declare -i INDEX_TOTAL=-1
    declare -i RETVAL=$FAILURE

    while IFS= read LINE; do
        ((INDEX_TOTAL++))
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM 2>/dev/null | $GREP_BIN $WATCH_STRING)
    echo $INDEX_TOTAL
    if [ $INDEX_TOTAL -gt 1 ]; then RETVAL=$SUCCESS;							fi
    return $RETVAL
};

# Function will populate
function GET_LIST_ARRAY()
{
    declare -i LIST_INDEX=-1
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)
    declare -i RETVAL=$FAILURE

    while IFS= read LINE; do
        ((LIST_INDEX++))
        TEMP="${LINE#*href="\""}"
        TEMP="${TEMP%/\"*}"
        LIST_ARRAY[$((LIST_INDEX))]="$TEMP"
        if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Storing Search Result: $LIST_INDEX of $LIST_TOTAL\t$TEMP";	fi
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM 2>/dev/null | $GREP_BIN $WATCH_STRING)
    if [ $LIST_INDEX -gt 1 ]; then RETVAL=$SUCCESS;                                                    fi
    return $RETVAL
};

function DL()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)

    for SUFFIX in ${LIST_ARRAY[@]}; do
        ((INDEX++))
        export FULL_URL="$BASE_URL$SUFFIX"
        if [ $INDEX -gt 0 ]; then
		if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Processing URL %-3s of %-3s: %s\n" $INDEX $LIST_TOTAL "$FULL_URL";	fi
		$YT_DLP_BIN $DLOPTS $FULL_URL
		RETVAL=$?
		echo -e "\n"
        fi
    done
};

GET_LIST_ARRAY
if [ ${#SEARCH_ITEM} -ne 0 ] && [ $? -eq $SUCCESS ]; then DL; EXIT_VAL=$?; fi
exit $EXIT_VAL

