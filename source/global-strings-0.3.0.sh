#!/bin/bash
# global-strings.sh
# Version 0.3
# Peter Talbott
# Simple shell script to define string values

## Most significant version update is totally rewritten GET_BIN()

# Define Version of this file
export GLOBAL_STRINGS_VERSION=0.3

# if exists, load java config file to set JAVA_HOME environment Variable
if [ -f /etc/java-home.cfg    ]; then . /etc/java-home.cfg;				fi

# Define Directoy Prefix String Variables
if [ ${#BIN_PREFIX}	-eq 0 ]; then export BIN_PREFIX="/bin";				fi
if [ ${#USR_PREFIX}	-eq 0 ]; then export USR_PREFIX="/usr";				fi
if [ ${#CFG_PREFIX}	-eq 0 ]; then export CFG_PREFIX="/etc";				fi
if [ ${#LIB_PREFIX}	-eq 0 ]; then export LIB_PREFIX="/lib";				fi
if [ ${#VAR_PREFIX}	-eq 0 ]; then export VAR_PREFIX="/var";				fi
if [ ${#SBIN_PREFIX}	-eq 0 ]; then export SBIN_PREFIX="/sbin";			fi
if [ ${#LOCAL_PREFIX}	-eq 0 ]; then export LOCAL_PREFIX="/local";			fi
if [ ${#ETC_SYSD}	-eq 0 ]; then export ETC_SYSD="$CFG_PREFIX/systemd/system";	fi
if [ ${#LIB_SYSD}	-eq 0 ]; then export LIB_SYSD="$LIB_PREFIX/systemd/system";	fi

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
declare -ag CMD_ARRAY=( "apt" "blkid" "bzcat" "bzip2" "chgrp" "chmod" "chown" "compton" "cut" "curl" "docker" "daemon" "du" 	\
  "false" "fdisk" "ffmpeg" "ffplay"  "free" "fsck" "grep" "gzip" "head" "ifconfig" "insmod" "inotifywait"			\
  "ip" "ipa" "iptables" "klist" "ldapadd" "ldapmodify" "ldapsearch" "ldapwhoami" "lscpu" "lspci" "ls" "lz4"			\
  "lsmod" "lsusb" "mencoder" "mkdir" "nmap" "modprobe" "mount" "net" "pgrep" "ping" "ps"					\
  "python" "python3" "rapiddisk" "rmdir" "sleep" "smartctl" "swapoff" "swapon" "systemctl" "tail"				\
  "tar"	"true" "umount" "unison" "uptime" "virsh" "wc" "wbinfo" "xfs_repair" "xl" "xrandr" "xz"	"xzcat"				);

# Define Commonly Used Binary Variables
# Revised 04-28-2022 PT
for TEMP in ${CMD_ARRAY[@]}; do
  GET_BIN >/dev/null
  if [ $? -eq $SUCCESS ]; then export "${TEMP^^}_BIN"=$(GET_BIN); fi
  unset TEMP
done

# Define Exceptions that the above could not handle due to special charecters
export TEMP="fsck.ext4";        export FSCK_EXT4_BIN=$(GET_BIN)
export TEMP="ipa-getkeytab";	export IPA_GETKEYTAB_BIN=$(GET_BIN)
export TEMP="update-rc.d";      export UPDATE_RC_BIN=$(GET_BIN)

# Define more clear definitions of some Binaries
export LDAP_ADD_BIN=$LDAPADD_BIN
export LDAP_MODIFY_BIN=$LDAPMODIFY_BIN
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

# Define commonly used text editor
export EDITOR="nano"

# Set LS_COLORS if not already set
if [ ${#LS_COLORS} 	-eq 0 ]; then export LS_COLORS="rs=0:di=38;5;33:ln=38;5;51:mh=00:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=01;37;41:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;40:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.zst=38;5;9:*.tzst=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.wim=38;5;9:*.swm=38;5;9:*.dwm=38;5;9:*.esd=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.mjpg=38;5;13:*.mjpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.m4a=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.oga=38;5;45:*.opus=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:"; fi
if [ ${#YOUTUBEOPTS}	-eq 0 ]; then export YOUTUBEOPTS="--embed-thumbnail --geo-bypass --force-ipv4 --yes-playlist --retries 20 --restrict-filenames --continue --no-overwrites --no-warnings --console-title --merge-output-format mp4 --no-check-certificate --verbose ";	fi
if [ ${#FFOPTS265}	-eq 0 ]; then export FFOPTS265="-c:v libx265 -vtag hvc1 -vf scale=1280x720 -c:a libmp3lame -movflags faststart -preset ultrafast";															fi
if [ ${#FFOPTS264}	-eq 0 ]; then export FFOPTS264="-c:v libx264 -crf 25 -vf scale=1280x720,fps=fps=29.97 -tune zerolatency -preset ultrafast -c:a libmp3lame -movflags faststart -maxrate 2M -bufsize 8M";									fi
if [ ${#FFMINIMAL264}   -eq 0 ]; then export FFMINIMAL264="-c:v libx264 -tune zerolatency -preset ultrafast -c:a libmp3lame -movflags faststart";        															fi

