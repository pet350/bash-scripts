#!/bin/bash
# 100% Revised and Major improvements
# Origonal code at (http://www.lisenet.com)
# By: Peter Talbott
# 02/09/2024

alias rscp="rsync -ave ssh"

declare -x USERNAME="$(whoami)"
declare -x LOGFILE=""$HOME"/rsync_nodes.log";
declare -a NODES=( "rodc.gigaware.lan" "xen.gigaware.lan" "jakku.gigaware.lan" );
declare -i NODES_LEN=${#NODES[@]}
declare -a SRC=( "/etc/hosts" "/etc/sysconfig/iptables" "/etc/sysctl.conf" "/etc/corosync" "/usr/local/sbin" "/var/lib/pacemaker" \
		 "/etc/security/limits.conf" "/etc/multipath.conf" "/etc/ldap.conf" "/etc/crm" "/etc/krb5.conf" \
		 "/etc/openldap" "/etc/drbd.d" "/usr/local/scripts" "/etc/pacemaker" "/etc/auto.master.d" );
declare -i SRC_LEN=${#SRC[@]}
declare -i COUNT=-1
declare -x CUR_HOST="$(hostname -f)"

function LINE()
{
  declare -i COUNT=0
  declare -i MAX=$1
  while [ $COUNT -lt $MAX ]; do
    ((COUNT++))
    printf "-"
  done
  printf "\n\n"
  return 0
};

echo -e "Nodes: ${NODES[@]}"
echo -e "Sync List: ${SRC[@]}"
LINE 100
while [ $COUNT -lt $((SRC_LEN-1)) ]; do
  ((COUNT++))
  TEMP="${SRC[$((COUNT))]}"
  TARGET_PATH=${TEMP%/*}
  echo -e "Current Node: $CUR_HOST"
  echo -e "Logfile is: $LOGFILE"
  echo -e "Syncing: $TEMP"
  echo -e "Target Path: $TARGET_PATH"
  LINE 75
  declare -i NODE_COUNT=-1
  while [ $NODE_COUNT -lt $((NODES_LEN-1)) ]; do
    ((NODE_COUNT++))
    declare -x TARGET_NODE="${NODES[$((NODE_COUNT))]}"
    if [ "$CUR_HOST" != $TARGET_NODE ]; then
        echo -e "Target Node: $TARGET_NODE"
	echo -e "Executing: rsync -av $TEMP $USERNAME@$TARGET_NODE:$TARGET_PATH | tee $LOGFILE"
        rsync -av $TEMP $USERNAME@$TARGET_NODE:$TARGET_PATH | tee $LOGFILE;
	declare -i RETVAL=$?
	if [ $RETVAL -eq 0 ]; then echo -e "Success: Return Value $RETVAL"; else echo -e "Failure: Return Value $RETVAL"; fi
	LINE 75
    fi
  done
  LINE 100
done
exit $RETVAL
