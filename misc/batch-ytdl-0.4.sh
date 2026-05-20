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
export VERSION="0.4"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-09-12"
export WORKING_PREFIX="$(pwd)"

# Define a few more binary variables
for DATA in curl yt_dlp chown sleep find; do
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

# Staticly defined Variables
export LENGTH_OPT="--get-duration"

# This binary is used to get the TARGET_FILENAME and DURATION (runtime) Only!
# Reason being, it will not get changed if program is in TEST mode
export YTDLP_BIN="$YT_DLP_BIN"

# Self Explanitory Function
function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

# Check Command Line for any arguments that may be present
for OPTIONS in $@; do
    case $OPTIONS in
	--version)			SHOW_HEADER;				exit $SUCCESS;;
        --debug | -d)			declare -i BOL_DEBUG=$TRUE;;
	--verbose | -v)			declare -i BOL_VERBOSE=$TRUE;		export VERBOSE="-v";;
        --help | -h)			declare -i BOL_HELP=$TRUE;;
	--test | -t)			declare -i BOL_TEST=$TRUE;;
	--list-only)			declare -i LIST_ONLY=$TRUE;;
	--no-length)			declare -i BOL_LENGTH=$FALSE;;
        --start-page=*)                 declare -i START_PAGE="${OPTIONS#*=}";;
        --end-page=*)                   declare -i END_PAGE="${OPTIONS#*=}";;
	--base-url=*)			export BASE_URL="${OPTIONS#*=}";;
	--search=*)			export SEARCH_ITEM="${OPTIONS#*=}";;
	--user=*)			export FILE_USER="${OPTIONS#*=}";;
	--group=*)			export FILE_GROUP=="${OPTIONS#*=}";;
	--prefix=*)			export STREAM_PREFIX="${OPTIONS#*=}";;
    esac
done

declare -a HELP_ARRAY=(	"---------------" "--------* Required *--------------------\n" "--search=XXX" "URL Search String (SEARCH_ITEM Variable)\n" \
			"---------------" "--------* Optional *--------------------\n" "--help" "(or -h) : Display this help message.\n" \
			"--verbose" "(or -v) : detailed output.\n" "--test" "(or -t) : Test mode does not download.\n" "--debug" "(or -d) : debug output.\n" \
			"---------------" "----------------------------------------\n" "--version" "Display version information\n" "---------------" \
			"----------------------------------------\n" "--start-page=NN" \
			"Page number to start at. (Default 1)\n" "--end-page=NN" "Page number to stop at. (Default 10)\n" "---------------" \
			"----------------------------------------\n" "--user=XXX" "Username to set the downloaded file to.\n" "--group=XXX" \
			"Group to set the downloaded file to.\n" "---------------" "----------------------------------------\n" "--prefix=XXX" \
			"Download Prefix.\n" "--base-url=XXX" "Base URL to download from.\n" "---------------" "----------------------------------------\n" \
			"--list-only" "Display all the names of what was found" );

# Declare Variables if not already defined
if [ ${#BOL_TEST}	-eq 0 ]; then	declare -i BOL_TEST=$FALSE;					fi
if [ ${#LIST_ONLY}      -eq 0 ]; then   declare -i LIST_ONLY=$FALSE;                                    fi
if [ ${#BOL_LENGTH}     -eq 0 ]; then   declare -i BOL_LENGTH=$TRUE;                                    fi
if [ $BOL_TEST    -eq   $TRUE ]; then	export YT_DLP_BIN=$TRUE_BIN;	export CHOWN_BIN=$TRUE_BIN;	fi
if [ ${#BASE_URL}	-eq 0 ]; then 	export BASE_URL="https://www.youporn.com";			fi
if [ ${#SEARCH_STRING}	-eq 0 ]; then 	export SEARCH_STRING="/search/?search-btn=&query=";		fi
if [ ${#WATCH_STRING}	-eq 0 ]; then 	export WATCH_STRING="/watch";					fi
if [ ${#PAGE_STRING}	-eq 0 ]; then	export PAGE_STRING="&page=";					fi
if [ ${#DLOPTS}		-eq 0 ]; then	export DLOPTS="--embed-thumbnail --geo-bypass --force-ipv4	\
						--yes-playlist --retries 20 --restrict-filenames  	\
						--continue --no-overwrites --no-warnings           	\
						--console-title --merge-output-format mp4          	\
						--no-check-certificate";				fi
if [ ${#FILE_USER}	-eq 0 ]; then	export FILE_USER="www-data";					fi
if [ ${#FILE_GROUP}	-eq 0 ]; then	export FILE_GROUP="streaming";					fi
if [ ${#STREAM_PREFIX}	-eq 0 ]; then	export STREAM_PREFIX="/opt/porn";				fi

# Define Arrays if not defioned already
if [ ${#LIST_ARRAY[@]}	 -eq 0 ]; then 	declare -g -a	LIST_ARRAY=();					fi
if [ ${#LENGTH_ARRAY[@]} -eq 0 ]; then  declare -g -a	LENGTH_ARRAY=();                                fi
if [ ${#START_PAGE}	 -eq 0 ]; then	declare -i	START_PAGE=1;					fi
if [ ${#END_PAGE}	 -eq 0 ]; then	declare -i	END_PAGE=10;					fi

# Chown ownership of TARGET_FILENAME if file exists
function CHANGE_OWNER()
{
    declare -i RETVAL=$FAILURE
    if [ -f $TARGET_FILENAME ]; then
        if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Executing: $CHOWN_BIN $VERBOSE $FILE_USER:$FILE_GROUP $TARGET_FILENAME"; fi
	$CHOWN_BIN $VERBOSE $FILE_USER:$FILE_GROUP $TARGET_FILENAME
        RETVAL=$?; COMMAND="$CHOWN_BIN"
        LOG_RESULTS
        echo -e "\n"
    else
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Not changing ownership of $TARGET_FILENAME, file does not exist!\n"; fi
    fi
    return $RETVAL
};

function MOVE_TARGET()
{
    declare -i RETVAL=$FAILURE
    if [ -f $TARGET_FILENAME ]; then
        if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Executing: mv $VERBOSE $TARGET_FILENAME $TARGET_PREFIX\n"; fi
	mv $VERBOSE $TARGET_FILENAME $TARGET_PREFIX
        RETVAL=$?; COMMAND="mv"
        LOG_RESULTS
        echo -e "\n"
    else
        if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Not moving $TARGET_FILENAME to $TARGET_PREFIX, file does not exist!\n"; fi
    fi
    return $RETVAL
};

# Get total number of download URLs
function GET_LIST_TOTAL()
{
    declare -i INDEX_TOTAL=-1
    declare -i RETVAL=$FAILURE

    while IFS= read LINE; do
        TEMP="${LINE#*href="\""}"
        TEMP="${TEMP%/\"*}"
        case "${TEMP:1:8}" in
                'porntags' | 'watch-hi')
                        $TRUE_BIN
                        ;;
                *)
			((INDEX_TOTAL++))
			;;
	esac
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM$PAGE_STRING$CURRENT_PAGE 2>/dev/null | $GREP_BIN $WATCH_STRING)
    echo $INDEX_TOTAL
    if [ $INDEX_TOTAL -gt 1 ]; then RETVAL=$SUCCESS;							fi
    return $RETVAL
};

# Function will populate LIST_ARRAY
function GET_LIST_ARRAY()
{
    declare -i LIST_INDEX=-1
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)
    declare -i RETVAL=$FAILURE

    while IFS= read LINE; do
        TEMP="${LINE#*href="\""}"
        TEMP="${TEMP%/\"*}"
        case "${TEMP:1:8}" in
		'porntags' | 'watch-hi')
			$TRUE_BIN
			;;
		*)
			((LIST_INDEX++))
			if [ $BOL_LENGTH -eq $TRUE ]; then TEMP_LENGTH=$($YTDLP_BIN $LENGTH_OPT $BASE_URL$TEMP); else TEMP_LENGTH="Unknown";	fi
        		LIST_ARRAY[$((LIST_INDEX))]="$TEMP"
			LENGTH_ARRAY[$((LIST_INDEX))]="TEMP_LENGTH"
			if [ $BOL_DEBUG -eq $TRUE  ] && [ $LIST_ONLY -eq $FALSE ]; then CLG_TEXT; printf "[Debug] ";			  fi
			if [ $BOL_DEBUG -eq $TRUE  ] && [ $LIST_ONLY -eq $TRUE  ]; then CLG_TEXT; printf "[Debug] [List Only] ";   	  fi
			if [ $BOL_DEBUG -eq $FALSE ] && [ $LIST_ONLY -eq $TRUE  ]; then CLG_TEXT; printf "[List Only] ";	 	  fi
			if [ $BOL_DEBUG -eq $TRUE  ] || [ $LIST_ONLY -eq $TRUE  ]; then CLB_TEXT; printf "Search Result: Page number: "; CY_TEXT; printf "%3s, " $CURRENT_PAGE; CLB_TEXT; printf "File Number:  "; CY_TEXT; printf "%3s / %-s, " $LIST_INDEX $LIST_TOTAL; CLB_TEXT; printf "Duration: "; CY_TEXT; printf "%8s, " $TEMP_LENGTH; CLB_TEXT; printf "Filename: "; CLR_TEXT; printf "%s\n" $TEMP; CN_TEXT;	fi
			;;
	esac
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM$PAGE_STRING$CURRENT_PAGE 2>/dev/null | $GREP_BIN $WATCH_STRING)
    if [ $LIST_INDEX -gt 1 ]; then RETVAL=$SUCCESS; 			                                                fi
    return $RETVAL
};

# Download all the URLs stored in LIST_ARRAY
function DL()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)

    for SUFFIX in ${LIST_ARRAY[@]}; do
        ((INDEX++))
        export FULL_URL="$BASE_URL$SUFFIX"
        if [ $INDEX -gt 0 ]; then
		export DURATION="${LENGTH_ARRAY[$((INDEX))]}"
		export TARGET_FILENAME=$($YTDLP_BIN $DLOPTS --get-filename $FULL_URL)
		export FIRST_LETTER=${TARGET_FILENAME:0:1}
		export FISRT_LETTER=${FIRST_LETTER^^}
		export TARGET_PREFIX="$STREAM_PREFIX/$FIRST_LETTER"
		if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Processing: Page %-3s URL %-3s of %-3s: %s\n" $CURRENT_PAGE $INDEX $LIST_TOTAL "$FULL_URL";	fi
		if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Target file: %s/%s\n" $TARGET_PREFIX $TARGET_FILENAME;					fi
		if [ ! -f "$TARGET_PREFIX"/"$TARGET_FILENAME" ]; then
			if [ $BOL_VERBOSE -eq $TRUE ] || [ $BOL_DEBUG   -eq $TRUE ]; then
				CLB_TEXT; printf "Filename: ";		CY_TEXT; printf "%s " "$TARGET_PREFIX"/"$TARGET_FILENAME"; CLB_TEXT; printf "Does NOT Exist, Proceding to Download\n"; CN_TEXT
				CLB_TEXT; printf "Download URL: ";	CY_TEXT; printf "%s\n" $FULL_URL; CN_TEXT
				CLB_TEXT; printf "Runtime: ";		CY_TEXT; printf "%s\n" $DURATION; CN_TEXT
			fi
			if [ $BOL_DEBUG   -eq $TRUE ]; then printf "[Debug] Executing: %s %s %s\n" $YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL;                                         fi
			$YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL
			RETVAL=$?; COMMAND="$YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL"
			LOG_RESULTS
			echo -e "\n"
			CHANGE_OWNER
			MOVE_TARGET
		else
			CLB_TEXT; printf "Target Exists! Skipping Download from: "; CC_TEXT; printf "%s!\n\n" $FULL_URL; CN_TEXT
		fi
        fi
    done
};

if [ $BOL_COLOR		-eq $TRUE					]; then INIT_COLOR_SHORTHAND;							fi
# Loop through PAGES from START_PAGE to END_PAGE and call DL function each loop
function DL_LOOP()
{
    declare -i -g CURRENT_PAGE=$START_PAGE
    declare -i RETVAL=$FAILURE
    while [ $CURRENT_PAGE -ne $((END_PAGE+1)) ]; do
        CLB_TEXT; GET_LIST_ARRAY; CN_TEXT
	if [ $LIST_ONLY -eq $FALSE ]; then CC_TEXT; DL; CN_TEXT;											fi
	RETVAL=$?
	((CURRENT_PAGE++))
    done
    return $RETVAL
};

if [ $BOL_HELP -eq $TRUE ]; then
    DO_HELP
    EXIT_VAL=$SUCCESS
else
    # As long as there is something stored in SEARCH_ITEM start executing DL_LOOP
    if [ ${#SEARCH_ITEM} -ne 0 ]; then
        DL_LOOP
        EXIT_VAL=$?
    else
        SHOW_HEADER
        echo -e "\nNo search item defined. Please Run: $RUN_CMD --help for more information"
        EXIT_VAL=$FAILURE
    fi
fi

exit $EXIT_VAL

