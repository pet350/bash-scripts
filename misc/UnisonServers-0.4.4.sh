#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018; 04/10/2019, 6/6/2020

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

# Current Version
export VERSION=0.4.4

# Define Global Arrays
declare -ag OPTIONS_ARRAY=("-auto" "-batch" "-times" "-numericids" "-rsync" "-killserver");
declare -ag HELP_ARRAY=("--help" "Display this Help Message\n" "--quite" "Don't display too much information\n" \
	"--threshold=NN" "Set Maximum Running Threshold\n" "--wait=NN" "Wait NN second inbetween processes\n" \
	"--no-wait" "Don't wait inbetween processes\n" "--remote=(host)" "Set Remote hostname\n" \
	"--version" "Display Version Information\n" "--test" "Run in Test Mode. Don't actuall call Unison Binary\n" \
	"--add-folder=XXX" "Add folder XXX to predefined folders\n" "--custom-folder=XXX" \
	"Do not use predefined folder, Use XXX instead\n" "--with-home" "Sychronize home folders\n" "--no-home" \
	"Do not Sychronize Home Folders\n" "--with-usr-local" "Sychronize /usr/local folders\n" "--no-usr-local" \
        "Do not Sychronize /usr/local Folders\n" "--prefer-local" "Favor local copy over remote\n" \
	"--perfer-remote" "Favor remote copy over local\n" "--no-preferance" "Do not show preferance on either side\n"
	"--allow-delete" "Allow file Deletion (careful!)\n" "--backup" "Perform tar backup of scripts first\n" \
	"XXX" "Pass any other option onto Unison Binary");

declare -ag FOLDER1_ARRAY=();
declare -ag FOLDER2_ARRAY=();

# Find Nuber of Unison Instances are Running
declare -ig CURRENT_PROC=$(ps -ax | grep unison | egrep -v 'UnisonServers.sh|/var/log/unison/|grep' | wc -l)

# Define Global Integer Variables
declare -ig OPTIONS_ARRAY_COUNT=${#OPTIONS_ARRAY[@]}
declare -ig RETVAL=$SUCCESS
declare -ig EXIT_VAL=$SUCCESS
declare -ig VAR_WAIT=1
declare -ig PROC_THRESHOLD=1
declare -ig EXCEDES_THRESHOLD=256
declare -ig INDEX=${#FOLDER1_ARRAY[@]}

# Define Global Booleans
declare -ig BOL_HOME=$TRUE
declare -ig BOL_USR_LOCAL=$TRUE
declare -ig BOL_CUSTOM_FOLDER=$FALSE
declare -ig BOL_QUIET=$FALSE
declare -ig BOL_PREFER_REMOTE=$FALSE
declare -ig BOL_ALLOW_DELETE=$FALSE
declare -ig BOL_NO_PREFERANCE=$FALSE
declare -ig BOL_BACKUP=$FALSE

# Define String Variables
export LOG_PREFIX="/var/log/unison"
export LOCAL_HOST="$(hostname -f)"
export COMMAND="$UNISON_BIN"

# Set Remote Hostname based on Local Hostname
if [ $LOCAL_HOST == "lxc.gigaware.lan" ]; then
  export REMOTE_HOST="ipa.gigaware.lan"
else
  export REMOTE_HOST="lxc.gigaware.lan"
fi

# Define the Log Filename
export DOW=$(date +%w)
export FULL_DATE=$(date +%F)
export FULL_TIME=$(date +%r)
export LOGFILE="/var/log/unison/$DOW-Server.log"
export BACKUP_PATH="/opt/bak/scripts/$(hostname -s)"
export BACKUP_FILE="$BACKUP_PATH/scripts-$FULL_DATE.tar.gz"
export BACKUP_OPTIONS="-zcvf"

# Print Date and Time to Logfile
function PRINT_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL | tee -a $LOGFILE
  return $SUCCESS
};

function TEST_REMOTE_HOST()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  ping -c 1 $REMOTE_HOST >/dev/null 2>/dev/null
  FUNCTION_RETURN=$?
  if [ $FUNCTION_RETURN -ne $SUCCESS ]; then
    PRINT_DATE_TIME
    echo -e $COLOR_LT_GREEN"Remote Host: "$COLOR_LT_BLUE"$REMOTE_HOST "$COLOR_RED"NOT "$COLOR_YELLOW"Responding!\n"$COLOR_NORMAL | tee -a $LOGFILE
    exit $FUNCTION_RETURN
  fi
  return $FUNCTION_RETURN
};

function BACKUP_SCRIPTS()
{
  export TEMP_COMMAND="$COMMAND"
  if [ ! -f $BACKUP_PATH ]; then mkdir -p $BACKUP_PATH >/dev/null 2>/dev/null; fi
  PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Backup scripts folder to: "$COLOR_YELLOW"$BACKUP_FILE"$COLOR_NORMAL | tee -a $LOGFILE
  printf "%b" $COLOR_ORRANGE; $TAR_BIN $BACKUP_OPTIONS $BACKUP_FILE -C "/usr/local" "scripts" | tee -a $LOGFILE
  export RETVAL=$?
  printf "%b" $COLOR_NORMAL
  export COMMAND="Final Outcome: "
  PRINT_DATE_TIME; LOG_RESULTS
  export COMMAND="$TEMP_COMMAND"
  unset TEMP_COMMAND
  return $RETVAL
};

# Make Sure That Only Root User is Running this Script
REQUIRE_ROOT_USER

# Parse Command Line Options -- If Any
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
'-t' | '--test')
	export UNISON_BIN="$TRUE_BIN"
	export TAR_BIN="$TRUE_BIN"
	export COMMAND="$TRUE_BIN"
	export BOL_TEST=$TRUE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
        export BOL_LOG_RESULTS=$TRUE
	export BOL_QUIET=$FALSE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
	export BOL_QUIET=$FALSE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	export BOL_QUIET=$TRUE
	;;
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy: Peter Talbott"
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
'--no-home')
	export BOL_HOME=$FALSE
	;;
'--with-home')
	export BOL_HOME=$TRUE
	;;
'--no-usr-local')
	export BOL_USR_LOCAL=$FALSE
	;;
'--with-usr-local')
	export BOL_USR_LOCAL=$TRUE
	;;
'--prefer-local')
	export BOL_PREFER_REMOTE=$FALSE
	;;
'--prefer-remote')
        export BOL_PREFER_REMOTE=$TRUE
        ;;
--threshold=*)
        X="${i#*=}"
        export PROC_THRESHOLD=$((X))
        ;;
--remote=*)
        export REMOTE_HOST="${i#*=}"
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
--custom-folder=*)
        CUSTOM_PREFIX="${i#*=}"
	CUSTOM_FOLDER="${CUSTOM_PREFIX#*/}"
	export BOL_CUSTOM_FOLDER=$TRUE
	INDEX=${#FOLDER1_ARRAY[@]}
	FOLDER1_ARRAY[$((INDEX))]="$CUSTOM_PREFIX"
	FOLDER2_ARRAY[$((INDEX))]="/nfs/$REMOTE_HOST/$CUSTOM_FOLDER"
	;;
--add-folder=*)
        CUSTOM_PREFIX="${i#*=}"
        CUSTOM_FOLDER="${CUSTOM_PREFIX#*/}"
        INDEX=${#FOLDER1_ARRAY[@]}
        FOLDER1_ARRAY[$((INDEX))]="$CUSTOM_PREFIX"
        FOLDER2_ARRAY[$((INDEX))]="/nfs/$REMOTE_HOST/$CUSTOM_FOLDER"
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'--backup')
	export BOL_BACKUP=$TRUE
	;;
'--allow-delete')
	export BOL_ALLOW_DELETE=$TRUE
	;;
'--no-preferance')
	export BOL_NO_PREFERANCE=$TRUE
	;;
*)
	# Any unknow options pass them onto unison
	OPTIONS_ARRAY_COUNT=${#OPTIONS_ARRAY[@]}
        OPTIONS_ARRAY[$((OPTIONS_ARRAY_COUNT))]="$i"
	;;
esac
done

if [ $BOL_CUSTOM_FOLDER -eq $TRUE ]; then
  export BOL_USR_LOCAL=$FALSE
  export BOL_HOME=$FALSE
fi

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

if [ $CURRENT_PROC -gt $PROC_THRESHOLD ]; then
  if [ $BOL_QUIET -eq $TRUE ]; then
    PRINT_DATE_TIME; echo -e $COLOR_LT_BLUE"Current Process Count: "$COLOR_YELLOW"$CURRENT_PROC "$COLOR_LT_BLUE"Excedes Threshold: "$COLOR_YELLOW"$PROC_THRESHOLD!"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
  else
    PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: "$COLOR_YELLOW"$VERSION"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
    PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Start of Log: "$COLOR_YELLOW"[$FULL_DATE @ $FULL_TIME]"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
    PRINT_DATE_TIME; echo -e $COLOR_RED"Error: "$COLOR_LT_BLUE"Current Process Count: "$COLOR_YELLOW"$CURRENT_PROC "$COLOR_LT_BLUE"Excedes Threshold: "$COLOR_YELLOW"$PROC_THRESHOLD!!\n"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
  fi
  exit $EXCEDES_THRESHOLD
fi

if [ ! -d $LOG_PREFIX ]; then mkdir -p $LOG_PREFIX; fi

# Display Informational Header
if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; echo -e "$RUN_CMD"$COLOR_LT_BLUE"\tVersion: "$COLOR_YELLOW"$VERSION"$COLOR_NORMAL | tee -a $LOGFILE; fi
PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Start of Log: "$COLOR_YELLOW"[$FULL_DATE @ $FULL_TIME]"$COLOR_NORMAL | tee -a $LOGFILE
if [ $BOL_BACKUP -eq $TRUE ]; then BACKUP_SCRIPTS; fi
if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Local Host Name: "$COLOR_YELLOW"$LOCAL_HOST"$COLOR_NORMAL | tee -a $LOGFILE; fi
if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Remote Host Name: "$COLOR_YELLOW"$REMOTE_HOST"$COLOR_NORMAL | tee -a $LOGFILE; fi
if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Number of Running Unison Processess: "$COLOR_YELLOW"$CURRENT_PROC"$COLOR_NORMAL | tee -a $LOGFILE; fi
if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Threshold of Running Unison Processess: "$COLOR_YELLOW"$PROC_THRESHOLD"$COLOR_NORMAL | tee -a $LOGFILE; fi

if [ $BOL_USR_LOCAL -eq $TRUE ]; then
  INDEX=${#FOLDER1_ARRAY[@]}
  # Synchronize These Folders
  FOLDER1_ARRAY[$((INDEX))]="/usr/local/"
  FOLDER2_ARRAY[$((INDEX))]="/nfs/$REMOTE_HOST/usr/local/"
fi

if [ $BOL_HOME -eq $TRUE ]; then
  INDEX=${#FOLDER1_ARRAY[@]}
  for DATA in $(ls -1 /home); do
    FOLDER1_ARRAY[$((INDEX))]="/home/$DATA/"
    FOLDER2_ARRAY[$((INDEX))]="/nfs/$REMOTE_HOST/home/$DATA/"
    ((INDEX++))
  done
fi

export FOLDER1_LIST=${FOLDER1_ARRAY[@]}
export FOLDER2_LIST=${FOLDER2_ARRAY[@]}

# Display Folders to Sync
if [ $BOL_QUIET -ne $TRUE ]; then
  PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Local Folder List: "$COLOR_YELLOW"$FOLDER1_LIST"$COLOR_NORMAL | tee -a $LOGFILE
  PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Remote Folder List: "$COLOR_YELLOW"$FOLDER2_LIST"$COLOR_NORMAL | tee -a $LOGFILE
  PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Unison Options: "$COLOR_YELLOW"${OPTIONS_ARRAY[@]}"$COLOR_NORMAL | tee -a $LOGFILE
  PRINT_DATE_TIME; echo -e $COLOR_LT_GREEN"Log File: "$COLOR_YELLOW"$LOGFILE"$COLOR_NORMAL | tee -a $LOGFILE
fi

# Define Local Host Name
export UNISONLOCALHOSTNAME="$LOCAL_HOST"
printf "\n" | tee -a $LOGFILE

# Make sure remote host is up and running!
TEST_REMOTE_HOST

# Run Unison With The PreDefined Variables Above
declare -i ARRAY_INDEX=-1
for DATA in ${FOLDER1_ARRAY[@]}; do
  ((ARRAY_INDEX++))
  FOLDER1="$DATA"
  FOLDER2="${FOLDER2_ARRAY[$((ARRAY_INDEX))]}"
  if [ $BOL_PREFER_REMOTE -eq $TRUE ]; then
    export FOLDER_PREFERENCE="$FOLDER2"
  else
    export FOLDER_PREFERENCE="$FOLDER1"
  fi
  if [ $BOL_ALLOW_DELETE -eq $FALSE ]; then
    OPTIONS_ARRAY_COUNT=${#OPTIONS_ARRAY[@]}
    OPTIONS_ARRAY[$((OPTIONS_ARRAY_COUNT))]="-nodeletion $FOLDER_PREFERENCE"
  fi
  if [ $BOL_NO_PREFERANCE -eq $FALSE ]; then
    OPTIONS_ARRAY_COUNT=${#OPTIONS_ARRAY[@]}
    OPTIONS_ARRAY[$((OPTIONS_ARRAY_COUNT))]="-prefer $FOLDER_PREFERENCE"
  fi
  PRINT_DATE_TIME
  echo -e $COLOR_LT_BLUE"Executing: "$COLOR_YELLOW"$COMMAND $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} \
	-ignore 'Name .cache*' -ignore 'Name plasmaConfSaver*' -ignore 'Name icons*' -logfile $LOGFILE.INFO | tee -a $LOGFILE"
  PRINT_DATE_TIME
  printf "\n%b" $COLOR_CYAN; $COMMAND $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} \
	-ignore 'Name .cache*' -ignore 'Name plasmaConfSaver*' -ignore 'Name icons*' -logfile $LOGFILE.INFO | tee -a $LOGFILE
  export RETVAL=$?
  EXIT_VAL=$((EXIT_VAL+RETVAL))
  printf "%b" $COLOR_NORMAL
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  PRINT_DATE_TIME; LOG_RESULTS | tee -a $LOGFILE
  echo -e "\n"
done
export RETVAL=$((EXIT_VAL))
export COMMAND="Final Outcome: "
PRINT_DATE_TIME; LOG_RESULTS

exit $RETVAL
# The End
