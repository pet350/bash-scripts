#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018; 04/10/2019

# Current Version
VERSION=0.1

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

declare -ig PROC_THRESHOLD=3
declare -ig CURRENT_PROC=$(ps -ax | grep /usr/local/sbin/UnisonScripts.sh | wc -l)

# Define String Variables
export RUN_CMD="$(basename $0)"
export LOG_PREFIX="/var/log/unison"

# Make Sure That Only Root is Running this Script
if [ $(id -u) -gt 0 ]; then
  echo -e "Error: $RUN_CMD Version $VERSION\nMust be ran as ROOT user!" | tee >>$LOGFILE.OUT >/dev/stdout
  exit $FAILURE
fi

if [ $CURRENT_PROC -gt $PROC_THRESHOLD ]; then
  echo -e "Error: Current Process Count: $CURRENT_PROC Excedes Threshold: $PROC_THRESHOLD!!" | tee >>$LOGFILE.OUT >/dev/stdout
  exit $FAILURE
fi

if [ ! -d $LOG_PREFIX ]; then mkdir -p $LOG_PREFIX; fi

# Synchronize These Folders
FOLDER1_ARRAY=("/usr/local/");
FOLDER2_ARRAY=("/nfs/ipa.gigaware.lan/usr/local/");
index=0
for DATA in $(ls -1 /home); do
  ((index++))
  FOLDER1_ARRAY[$((index))]="/home/$DATA/"
  FOLDER2_ARRAY[$((index))]="/nfs/ipa.gigaware.lan/home/$DATA/"
done

# Define the Log Filename
DOW=$(date +%w)
FULL_DATE=$(date +%F)
FULL_TIME=$(date +%r)
LOGFILE="/var/log/unison/$DOW-Server.log"
echo -e "[$FULL_DATE @ $FULL_TIME] Start of Log: " | tee >>$LOGFILE >/dev/stdout

# Define Local Host Name
UNISONLOCALHOSTNAME="$(hostname -f)"

# Define Options
OPTIONS_ARRAY=("-auto" "-batch" "-times" "-numericids" "-rsync" "-killserver");



# Run Unison With The PreDefined Variables Above
index=-1
for DATA in ${FOLDER1_ARRAY[@]}; do
  ((index++))
  FOLDER1="$DATA"
  FOLDER2="${FOLDER2_ARRAY[$((index))]}"
  echo -e "unison $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} -prefer $FOLDER1 -nodeletion $FOLDER1 -logfile $LOGFILE | tee >>$LOGFILE.OUT >/dev/stdout"
  unison $FOLDER1 $FOLDER2 ${OPTIONS_ARRAY[@]} -ignore 'Name .cache*' -prefer $FOLDER1 -nodeletion $FOLDER1 -logfile $LOGFILE | tee >>$LOGFILE.OUT >/dev/stdout
done


# The End
