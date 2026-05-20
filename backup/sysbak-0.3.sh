#! /bin/bash
## VERY Simple Script to Backup System Files

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

# Define RUN_CMD and VERSION
export RUN_CMD="$(basename $0)"
export VERSION="0.3"

# Define Arrays that are independant of the Environmanet
declare -a APPEND_BAK_TARGET_ARRAY=();
declare -a APPEND_BAK_SOURCE_PATH=();
declare -a APPEND_BAK_SOURCE_ARRAY=();

declare -i APPEND_BAK_TARGET_ARRAY_LEN=${#APPEND_BAK_TARGET_ARRAY[@]}
declare -i APPEND_BAK_SOURCE_PATH_LEN=${#APPEND_BAK_SOURCE_PATH[@]}
declare -i APPEND_BAK_SOURCE_ARRAY_LEN=${#APPEND_BAK_SOURCE_ARRAY[@]}
declare -i FINAL_RETVAL=$FAILURE
declare -i SCRIPT_PID=$$
declare -i PROC_COUNT=$(ps -ax | grep -v grep | grep $RUN_CMD | wc -l)-1

#Self explanitory function
function BACKUP()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1
  for TARGET in ${BAK_TARGET_ARRAY[@]}; do
    ((INDEX++))
    if [ $BOL_QUIET -eq $FALSE ]; then SHOW_DATE_TIME; printf "%s\t%s %s\n" "Started: " "Creating backup file: " "$TARGET";										fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; printf "%s\t%s\n" "Executing: " "$TAR_BIN --xz $VERBOSE -cf $TARGET -C ${BAK_SOURCE_PATH[$((INDEX))]} ${BAK_SOURCE_ARRAY[$((INDEX))]}";	fi
    $TAR_BIN --xz $VERBOSE -cf "$TARGET" -C "${BAK_SOURCE_PATH[$((INDEX))]}" ${BAK_SOURCE_ARRAY[$((INDEX))]}
    export RETVAL=$?
    FUNCTION_RETURN=$(($FUNCTION_RETURN+$RETVAL))
    export COMMAND="$TAR_BIN: Return Value: $RETVAL"
    if [ $BOL_QUIET -eq $FALSE ]; then SHOW_DATE_TIME; printf "%s\t%s\n" "Finished: " "Creating backup file: $TARGET"; SHOW_DATE_TIME; LOG_RESULTS;							fi
    unset COMMAND
    $SLEEP_BIN 1
    if [ $BOL_QUIET -eq $FALSE ]; then echo -e "\n";																	fi
  done
  return $FUNCTION_RETURN
};

function UNMOUNT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $UMOUNT_BIN $BAK_MOUNT";									fi
  $UMOUNT_BIN "$BAK_MOUNT" 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$UMOUNT_BIN Return Value: $RETVAL"
  if [ $BOL_QUIET -eq $FALSE ]; then LOG_RESULTS; unset COMMAND; echo -e '';										fi
  $SLEEP_BIN 1
  return $RETVAL
};

function MOUNT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $MOUNT_BIN -o $MOUNT_OPTS $NFS_EXPORT $BAK_MOUNT";						fi
  $MOUNT_BIN -o $MOUNT_OPTS "$NFS_EXPORT" "$BAK_MOUNT" 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$MOUNT_BIN Return Value: $RETVAL"
  $SLEEP_BIN 1
  if [ $BOL_QUIET -eq $FALSE ]; then LOG_RESULTS; unset COMMAND; echo -e '';										fi
  if [ $($MOUNT_BIN | $GREP_BIN $BAK_MOUNT | $WC_BIN -l)     -lt 1	]; then echo -e  "$BAK_MOUNT not mounted!"; exit $FAILURE;		       	fi
  if [ ! -d "$BACKUP_PATH" ]; then mkdir -p "$BACKUP_PATH"; if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Created Directory $BACKUP_PATH"; fi;		fi
  return $RETVAL
};

# Check for command line arguments
for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --hostname=*)	export NETBIOS_HOSTNAME="${OPTIONS#*=}";;
    --fqdn-hostname=*)	export FQDN_HOSTNAME="${OPTIONS#*=}";;
    --kernel=*)		export KERNEL="${OPTIONS#*=}";;
    --bak-ext=*)	export BAK_EXT="${OPTIONS#*=}";;
    --bak-mount=*)	export BAK_MOUNT="${OPTIONS#*=}";;
    --bak-path=*)	export BACKUP_PATH="${OPTIONS#*=}";;
    --nfs-server=*)	export NFS_SERVER="${OPTIONS#*=}";;
    --nfs-export=*)	export NFS_EXPORT="${OPTIONS#*=}";;
    --dow=*)		export DOW="${OPTIONS#*=}";;
    --mount-opts=*)	export MOUNT_OPTS="${OPTIONS#*=}";;
    --cfg-file=*)	export CFG_FILE="${OPTIONS#*=}";;
    --threshold=*)	export PROC_THRESHOLD="${OPTIONS#*=}";;
    -d | --debug)	export BOL_DEBUG=$TRUE;;
    -v | --verbose)	export BOL_QUIET=$FALSE;		export BOL_VERBOSE=$TRUE;		export VERBOSE="--verbose";;
    -q | --quiet)	export BOL_QUIET=$TRUE;			export BOL_VERBOSE=$FALSE;		export VERBOSE="";;
    -t | --test)	export TAR_BIN=$TRUE_BIN;;
  esac
done

# Define Variables that are not already defined
# Either as environment variables or set by command line options defined above
if [ ${#CFG_FILE}			-eq 0 ]; then export CFG_FILE="/etc/sysbak.cfg";									fi
if [ -f $CFG_FILE			      ]; then . $CFG_FILE; echo -e "Loaded Config File $CFG_FILE";							fi
if [ ${#BOL_MNT}			-eq 0 ]; then declare -i BOL_MNT=$TRUE;											fi
if [ ${#BOL_BAK}			-eq 0 ]; then declare -i BOL_BAK=$TRUE;											fi
if [ ${#BOL_QUIET}                      -eq 0 ]; then declare -i BOL_QUIET=$FALSE;                                                                              fi
if [ ${#BOL_VERBOSE}                    -eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;                                                                            fi
if [ ${#NETBIOS_HOSTNAME}		-eq 0 ]; then export NETBIOS_HOSTNAME=$($HOSTNAME_BIN --short);								fi
if [ ${#FQDN_HOSTNAME}			-eq 0 ]; then export FQDN_HOSTNAME=$($HOSTNAME_BIN --fqdn);								fi
if [ ${#KERNEL}				-eq 0 ]; then export KERNEL=$(uname -r);										fi
if [ ${#BAK_EXT}			-eq 0 ]; then export BAK_EXT="tar.xz";											fi
if [ ${#BAK_MOUNT}			-eq 0 ]; then export BAK_MOUNT="/mnt/bak";										fi
if [ ${#NFS_SERVER}			-eq 0 ]; then export NFS_SERVER="lxc.gigaware.lan";									fi
if [ ${#NFS_EXPORT}			-eq 0 ]; then export NFS_EXPORT="$NFS_SERVER:/opt/bak";									fi
if [ ${#DOW}				-eq 0 ]; then export DOW=$(date +%A);											fi
if [ ${#MOUNT_OPTS}             	-eq 0 ]; then export MOUNT_OPTS="defaults";										fi
if [ ${#BACKUP_PATH}			-eq 0 ]; then export BACKUP_PATH="$BAK_MOUNT/$FQDN_HOSTNAME/$DOW";							fi
if [ ${#PROC_THRESHOLD}			-eq 0 ]; then export PROC_THRESHOLD=1;											fi
if [ $PROC_COUNT	-gt   $PROC_THRESHOLD ]; then echo -e "Process Threshold ($PROC_THRESHOLD) Exceded  ($PROC_COUNT). Exiting"; exit $SUCCESS;		fi
if [ ! -d "$BAK_MOUNT"                        ]; then mkdir -p "$BAK_MOUNT"; echo -e "Created Directory $BAK_MOUNT";                  				fi
if [ $BOL_MNT			    -eq $TRUE ]; then MOUNT;													fi
if [ ! -d "$BACKUP_PATH"                      ]; then mkdir -p "$BACKUP_PATH"; echo -e "Created Directory $BACKUP_PATH";              				fi
if [ ${#BAK_TARGET_ARRAY[@]}		-eq 0 ]; then declare -ag BAK_TARGET_ARRAY=( "$BACKUP_PATH/boot.$KERNEL.$BAK_EXT" "$BACKUP_PATH/etc.$BAK_EXT" "$BACKUP_PATH/lib.modules.$KERNEL.$BAK_EXT" "$BACKUP_PATH/lib.systemd.$BAK_EXT" "$BACKUP_PATH/usr.local.$BAK_EXT" );		fi
if [ ${#BAK_SOURCE_PATH[@]}		-eq 0 ]; then declare -ag BAK_SOURCE_PATH=( "/boot" "/etc" "/lib/modules/$KERNEL" "/lib/systemd" "/usr/local" );	fi
if [ ${#BAK_SOURCE_ARRAY[@]}		-eq 0 ]; then declare -ag BAK_SOURCE_ARRAY=( "efi extlinux flask grub grub2 init*-$KERNEL.img loader System.map-$KERNEL config-$KERNEL vmlinuz-$KERNEL xen*" '.' '.' '.' "bin etc include lib lib64 libexec samba scripts sbin" );	fi
if [ $BOL_BAK	 		    -eq $TRUE ]; then BACKUP; FINAL_RETVAL=$?;											fi
if [ $BOL_MNT                       -eq $TRUE ]; then UNMOUNT;                                                                                                  fi

# All Done
exit $FINAL_RETVAL