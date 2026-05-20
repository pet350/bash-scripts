#!/bin/bash
# global-strings.sh
# Version 0.2
# Peter Talbott
# Simple shell script to define string values

## Most significant version update is totally rewritten GET_BIN()

# Define Directoy Prefix String Variables
if [ ${#BIN_PREFIX}	 -eq 0 ];	then	export BIN_PREFIX="/bin";		fi
if [ ${#USR_PREFIX}	 -eq 0 ];	then	export USR_PREFIX="/usr";		fi
if [ ${#CFG_PREFIX}	 -eq 0 ];	then	export CFG_PREFIX="/etc";		fi
if [ ${#LIB_PREFIX}	 -eq 0 ];	then	export LIB_PREFIX="/lib";		fi
if [ ${#VAR_PREFIX}	 -eq 0 ];	then	export VAR_PREFIX="/var";		fi
if [ ${#SBIN_PREFIX}	 -eq 0 ];	then	export SBIN_PREFIX="/sbin";		fi
if [ ${#LOCAL_PREFIX}	 -eq 0 ];	then	export LOCAL_PREFIX="/local";		fi

# New Version, Much More Efficient
function GET_BIN()
{
  declare -i FUNCTION_RETURN=$FAILURE
  for PREFIX in $BIN_PREFIX $SBIN_PREFIX $USR_PREFIX$BIN_PREFIX $USR_PREFIX$SBIN_PREFIX $USR_PREFIX$LOCAL_PREFIX$BIN_PREFIX; do
    if [ -f $PREFIX/$TEMP ]; then
      echo -e "$PREFIX/$TEMP"
      FUNCTION_RETURN=$SUCCESS
      break 2
    fi
  done
  return $FUNCTION_RETURN
};

# Define an array of all the Binaries to locate and define
declare -ag CMD_ARRAY=( "apt" "blkid" "bzcat" "bzip2" "chgrp" "chmod" "chown" "compton" "cut" "docker" "daemon" "du" 		\
  "false" "fdisk" "ffmpeg" "ffplay"  "free" "fsck" "grep" "gzip" "head" "ifconfig" "insmod" "inotifywait"			\
  "ip" "ipa" "iptables" "klist" "ldapadd" "ldapmodify" "ldapsearch" "ldapwhoami" "lscpu" "lspci" "ls" "lz4"			\
  "lsmod" "lsusb" "mencoder" "mkdir" "nmap" "modprobe" "mount" "net" "pgrep" "ping" "ps"					\
  "python" "python3" "rapiddisk" "rmdir" "sleep" "smartctl" "swapoff" "swapon" "systemctl" "tail"				\
  "tar"	"true" "umount" "unison" "uptime" "virsh" "wc" "wbinfo" "xfs_repair" "xl" "xrandr" "xz"					);

# Define Commonly Used Binary Variables
for TEMP in ${CMD_ARRAY[@]}; do
  DATA=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${TEMP^^}_BIN"=$DATA
  fi
  unset TEMP
done

# Define Exceptions that the above could not handle due to special charecters
export TEMP="fsck.ext4";        export FSCK_EXT4_BIN=$(GET_BIN)
export TEMP="ipa-getkeytab";	export IPA_GETKEYTAB_BIN=$(GET_BIN)
export TEMP="update-rc.d";      export UPDATE_RC_BIN=$(GET_BIN)

# Define more clear definitions of some Binaries
export LDAP_ADD_BIN=$LDAPADD_BIN
export LDAP_MODIFY_BIN=$LDAP_MODIFY_BIN
export LDAP_SEARCH_BIN=$LDAPSEARCH_BIN
export LDAP_WHOAMI_BIN=$LDAPWHOAMI_BIN
export SYSCTL_BIN=$SYSTEMCTL_BIN
export FSCK_XFS_BIN=$XFS_REPAIR_BIN

# Clear TEMP
unset TEMP

# Define Misc String Values
export KERNEL=$(/bin/uname -r)

# Build Specific Strings
export LC_ALL=en_US.UTF-8

# Define commonly used text strings if not already
if [ ${#EDITOR}		-eq 0 ]; then			export EDITOR="nano";				fi
if [ ${#ETC_SYSD}	-eq 0 ]; then			export ETC_SYSD="/etc/systemd/system";		fi
if [ ${#LIB_SYSD}	-eq 0 ]; then			export LIB_SYSD="/lib/systemd/system";		fi
if [ ${#LOSBIN}		-eq 0 ]; then			export LOSBIN="/usr/local/sbin";		fi
if [ ${#LOBIN}		-eq 0 ]; then			export LOBIN="/usr/local/bin";			fi
if [ ${#JAVA_HOME}	-eq 0 ]; then
  for JRE_PATH in  "/usr/lib/jvm/jre" "/usr/lib64/jvm/jre" "/usr/lib/jvm/default-java"; do
    if [ -d $JRE_PATH ]; then export JAVA_HOME=$JRE_PATH; fi
  done
fi
