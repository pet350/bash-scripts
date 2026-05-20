#!/bin/bash
# written by Tomas (http://www.lisenet.com)
# 07/02/2016 (dd/mm/yy)
# copyleft free software
# Simple script to keep cluster nodes in sync
#
LOGFILE=""$HOME"/rsync_nodes.log";
# Nodes to keep in sync.
NODE1="pcmk01";
NODE2="pcmk02";
NODE3="pcmk03";
# Files and directories to sync.
# More files can be added as required.
FILE1="/etc/hosts";
FILE2="/etc/sysconfig/iptables";
FILE3="/etc/sysctl.conf";
FILE4="/etc/security/limits.conf";
FILE5="/etc/multipath.conf";
DIR1="/etc/yum.repos.d/";
#
echo "Logfile is: "$LOGFILE"";
echo "Syncing "$FILE1"";
rsync -av "$FILE1" "$NODE2":"$FILE1" >>"$LOGFILE" 2>&1;
rsync -av "$FILE1" "$NODE3":"$FILE1" >>"$LOGFILE" 2>&1;
echo "Syncing "$FILE2"";
rsync -av "$FILE2" "$NODE2":"$FILE2" >>"$LOGFILE" 2>&1;
rsync -av "$FILE2" "$NODE3":"$FILE2" >>"$LOGFILE" 2>&1;
echo "Syncing "$FILE3"";
rsync -av "$FILE3" "$NODE2":"$FILE3" >>"$LOGFILE" 2>&1;
rsync -av "$FILE3" "$NODE3":"$FILE3" >>"$LOGFILE" 2>&1;
echo "Syncing "$FILE4"";
rsync -av "$FILE4" "$NODE2":"$FILE4" >>"$LOGFILE" 2>&1;
rsync -av "$FILE4" "$NODE3":"$FILE4" >>"$LOGFILE" 2>&1;
echo "Syncing "$FILE5"";
rsync -av "$FILE5" "$NODE2":"$FILE5" >>"$LOGFILE" 2>&1;
rsync -av "$FILE5" "$NODE3":"$FILE5" >>"$LOGFILE" 2>&1;
echo "Syncing "$DIR1"";
rsync -av "$DIR1" "$NODE2":"$DIR1" >>"$LOGFILE" 2>&1;
rsync -av "$DIR1" "$NODE3":"$DIR1" >>"$LOGFILE" 2>&1;
exit 0;
