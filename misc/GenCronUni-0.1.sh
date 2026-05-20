#!/bin/bash
# By: Peter Talbott
# 09/06/2018; 04/10/2019, 6/6/2020

# Current Version
export VERSION=0.4.2

# Source function library.
source /lib/lsb/init-functions

if [ -f /usr/local/scripts/include/*.sh ]; then
  for INCLUDE_FILE in $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
fi

declare -ig RANDOM_MIN=$((2" "+" "RANDOM" "%" "19))

# Define Global Arrays
declare -ag TEMPLATE_ARRAY=("##" "Cron" "File" "To" "Run" "backup-sys-cfg.sh" "Version" "0.1" "Daily" "\n\n" \
  "SHELL=/bin/sh" "\n" "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" "\n\n"








ers4.sh" "UnisonServers.sh" "unmask-0.5.sh" "unmask.sh" "update-uuid.sh" "apt-list-0.1.sh" "apt-list-0.2.sh" "apt-list.sh" "AutoStart.d-0.1.sh" "AutoStart.d-0.2.sh" "AutoStart.d.sh" "Batch-x264-.0.1.sh" "batchx264.sh" "Batch-x264.sh" "btrfs-undelete-0.1.sh" "btrfs-undelete.sh" "CheckServices-0.1.sh" "CheckServices.sh" "chroot-0.1.sh" "chroot.example.sh" "chroot.sh" "CleanVarLog-0.1.sh" "CleanVarLog.sh" "ClearAptBtrfs-0.1.sh" "ClearAptBtrfs.sh" "CronUnisonServers.sh" "disable-service-0.1.sh" "disable-service.sh" "dis-apparmor-prof-0.1.sh" "dis-apparmor-prof-0.2.sh" "dis-apparmor-prof.sh" "DisAppProf.sh" "dl-list.sh" "enable-service-0.1.sh" "enable-service.sh" "encode-0.1.sh" "encode-0.2.sh" "encode-0.3.sh" "encode-0.4.sh" "encode.sh" "fix-snmpd-0.1.sh" "fix-snmpd.sh" "FreeBuffCache-0.1.sh" "FreeBuffCache.sh" "GenCronUni-0.1.sh" "ImageFile-Set-UUID.sh" "KillAllUnison-0.1.sh" "KillAllUnison.sh" "KillScreenSaver.sh" "ldap-avatar-0.1.sh" "ldap-avatar.sh" "listppa-0.1.sh" "listppa.sh" "m4a-to-mp3.sh" "MakeVMDK-0.1.sh" "mask-0.5.sh" "mask.sh" "numlockon-0.1.sh" "numlockon.sh" "pciback.sh" "rcstatus-0.1.sh" "rcstatus.sh" "RemoveCloudInit-0.1.sh" "RemoveCloudInit.sh" "RemoveDuplicates-0.1.sh" "RemoveDuplicates.sh" "restart-0.1.sh" "restart-0.2.sh" "restart-0.3.sh" "restart-0.5.sh" "restart.sh" "start-0.1.sh" "start-0.2.sh" "start-0.3.sh" "start-0.5.sh" "start-gnome-keyring-0.1.sh" "start-gnome-keyring.sh" "StartNetwork-0.1.sh" "StartNetwork.sh" "start.sh" "status-0.1.sh" "status-0.2.sh" "status-0.3.sh" "status-0.5.sh" "status.sh" "stop-0.1.sh" "stop-0.2.sh" "stop-0.3.sh" "stop-0.5.sh" "stop.sh" "SyncServers-0.1.sh" "SyncServers.sh" "tuntap" "UnisonDaemon-0.1.sh" "UnisonDaemon.sh" "UnisonLibServer-0.1.sh" "UnisonMySQL-0.1.sh" "UnisonMySQL.sh" "UnisonPeteServer.0.1.sh" "UnisonScripts-0.1.sh" "UnisonScripts-0.2.sh" "UnisonScripts.sh" "UnisonServers-0.1.sh" "UnisonServers-0.2.sh" "UnisonServers-0.3.sh" "UnisonServers-0.4.1.sh" "UnisonServers-0.4.2.sh" "UnisonServers-0.4.sh" "UnisonServers4.sh" "UnisonServers.sh" "unmask-0.5.sh" "unmask.sh" "update-uuid.sh" "root" "/usr/local/sbin/UnisonServers.sh" "--custom-folder=/usr/local/scripts" "--add-folder=/usr/local/etc" "--add-folder=/usr/local/sbin" "--prefer-remote" "--force-color" "|" "tee" "/var/log/UnisonScripts.log" */$((RANDOM_MIN)) *	* * *	root	/usr/local/sbin/UnisonServers.sh --custom-folder=/usr/local/scripts --add-folder=/usr/local/etc --add-folder=/usr/local/sbin --prefer-remote --force-color | tee /var/log/UnisonScripts.log
