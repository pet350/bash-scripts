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

# Define some static variables
export RUN_CMD="$(basename $0)"
export VERSION="0.8"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-02-23"
export WORKING_PREFIX="$(pwd)"

# Define some static integers
declare -i SUCCESSFUL_DOWNLOAD=0

## Added in Version 0.8
## if Verbose flag is set, display the exclude list prior to download
## Added logfile support

## Added in Version 0.7
## --all | -a 		All normally used options get Enabled
## --booleans		Print out all Boolean values prior to main loop

## Added in version 0.6
## --summary	Display a summary at the end (Default)
## --no-summary Don't Display a summary at the end

## Added in version 0.5
## --ignore=XXX Option
## --no-men (or -m) Option
## Filenames that start with an integer goes to the folder 0

# Define a few more binary variables
for DATA in curl yt_dlp egrep chown sleep find; do
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

# Define Boolean Arrays
declare -a BOOLEAN_VALUES=();
declare -a BOOLEAN_NAMES=( "Debug\n" "Summary\n" "Verbose\n" "Help\n" "Color\n" "Force Color\n" "Test\n" "Length\n" "Duration\n" "List Only\n" );

# Define an array of everthing associated with a man for an exclude list
declare -a GUYS=("cumshot" "cum-shot" "boy" "his" "-male" "-man" "-men" "husband"	\
		 "dick" "guy" "brother" "son" "stepson" "cock" "penis-" "uncle" "him"	\
		 "jiz" "he-" "trans" "wang" "shlong" "blowjob" "handjob" "footjob"	\
		 "balls" "johnson" "erection" "testicle" "trans" "trannies" "shemale"	);

# Staticly defined Variables
export LENGTH_OPT="--get-duration"

# This binary is used to get the TARGET_FILENAME and DURATION (runtime) Only!
# Reason being, it will not get changed if program is in TEST mode
export YTDLP_BIN="$YT_DLP_BIN"

# Self Explanitory Function
function SHOW_HEADER()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function PRINT_BOOLEAN()
{
    local -i BOOLEAN=$1

    if   [ $BOOLEAN -eq $TRUE  ]; then 	CG_TEXT; printf "True";    CN_TEXT
    elif [ $BOOLEAN -eq $FALSE ]; then  CR_TEXT; printf "False";   CN_TEXT
    else 				CY_TEXT; printf "Unknown"; CN_TEXT
    fi
    return $BOOLEAN
};

function ASSEMBLE_BOOLEAN_ARRAY()
{
    declare -i INDEX=-1
    for ELEMENT in "$BOL_DEBUG" "$BOL_SUMMARY" "$BOL_VERBOSE" "$BOL_HELP" "$BOL_COLOR" "$BOL_FORCE_COLOR" "$BOL_TEST" "$BOL_LENGTH" "$BOL_DURATION" "$LIST_ONLY"; do
        ((INDEX++))
        BOOLEAN_VALUES[$((INDEX))]=$ELEMENT
    done
    return $INDEX
};

function PRINT_BOOLEANS()
{
    declare -i INDEX=-1
    declare -i RETVAL=$FAILURE

    if [ ${#BOOLEAN_VALUES[@]} -ne 0 ] && [ ${#BOOLEAN_NAMES[@]} -ne 0 ]; then
        while IFS= read BOOLEAN_NAME; do
            ((INDEX++))
	    if [ ${#BOOLEAN_NAME} -gt 0 ]; then
                CLB_TEXT; printf "%-15s: " "$BOOLEAN_NAME"; PRINT_BOOLEAN ${BOOLEAN_VALUES[$((INDEX))]}; CN_TEXT; printf "\n"
	    fi
        done < <(echo -e "${BOOLEAN_NAMES[@]}")
        RETVAL=$SUCCESS
    else
        CLR_TEXT; printf "No Booleans Defined\n"; CN_TEXT
        RETVAL=$FAILURE
    fi
    return $RETVAL
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

function SHOW_EXCLUDE_LIST()
{
   declare -i RETVAL=$SUCCESS
   CLB_TEXT; printf "Current Exclude List: "
    if [ ${#EXCLUDE_LIST} -ne 0 ]; then
	CC_TEXT; printf "%s" "$EXCLUDE_LIST"
    else
       CR_TEXT; printf "No exclude list defined"
       RETVAL=$FAILURE
    fi
    CN_TEXT; printf "\n"
    return $RETVAL
};

# Check Command Line for any arguments that may be present
for OPTIONS in $@; do
    case ${OPTIONS,,} in
	--version)			SHOW_HEADER;				exit $SUCCESS;;
	--all 		| -a)		for ALL_TRUE in BOL_DEBUG SHOW_BOOLEANS BOL_SUMMARY BOL_VERBOSE BOL_COLOR BOL_FORCE_COLOR BOL_DURATION; do export $ALL_TRUE=$TRUE; done; NO_MEN; 	export VERBOSE="-v";;
	--booleans	| -b)		declare -i SHOW_BOOLEANS=$TRUE;;
        --debug		| -d)		declare -i BOL_DEBUG=$TRUE; 		declare -i SHOW_BOOLEANS=$TRUE;;
	--summary	| -s)		declare -i BOL_SUMMARY=$TRUE;;
	--no-summary	| -ns)		declare -i BOL_SUMMARY=$FALSE;;
	--verbose	| -v)		declare -i BOL_VERBOSE=$TRUE;		export VERBOSE="-v";;
        --help		| -h)		declare -i BOL_HELP=$TRUE;;
	--bw)				declare -i BOL_COLOR=$FALSE;;
	--test		| -t)		declare -i BOL_TEST=$TRUE;;
	--list-only	| -l)		declare -i LIST_ONLY=$TRUE;;
	--no-length)			declare -i BOL_LENGTH=$FALSE;;
        --no-duration)                  declare -i BOL_LENGTH=$FALSE;		declare -i BOL_DURATION=$FALSE;;
        --length)                       declare -i BOL_LENGTH=$TRUE;;
        --duration)                     declare -i BOL_DURATION=$TRUE;;
        --bw)                           declare -i BOL_COLOR=$FALSE;;
        --color)	                declare -i BOL_COLOR=$TRUE;;
        --force-color) 		        declare -i BOL_FORCE_COLOR=$TRUE;       declare -i BOL_COLOR=$TRUE;;
	--logfile=*	| --log=*)	declare -x LOGFILE="${OPTIONS#*=}";;
        --start-page=*	| --start=*)    declare -i START_PAGE="${OPTIONS#*=}";;
        --end-page=*    | --end=*)      declare -i END_PAGE="${OPTIONS#*=}";;
	--base-url=*)			declare -x BASE_URL="${OPTIONS#*=}";;
	--search=*)			export SEARCH_ITEM="${OPTIONS#*=}";;
	--user=*)			export FILE_USER="${OPTIONS#*=}";;
	--group=*)			export FILE_GROUP=="${OPTIONS#*=}";;
	--prefix=*)			export STREAM_PREFIX="${OPTIONS#*=}";;
	--ignore=*)			if [ ${#EXCLUDE_LIST} -eq 0 ]; then export EXCLUDE_LIST="${OPTIONS#*=}";	else export EXCLUDE_LIST="$EXCLUDE_LIST|${OPTIONS#*=}";	fi;;
	--no-men |	-m)		NO_MEN;;
    esac
done

# Define HELP_ARRAY what is used by DO_HELP funtion  when --help is present on the command line
declare -a HELP_ARRAY=(	"---------------" "--------* Required *--------------------\n" "--search=XXX" "URL Search String (SEARCH_ITEM Variable)\n" 			\
			"---------------" "--------* Optional *--------------------\n" "--help" "(or -h) : Display this help message.\n" 				\
			"--verbose" "(or -v) : detailed output.\n" "--test" "(or -t) : Test mode does not download.\n" "--debug" "(or -d) : debug output.\n" 		\
			"---------------" "----------------------------------------\n" "--version" "Display version information\n" "---------------" 			\
			"---------+ Pages  +-----------------------\n" "--start-page=NN"										\
			"Page number to start at. (Default 1)\n" "--end-page=NN" "Page number to stop at. (Default 10)\n" "---------------" 				\
			"----------------------------------------\n" "--user=XXX" "Username to set the downloaded file to.\n" "--group=XXX" 				\
			"Group to set the downloaded file to.\n" "---------------" "----------------------------------------\n" "--prefix=XXX" 				\
			"Download Prefix.\n" "--base-url=XXX" "Base URL to download from.\n" "---------------" "----------------------------------------\n" 		\
			"--list-only" "(or -l) : List all found names.\n" "--no-men" "(or -m) : attempt to filter out any men.\n" "---------------" 			\
			"----------------------------------------\n"  "--ignore=XXX" "Do not download filenames containing XXX.\n" "--no-length"			\
			"Don't get video length during lookup (X).\n" "--length" "Get video length during lookup.\n" "--no-duration" "Don't get video length at all.\n"	\
			"--duration" "Get video lenght prior to D/L (X).\n"  "--all" "(or -a) Enable All used as defaults.\n" "--booleans" 				\
			"(or -b) Show all booleans.\n" "---------------" "----------------------------------------\n"							\
			"(X)" "Signifies Default Behavior."														);

# Declare Variables if not already defined
if [ ${#LOGFILE}	-eq 0 ]; then	declare -x LOGFILE="/tmp/ytdl.log";					fi
if [ ${#SHOW_BOOLEANS}	-eq 0 ]; then	declare -i SHOW_BOOLEANS=$FALSE;					fi
if [ ${#BOL_SUMMARY}	-eq 0 ]; then	declare -i BOL_SUMMARY=$TRUE;						fi
if [ ${#BOL_TEST}	-eq 0 ]; then	declare -i BOL_TEST=$FALSE;						fi
if [ ${#LIST_ONLY}      -eq 0 ]; then   declare -i LIST_ONLY=$FALSE;                                   		fi
if [ ${#BOL_LENGTH}     -eq 0 ]; then   declare -i BOL_LENGTH=$FALSE;                                   	fi
if [ ${#BOL_DURATION}   -eq 0 ]; then   declare -i BOL_DURATION=$TRUE;                                  	fi
if [ $BOL_TEST    -eq   $TRUE ]; then	declare -x YT_DLP_BIN=$TRUE_BIN;	export CHOWN_BIN=$TRUE_BIN;	fi
if [ ${#BASE_URL}	-eq 0 ]; then 	declare -x BASE_URL="https://www.youporn.com";				fi
if [ ${#SEARCH_STRING}	-eq 0 ]; then 	declare -x SEARCH_STRING="/search/?search-btn=&query=";			fi
if [ ${#WATCH_STRING}	-eq 0 ]; then 	declare -x WATCH_STRING="/watch";					fi
if [ ${#PAGE_STRING}	-eq 0 ]; then	export PAGE_STRING="&page=";						fi
if [ ${#DLOPTS}		-eq 0 ]; then	export DLOPTS="--embed-thumbnail --geo-bypass --force-ipv4		\
						--yes-playlist --retries 20 --restrict-filenames  		\
						--continue --no-overwrites --no-warnings           		\
						--console-title --merge-output-format mp4          		\
						--no-check-certificate";					fi
if [ ${#FILE_USER}	-eq 0 ]; then	export FILE_USER="www-data";						fi
if [ ${#FILE_GROUP}	-eq 0 ]; then	export FILE_GROUP="streaming";						fi
if [ ${#STREAM_PREFIX}	-eq 0 ]; then	export STREAM_PREFIX="/opt/porn";					fi

# Define Arrays if not defioned already
if [ ${#LIST_ARRAY[@]}	 -eq 0 ]; then 	declare -g -a	LIST_ARRAY=();					fi
if [ ${#LENGTH_ARRAY[@]} -eq 0 ]; then  declare -g -a	LENGTH_ARRAY=();                                fi
if [ ${#START_PAGE}	 -eq 0 ]; then	declare -i	START_PAGE=1;					fi
if [ ${#END_PAGE}	 -eq 0 ]; then	declare -i	END_PAGE=10;					fi

declare -i TOTAL_ERRORS=0

declare -ag DOWNLOADED_SUCCESSFUL_ARRAY=();
declare -ag DOWNLOAD_UNSUCCESSFUL_ARRAY=();
declare -ag DOWNLOAD_SKIPPED_ARRAY=();

# Chown ownership of TARGET_FILENAME if file exists
function CHANGE_OWNER()
{
    declare -i RETVAL=$FAILURE
    if [ -f $TARGET_FILENAME ]; then
        if [ $BOL_DEBUG -eq $TRUE ]; then CLR_TEXT; printf "[Debug] "; CLB_TEXT; printf "Executing: "; CY_TEXT; printf "%s %s " $CHOWN_BIN $VERBOSE; printf "%s:%s %s" $FILE_USER:$FILE_GROUP $TARGET_FILENAME; CN_TEXT; 						fi
	$CHOWN_BIN $VERBOSE $FILE_USER:$FILE_GROUP $TARGET_FILENAME
        RETVAL=$?; COMMAND="$CHOWN_BIN"
        LOG_RESULTS
	if  [ $RETVAL -ne $SUCCESS ]; then ((TOTAL_ERRORS++)); fi
        echo -e "\n"
    else
        if [ $BOL_VERBOSE -eq $TRUE ]; then CLR_TEXT; printf "Not changing ownership of "; CY_TEXT; printf "%s " "$TARGET_FILENAME"; CLR_TEXT; printf "file does not exist!\n"; CN_TEXT; 							fi
    fi
    return $RETVAL
};

function SHOW_DL()
{
    CLB_TEXT; printf "Filename: ";          CY_TEXT; printf "%s " "$TARGET_PREFIX"/"$TARGET_FILENAME"; CLB_TEXT; printf "Does NOT Exist, Proceding to Download\n"; CN_TEXT
    CLB_TEXT; printf "Download URL: ";      CY_TEXT; printf "%s\n" $FULL_URL; CN_TEXT
    CLB_TEXT; printf "Runtime: ";           CY_TEXT; printf "%s\n" $DURATION; CN_TEXT
    return $SUCCESS
};

function SHOW_TOTALS()
{
    if [ $SKIP_TOTAL -gt 0 ];          then CLB_TEXT; printf "Downloads Skipped Because File Already Exists: "; CY_TEXT; printf "%4s\n" $SKIP_TOTAL; CN_TEXT;                   fi
    if [ $TOTAL_ERRORS -gt 0 ];        then CLB_TEXT; printf "Total "; CLR_TEXT; printf "Errors ";     CLB_TEXT; printf "Encountered: "; CY_TEXT; printf "%4s\n" $TOTAL_ERRORS; CN_TEXT;                                   fi
    if [ $SUCCESSFUL_DOWNLOAD -gt 0 ]; then CLB_TEXT; printf "Total "; CLG_TEXT; printf "Successful "; CLB_TEXT; printf " Downloaded: "; CY_TEXT; printf "%4s\n" $SUCCESSFUL_DOWNLOAD; CN_TEXT;                            fi
    return $SUCCESS
};

function MOVE_TARGET()
{
    declare -i RETVAL=$FAILURE
    if [ -f $TARGET_FILENAME ]; then
        if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Executing: mv $VERBOSE $TARGET_FILENAME $TARGET_PREFIX\n"; 								fi
	mv $VERBOSE $TARGET_FILENAME $TARGET_PREFIX
        RETVAL=$?; COMMAND="mv"
        LOG_RESULTS
        if  [ $RETVAL -ne $SUCCESS ]; then ((TOTAL_ERRORS++)); fi
        echo -e "\n"
    else
        if [ $BOL_VERBOSE -eq $TRUE ]; then CLR_TEXT; printf "Not moving "; CY_TEXT; printf "%s " "$TARGET_FILENAME"; CLR_TEXT; printf "to "; CY_TEXT; printf "%s " "$TARGET_PREFIX"; CLR_TEXT; printf ", file does not exist!\n"; CN_TEXT; 							fi
    fi
    return $RETVAL
};

# Get total number of download URLs
function GET_LIST_TOTAL()
{
    declare -i INDEX_TOTAL=-1
    declare -i RETVAL=$FAILURE

    if [ ${#EXCLUDE_LIST} -ne 0 ]; then export EXCLUDE_OPTION="-v"; else unset EXCLUDE_OPTION; 											fi
    while IFS= read LINE; do
        TEMP="${LINE#*href="\""}"
        TEMP="${TEMP%/\"*}"
        case "${TEMP:1:8}" in
                'porntags' | 'watch-hi')
                        $TRUE_BIN
                        ;;
                *)
			((INDEX_TOTAL++))
			RETVAL=$SUCCESS
			;;
	esac
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM$PAGE_STRING$CURRENT_PAGE 2>/dev/null | $GREP_BIN $WATCH_STRING | $EGREP_BIN $EXCLUDE_OPTION "$EXCLUDE_LIST")
    echo $INDEX_TOTAL
    if  [ $RETVAL -ne $SUCCESS ]; then ((TOTAL_ERRORS++)); 															fi
    return $RETVAL
};

function SHOW_SUMMARY()
{
    if [ ${#DOWNLOAD_UNSUCCESSFUL_ARRAY[@]}	-gt 0 ]; then CLB_TEXT; printf "Downloads Unsuccessful: ";      CLR_TEXT; printf "%s\n" "${DOWNLOAD_UNSUCCESSFUL_ARRAY[@]}";	CN_TEXT;	fi
    if [ ${#DOWNLOAD_SKIPPED_ARRAY[@]}		-gt 0 ]; then CLB_TEXT; printf "Downloads Skipped: ";		CY_TEXT;  printf "%s\n" "${DOWNLOAD_SKIPPED_ARRAY[@]}";		CN_TEXT;	fi
    if [ ${#DOWNLOADED_SUCCESSFUL_ARRAY[@]}	-gt 0 ]; then CLB_TEXT; printf "Downloads Successful: ";	CLG_TEXT; printf "%s\n" "${DOWNLOADED_SUCCESSFUL_ARRAY[@]}";	CN_TEXT;	fi
    return $SUCCESS
};

# Function will populate LIST_ARRAY
function GET_LIST_ARRAY()
{
    declare -i LIST_INDEX=-1
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)
    declare -i RETVAL=$FAILURE

    if [ ${#EXCLUDE_LIST} -ne 0 ]; then export EXCLUDE_OPTION="-v"; else unset EXCLUDE_OPTION; 											fi
    while IFS= read LINE; do
        TEMP="${LINE#*href="\""}"
        TEMP="${TEMP%/\"*}"
        case "${TEMP:1:8}" in
		'porntags' | 'watch-hi')
			$TRUE_BIN
			;;
		*)
			((LIST_INDEX++))
			if [ $BOL_LENGTH -eq $TRUE ]; then TEMP_LENGTH=$($YTDLP_BIN $LENGTH_OPT $BASE_URL$TEMP); else TEMP_LENGTH="Unknown";					fi
        		LIST_ARRAY[$((LIST_INDEX))]="$TEMP"
			LENGTH_ARRAY[$((LIST_INDEX))]="$TEMP_LENGTH"
			if [ $BOL_DEBUG -eq $TRUE  ] && [ $LIST_ONLY -eq $FALSE ]; then CLG_TEXT; printf "[Debug] ";			  					fi
			if [ $BOL_DEBUG -eq $TRUE  ] && [ $LIST_ONLY -eq $TRUE  ]; then CLG_TEXT; printf "[Debug] [List Only] ";   	  					fi
			if [ $BOL_DEBUG -eq $FALSE ] && [ $LIST_ONLY -eq $TRUE  ]; then CLG_TEXT; printf "[List Only] ";	 	  					fi
			if [ $BOL_DEBUG -eq $TRUE  ] || [ $LIST_ONLY -eq $TRUE  ]; then CLB_TEXT; printf "Search Result: Page number: "; CY_TEXT; printf "%3s, " $CURRENT_PAGE; CLB_TEXT; printf "File Number:  "; CY_TEXT; printf "%3s / %3s, " $LIST_INDEX $LIST_TOTAL; CLB_TEXT; printf "Duration: "; CY_TEXT; printf "%8s, " $TEMP_LENGTH; CLB_TEXT; printf "Filename: "; CLR_TEXT; printf "%s\n" $TEMP; CN_TEXT;	fi
			;;
	esac
    done < <($CURL_BIN $BASE_URL$SEARCH_STRING$SEARCH_ITEM$PAGE_STRING$CURRENT_PAGE 2>/dev/null | $GREP_BIN $WATCH_STRING | $EGREP_BIN $EXCLUDE_OPTION "$EXCLUDE_LIST")
    if [ $LIST_INDEX -gt 1 ]; then RETVAL=$SUCCESS;
    if  [ $RETVAL -ne $SUCCESS ]; then ((TOTAL_ERRORS++)); fi		                                                							fi
    return $RETVAL
};

# Download all the URLs stored in LIST_ARRAY
function DL()
{
    declare -i INDEX=-1
    declare -i SKIP_COUNT=0
    declare -i RETVAL=$FAILURE
    declare -i LIST_TOTAL=$(GET_LIST_TOTAL)

    for SUFFIX in ${LIST_ARRAY[@]}; do
        ((INDEX++))
        export FULL_URL="$BASE_URL$SUFFIX"
        if [ $INDEX -gt 0 ]; then
		export DURATION="${LENGTH_ARRAY[$((INDEX))]}"
		export TARGET_FILENAME=$($YTDLP_BIN $DLOPTS --get-filename $FULL_URL)
		export FIRST_LETTER=${TARGET_FILENAME:0:1}
		case $FIRST_LETTER in
    			'' | *[!0-9]*) 	export FIRST_LETTER=${FIRST_LETTER^^};;
    			*) 		export FIRST_LETTER="0";;
		esac
		export TARGET_PREFIX="$STREAM_PREFIX/$FIRST_LETTER"
		if [ $BOL_VERBOSE -eq $TRUE ]; then
			CC_TEXT;  date; $CN_TEXT
		        CLB_TEXT; printf "Processing: Page "; CY_TEXT; printf "%-3s URL %-3s of %-3s: %s\n" $CURRENT_PAGE $INDEX $LIST_TOTAL "$FULL_URL"
			CLB_TEXT; printf "Target file: ";     CY_TEXT; printf "%s/%s\n" $TARGET_PREFIX $TARGET_FILENAME; CN_TEXT
		fi
		if [ ! -f "$TARGET_PREFIX"/"$TARGET_FILENAME" ]; then
			case $DURATION in
				'Unknown')	if [ $BOL_DURATION -eq $TRUE ]; then export DURATION=$($YTDLP_BIN $LENGTH_OPT $FULL_URL); fi;;
			esac
			if [ $BOL_VERBOSE -eq $TRUE ] || [ $BOL_DEBUG   -eq $TRUE ]; then
				SHOW_DL
				SHOW_TOTALS
			fi
			if [ $BOL_DEBUG   -eq $TRUE ]; then CLR_TEXT; printf "[Debug] "; CLB_TEXT; printf "Executing: "; CY_TEXT; printf "%s %s %s\n" $YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL; CN_TEXT;             fi
			CC_TEXT; $YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL
			RETVAL=$?; COMMAND="$YT_DLP_BIN $DLOPTS $VERBOSE $FULL_URL"; CN_TEXT
			LOG_RESULTS
			if [ $RETVAL -ne $SUCCESS ]; then
				DOWNLOAD_UNSUCCESSFUL_ARRAY[$((TOTAL_ERRORS))]="$TARGET_FILENAME"
				((TOTAL_ERRORS++))
			fi
			if [ $RETVAL -eq $SUCCESS ]; then
				DOWNLOADED_SUCCESSFUL_ARRAY[$((SUCCESSFUL_DOWNLOAD))]="$TARGET_FILENAME"
				((SUCCESSFUL_DOWNLOAD++))
			fi
			echo -e "\n"
			CHANGE_OWNER
			MOVE_TARGET
		else
			DOWNLOAD_SKIPPED_ARRAY[$((SKIP_COUNT))]="$TARGET_FILENAME"
			((SKIP_COUNT++))
			CLB_TEXT; printf "Target Exists! Skipping Download from: "; CC_TEXT; printf "%s!\n\n" $FULL_URL; CN_TEXT
		fi
        fi
    done
    return $SKIP_COUNT
};

if [ $BOL_COLOR		-eq $TRUE					]; then INIT_COLOR_SHORTHAND;										fi
# Loop through PAGES from START_PAGE to END_PAGE and call DL function each loop
function DL_LOOP()
{
    declare -i -g CURRENT_PAGE=$START_PAGE
    declare -i RETVAL=$FAILURE
    declare -i SKIP_TOTAL=0

    while [ $CURRENT_PAGE -ne $((END_PAGE+1)) ]; do
        CLB_TEXT; GET_LIST_ARRAY; CN_TEXT
	if [ $LIST_ONLY -eq $FALSE ]; then CC_TEXT; DL; SKIP_TOTAL=$((SKIP_TOTAL+$?)); CN_TEXT;											fi
	RETVAL=$?
	((CURRENT_PAGE++))
    done
    SHOW_TOTALS
    return $RETVAL
};

ASSEMBLE_BOOLEAN_ARRAY

if [ $BOL_HELP -eq $TRUE ]; then
    DO_HELP
    EXIT_VAL=$SUCCESS
else
    if [ $SHOW_BOOLEANS -eq $TRUE ]; then PRINT_BOOLEANS		| tee -a $LOGFILE;	fi
    # As long as there is something stored in SEARCH_ITEM start executing DL_LOOP
    if [ ${#SEARCH_ITEM} -ne 0 ]; then
	if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_EXCLUDE_LIST		| tee -a $LOGFILE; 	fi
        DL_LOOP								| tee -a $LOGFILE
        EXIT_VAL=$?
	if [ $BOL_SUMMARY -eq $TRUE ]; then SHOW_SUMMARY		| tee -a $LOGFILE; 	fi
    else
        SHOW_HEADER
        echo -e "\nNo search item defined. Please Run: $RUN_CMD --help for more information"
        EXIT_VAL=$FAILURE
    fi
fi

exit $EXIT_VAL

