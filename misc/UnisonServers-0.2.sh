#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018; 04/10/2019, 6/6/2020

# Current Version
export VERSION=0.2

# Source function library.
source /lib/lsb/init-functions

if [ -f /usr/local/scripts/include/*.sh ]; then
  for INCLUDE_FILE in $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
fi

# Find Nuber of Unison Instances are Running
declare -ig CURRENT_PROC=$(ps -ax | grep -v grep | grep unison | wc -l)
declare -ig VAR_WAIT=1

# Define Options
declare -ag OPTIONS_ARRAY=("-auto" "-batch" "-times" "-numericids" "-rsync" "-killserver");
declare -ig BOL_HOME=$TRUE

# Define String Variables
export LOG_PREFIX="/var/log/unison"
export LOCAL_HOST="$(hostname -f)"
export COMMAND="$UNISON_BIN"

# Set Remote Hostname based on Local Hostname
if [ $LOCAL_HOST == "lxc.gigaware.lan" ]; then
  export REMOTE_HOST="ipa.gigaware.lan"
  declare -ig PROC_THRESHOLD=2
else
  export REMOTE_HOST="lxc.gigaware.lan"
  declare -ig PROC_THRESHOLD=1
fi

# Define the Log Filename
export DOW=$(date +%w)
export FULL_DATE=$(date +%F)
export FULL_TIME=$(date +%r)
export LOGFILE="/var/log/unison/$DOW-Server.log"

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
	export COMMAND="$TRUE_BIN"
	export BOL_TEST=$TRUE
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
'--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
'--no-home')
	export BOL_HOME=$FALSE
	;;
'--with-home')
	export BOL_HOME=$TRUE
	;;
--threshold=*)
        X="${i#*=}"
        PROC_THRESHOLD=$((X))
        ;;
--remote=*)
        REMOTE_HOST="${i#*=}"
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
*)
	OPTIONS_ARRAY_COUNT=${#OPTIONS_ARRAY[@]}
        OPTIONS_ARRAY[$((OPTIONS_ARRAY_COUNT))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi
if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $CURRENT_PROC -gt $PROC_THRESHOLD ]; then
  echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: "$COLOR_YELLOW"$VERSION"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
  echo -e $COLOR_LT_BLUE"[$FULL_DATE @ $FULL_TIME]"$COLOR_YELLOW" Start of Log: "$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
  echo -e $COLOR_RED"Error: "$COLOR_LT_BLUE"Current Process Count: "$COLOR_YELLOW"$CURRENT_PROC "$COLOR_LT_BLUE"Excedes Threshold: "$COLOR_YELLOW"$PROC_THRESHOLD!!\n"$COLOR_NORMAL | tee -a "$LOGFILE.ERROR"
  exit $FAILURE
fi

if [ ! -d $LOG_PREFIX ]; then mkdir -p $LOG_PREFIX; fi

# Display Informational Header
echo -e $COLOR_LT_GREEN"$RUN_CMD"$COLOR_LT_BLUE"\tVersion: "$COLOR_YELLOW"$VERSION"$COLOR_NORMAL | tee -a $LOGFILE
echo -e $COLOR_LT_GREEN"Local Host Name: "$COLOR_YELLOW"$LOCAL_HOST"$COLOR_NORMAL | tee -a $LOGFILE
echo -e $COLOR_LT_GREEN"Remote Host Name: "$COLOR_YELLOW"$REMOTE_HOST"$COLOR_NORMAL | tee -a $LOGFILE
echo -e $COLOR_LT_GREEN"Number of Running Unison Processess: "$COLOR_YELLOW"$CURRENT_PROC"$COLOR_NORMAL | tee -a $LOGFILE
echo -e $COLOR_LT_GREEN"Threshold of Running Unison Processess: "$COLOR_YELLOW"$PROC_THRESHOLD"$COLOR_NORMAL | tee -a $LOGFILE
echo -e $COLOR_LT_GREEN"[$FULL_DATE @ $FULL_TIME] Start of Log: "$COLOR_NORMAL"\n" | tee -a $LOGFILE

# Synchronize These Folders
FOLDER1_ARRAY=("/usr/local/");
FOLDER2_ARRAY=("/nfs/$REMOTE_HOST/usr/local/");

if [ $BOL_HOME -eq $TRUE ]; then
  declare -i index=0
  for DATA in $(ls -1 /home); do
    ((index++))
    FOLDER1_ARRAY[$((index))]="/home/$DATA/"
    FOLDER2_ARRAY[$((index))]="/nfs/$REMOTE_HOST/home/$DATA/"
  done
fi

# Define Local Host Name
export UNISONLOCALHOSTNAME="$LOCAL_HOST"

# Run Unison With The PreDefined Variables Above
index=-1
for DATA in ${FOLDER1_ARRAY[@]}; do
  ((index++))
  FOLDER1="$DATA"
  FOLDER2="${FOLDER2_ARRAY[$((index))]}"
  echo -e $COLOR_LT_BLUE"Executing: "$COLOR_YELLOW"$COMMAND $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} -ignore 'Name .cache*' -prefer $FOLDER1 -nodeletion $FOLDER1 -logfile $LOGFILE.INFO | tee -a $LOGFILE"
  printf "\n%b" $COLOR_CYAN; $COMMAND $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} -ignore 'Name .cache*' -prefer $FOLDER1 -nodeletion $FOLDER1 -logfile $LOGFILE.INFO | tee -a $LOGFILE
  export RETVAL=$?
  printf "%b" $COLOR_NORMAL
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  LOG_RESULTS | tee -a $LOGFILE
  echo -e "\n"
done

exit $RETVAL
# The End
