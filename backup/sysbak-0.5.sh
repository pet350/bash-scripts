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
export VERSION="0.5"
export AUTHOR="Peter Talbott"
export MODIFIED="2021-08-26, 2021-08-27"

case "${BASH_VERSINFO[5],,}" in # Check and see if were runnnnig on OpenWRT
  x86_64-openwrt-linux-gnu)	# Script IS running on OpenWRT Hardware (or VM)
    export PS_OPT="";		export XZ="";		export COMPRESS="";		export BOL_WRT=$TRUE;		export BOL_FORCE_COLOR=$TRUE;;
  *)				# Script is NOT running on OpenWRT Hardware (or VM)
    export PS_OPT="-ax";	export XZ=".xz";	export COMPRESS="--xz";		export BOL_WRT=$FALSE;;
esac

# Define Arrays that are independant of the Environmanet
declare -a APPEND_BAK_TARGET_ARRAY=();
declare -a APPEND_BAK_SOURCE_PATH=();
declare -a APPEND_BAK_SOURCE_ARRAY=();

declare -i APPEND_BAK_TARGET_ARRAY_LEN=${#APPEND_BAK_TARGET_ARRAY[@]}
declare -i APPEND_BAK_SOURCE_PATH_LEN=${#APPEND_BAK_SOURCE_PATH[@]}
declare -i APPEND_BAK_SOURCE_ARRAY_LEN=${#APPEND_BAK_SOURCE_ARRAY[@]}

declare -i FINAL_RETVAL=$FAILURE
declare -i SCRIPT_PID=$$
declare -i PROC_COUNT=$(ps $PS_OPT | grep -v grep | grep $RUN_CMD | wc -l)

if [ ${#BOL_CHECK_PROC}		-eq 0 ]; then	declare -i BOL_CHECK_PROC=$TRUE; fi
# Functions for changing text color a lot easier!
function CN_TEXT() {  printf "%b" $CN;  return $SUCCESS; };
function CK_TEXT() {  printf "%b" $CK;  return $SUCCESS; };
function CR_TEXT() {  printf "%b" $CR;  return $SUCCESS; };
function CG_TEXT() {  printf "%b" $CG;  return $SUCCESS; };
function CO_TEXT() {  printf "%b" $CO;  return $SUCCESS; };
function CB_TEXT() {  printf "%b" $CB;  return $SUCCESS; };
function CP_TEXT() {  printf "%b" $CP;  return $SUCCESS; };
function CC_TEXT() {  printf "%b" $CC;  return $SUCCESS; };
function CY_TEXT() {  printf "%b" $CY;  return $SUCCESS; };
function CW_TEXT() {  printf "%b" $CW;  return $SUCCESS; };
function CLA_TEXT() { printf "%b" $CLA; return $SUCCESS; };
function CLR_TEXT() { printf "%b" $CLR; return $SUCCESS; };
function CLP_TEXT() { printf "%b" $CLP; return $SUCCESS; };
function CLC_TEXT() { printf "%b" $CLC; return $SUCCESS; };
function CLB_TEXT() { printf "%b" $CLB; return $SUCCESS; };
function CLG_TEXT() { printf "%b" $CLG; return $SUCCESS; };
function CDA_TEXT() { printf "%b" $CDA; return $SUCCESS; };

# Self explanitory function
function SHOW_HEADER()
{
  printf "%s: " "$(SHOW_DATE_TIME)";	CLB_TEXT; printf "%s:\t" "$RUN_CMD";	CLG_TEXT; printf "Version: ";  CY_TEXT;  printf "%s\t" "$VERSION";	CLG_TEXT; printf "By: "; CLR_TEXT
  printf "%s " "$AUTHOR";		CLG_TEXT; printf "Dated: ";		CLR_TEXT; printf "%s\n" "$MODIFIED"
  printf "%s: " "$(SHOW_DATE_TIME)";	CLB_TEXT; printf "%s:\t" "$BASH_BIN";	CLG_TEXT; printf "Version: ";  CY_TEXT;  printf "%s\n" "${BASH_VERSINFO[5]^^}";	CN_TEXT
  return $SUCCESS
};

# Create Backup Path IF it does not exist
function CHECK_BAK_PATH()
{
  declare -i RETVAL=$SUCCESS
  if [ ! -d "$BACKUP_PATH" ]; then
    mkdir -p "$BACKUP_PATH" 2>/dev/null; RETVAL=$?
    if [ $RETVAL -ne $SUCCESS ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLR_TEXT; printf "Cannot Create Dir:\t"; CY_TEXT; printf "%s\n" "$BACKUP_PATH"; CN_TEXT; exit $RETVAL;											fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Created Dir:\t"; CY_TEXT; printf "%s\n" "$BACKUP_PATH"; CN_TEXT;													fi
  fi
  return $RETVAL
};

function VERIFY_SOURCE()
{
  declare -i FUNCTION_RETURN=$FAILURE
  export DATA="$SOURCE_PREFIX/$SOURCE_FILE"

  if [ -d "$DATA" ] || [ -f "$DATA" ]; then printf "%s " $SOURCE_FILE; FUNCTION_RETURN=$SUCCESS;																				fi
  return $FUNCTION_RETURN
};

# Self explanitory function
function BACKUP()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i RETVAL=$SUCCESS
  declare -i INDEX=-1

  for TARGET in ${BAK_TARGET_ARRAY[@]}; do
    ((INDEX++))
    if [ $BOL_QUIET -eq $FALSE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Started:\t"; CLG_TEXT; printf  "Creating backup file: "; CY_TEXT; printf "%s\n" "$TARGET"; CN_TEXT;									fi
    if [ ${#BAK_SOURCE_ARRAY[$((INDEX))]} -ne 0 ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Executing:\t"; CLR_TEXT; printf "%s\n" "$TAR_BIN;  $COMPRESS $VERBOSE -cf $TARGET -C ${BAK_SOURCE_PATH[$((INDEX))]} ${BAK_SOURCE_ARRAY[$((INDEX))]}"; CN_TEXT;	fi
      CC_TEXT; $TAR_BIN $COMPRESS $VERBOSE -cf "$TARGET" -C "${BAK_SOURCE_PATH[$((INDEX))]}" ${BAK_SOURCE_ARRAY[$((INDEX))]} 2>/dev/null; export RETVAL=$?; CN_TEXT
    else
      if [ $BOL_QUIET -eq $FALSE ]; then
        printf "%s: " "$(SHOW_DATE_TIME)"; CLR_TEXT; printf "No File List:\t"; CLG_TEXT; printf "from "; CY_TEXT; printf "%s\n" "${BAK_SOURCE_PATH[$((INDEX))]}"
        printf "%s: " "$(SHOW_DATE_TIME)"; CLR_TEXT; printf "Skipping:\t"; CLG_TEXT; printf "Creation of:  "; CY_TEXT; printf "%s\n" "$TARGET"; CN_TEXT
      fi
      export RETVAL=$SUCCESS
    fi
    FUNCTION_RETURN=$(($FUNCTION_RETURN+$RETVAL))
    export COMMAND="$TAR_BIN: Return Value: $RETVAL"
    if [ $BOL_QUIET -eq $FALSE ]; then
      printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Finished:\t"; CLG_TEXT; printf "Creating backup file: "; CY_TEXT; printf "%s\n" "$TARGET"
      printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Results:\t";  LOG_RESULTS
    fi
    unset COMMAND
    $SLEEP_BIN 1
    if [ $BOL_QUIET -eq $FALSE ]; then printf "\n";																										fi
  done
  return $FUNCTION_RETURN
};

function UNMOUNT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Executing:\t"; CLR_TEXT; printf "%s\n" "$UMOUNT_BIN $BAK_MOUNT"; CN_TEXT;												fi
  $UMOUNT_BIN "$BAK_MOUNT" 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$UMOUNT_BIN Return Value: $RETVAL"
  if [ $BOL_QUIET -eq $FALSE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Results:\t"; LOG_RESULTS; unset COMMAND; printf "\n";															fi
  $SLEEP_BIN 1
  return $RETVAL
};

function MOUNT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Executing:\t"; CLR_TEXT; printf "%s\n" "$MOUNT_BIN $OPT_SWITCH $MOUNT_OPTS $NFS_EXPORT $BAK_MOUNT"; CN_TEXT;								fi
  $MOUNT_BIN $OPT_SWITCH $MOUNT_OPTS "$NFS_EXPORT" "$BAK_MOUNT" 2>/dev/null 3>/dev/null
  export RETVAL=$?
  export COMMAND="$MOUNT_BIN Return Value: $RETVAL"
  $SLEEP_BIN 1
  if [ $BOL_QUIET -eq $FALSE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Results:\t"; LOG_RESULTS; unset COMMAND; printf "\n";															fi
  if [ $($MOUNT_BIN|$GREP_BIN $BAK_MOUNT|$WC_BIN -l) -lt 1 ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "%s:\t" $BAK_MOUNT; CLR_TEXT; printf "not mounted!\n"; CN_TEXT; exit $FAILURE;								fi
  CHECK_BAK_PATH
  return $RETVAL
};

# Check for command line arguments
for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --version)		if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi;	SHOW_HEADER; exit $SUCCESS;;
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
    --no-threshold)	export BOL_CHECK_PROC=$FALSE;;
    -d | --debug)	export BOL_DEBUG=$TRUE;;
    -v | --verbose)	export BOL_QUIET=$FALSE;		export BOL_VERBOSE=$TRUE;		export VERBOSE="-v";;
    -q | --quiet)	export BOL_QUIET=$TRUE;			export BOL_VERBOSE=$FALSE;		export VERBOSE="";;
    -t | --test)	export TAR_BIN=$TRUE_BIN;;
    --bw)		export BOL_COLOR=$FALSE;;
    --color)		export BOL_COLOR=$TRUE;;
    --force-color)	export BOL_FORCE_COLOR=$TRUE;		export BOL_COLOR=$TRUE;;
  esac
done

# Define Variables that are not already defined																								##
# Either as environment variables or set by command line options defined above																				##
if [ $BOL_COLOR						    -eq $TRUE ]; then INIT_COLOR_SHORTHAND;																	fi
if [ $BOL_QUIET			                           -eq $FALSE ]; then SHOW_HEADER; printf "\n";                                                                                                                                 fi
if [ ${#CFG_FILE}						-eq 0 ]; then export CFG_FILE="/etc/sysbak.cfg";															fi
if [ -f $CFG_FILE						      ]; then . $CFG_FILE; printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Loaded:\t"; CLG_TEXT; printf "Config File: "; CY_TEXT; printf "%s\n\n" "$CFG_FILE";	fi
if [ ${#BOL_MNT}						-eq 0 ]; then declare -i BOL_MNT=$TRUE;																	fi
if [ ${#BOL_BAK}						-eq 0 ]; then declare -i BOL_BAK=$TRUE;																	fi
if [ ${#BOL_QUIET}       	        		        -eq 0 ]; then declare -i BOL_QUIET=$FALSE;                                                              				                		fi
if [ ${#BOL_VERBOSE}			            	   	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;     				                                                                        		fi
if [ ${#NETBIOS_HOSTNAME}					-eq 0 ]; then export NETBIOS_HOSTNAME=$($HOSTNAME_BIN --short);														fi
if [ ${#FQDN_HOSTNAME}						-eq 0 ]; then export FQDN_HOSTNAME=$($HOSTNAME_BIN --fqdn);														fi
if [ ${#KERNEL}							-eq 0 ]; then export KERNEL=$(uname -r);																fi
if [ ${#BAK_EXT}						-eq 0 ]; then export BAK_EXT="tar$XZ";																	fi
if [ ${#BAK_MOUNT}						-eq 0 ]; then export BAK_MOUNT="/mnt/bak";																fi
if [ ${#NFS_SERVER}						-eq 0 ]; then export NFS_SERVER="lxc.gigaware.lan";															fi
if [ ${#NFS_EXPORT}						-eq 0 ]; then export NFS_EXPORT="$NFS_SERVER:/opt/bak";															fi
if [ ${#DOW}							-eq 0 ]; then export DOW=$(date +%A);																	fi
if [ ${#MOUNT_OPTS} 	-eq 0 ] 	&& [ $BOL_WRT	-ne	$TRUE ]; then export MOUNT_OPTS="defaults";	else export MOUNT_OPTS="";												fi
if [ ${#OPT_SWITCH} 	-eq 0 ]		&& [ $BOL_WRT	-ne	$TRUE ]; then export OPT_SWITCH="-o";		else export OPT_SWITCH="";												fi
if [ ${#BACKUP_PATH}						-eq 0 ]; then export BACKUP_PATH="$BAK_MOUNT/$FQDN_HOSTNAME/$DOW";													fi
if [ ${#PROC_THRESHOLD}						-eq 0 ]; then export PROC_THRESHOLD=2;																	fi
if [ $PROC_COUNT -gt $PROC_THRESHOLD ] && [ $BOL_CHECK_PROC -eq $TRUE ]; then printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Proc Max:\t"; CLG_TEXT; printf "Threshold: "; CY_TEXT; printf "(%s) " $PROC_THRESHOLD;		##
										    CLR_TEXT; printf "Exceded ";  CY_TEXT; printf "(%s) " $PROC_COUNT; CLR_TEXT; printf "Exiting\n"; CN_TEXT; exit $SUCCESS;				fi
if [ ! -d "$BAK_MOUNT"  			                      ]; then mkdir -p "$BAK_MOUNT";   printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Made Dir:\t"; CY_TEXT; printf "%s\n" " $BAK_MOUNT";  CN_TEXT;		fi
if [ $BOL_MNT						    -eq $TRUE ]; then MOUNT;																			fi
if [ ! -d "$BACKUP_PATH"           	    		              ]; then mkdir -p "$BACKUP_PATH"; printf "%s: " "$(SHOW_DATE_TIME)"; CLB_TEXT; printf "Made Dir:\t"; CY_TEXT; printf "%s\n" "$BACKUP_PATH"; CN_TEXT;		fi
if [ ${#BAK_TARGET_ARRAY[@]}					-eq 0 ]; then declare -ag BAK_TARGET_ARRAY=( "$BACKUP_PATH/boot.$KERNEL.$BAK_EXT" "$BACKUP_PATH/etc.$BAK_EXT" "$BACKUP_PATH/lib.modules.$KERNEL.$BAK_EXT" "$BACKUP_PATH/lib.systemd.$BAK_EXT" "$BACKUP_PATH/var.$BAK_EXT" "$BACKUP_PATH/usr.local.$BAK_EXT" );		fi
if [ ${#BAK_SOURCE_PATH[@]}					-eq 0 ]; then declare -ag BAK_SOURCE_PATH=( "/boot" "/etc" "/lib/modules/$KERNEL" "/lib/systemd" "/var" "/usr/local" );							fi
if [ ${#BAK_SOURCE_ARRAY[@]}					-eq 0 ]; then																				##
  case ${FQDN_HOSTNAME,,} in																										##
    sql.gigaware.lan | ubuntuserver.gigaware.lan | centos.gigaware.lan | openwrt.x86) # Linux Container Virtual Machines Share the same '/usr/local' so we don't need multiple backups of the same filesystem				##
	declare -ag BAK_SOURCE_ARRAY=( "$(SOURCE_PREFIX='/boot'; for SOURCE_FILE in efi extlinux flask grub grub2 initramfs-$KERNEL.img loafFINder System.map-$KERNEL config-$KERNEL vmlinuz-$KERNEL xen.gz xen-4.{10,11,12,13,14,15}.gz; do VERIFY_SOURCE; done)" '.' '.' '.'	\
	"$(SOURCE_PREFIX='/var'; for SOURCE_FILE in named www lib/httpd lib/apache2 lib/ipa-client lib/pki lib/tftpboot lib/tomcat lib/tomcat8 lib/tomcat9; do VERIFY_SOURCE; done)" );							##
	;;																												##
    *)											# Any other hostname will include the '/usr/local' filesystem											##
	declare -ag BAK_SOURCE_ARRAY=( "$(SOURCE_PREFIX='/boot'; for SOURCE_FILE in efi extlinux flask grub grub2 initramfs-$KERNEL.img loafFINder System.map-$KERNEL config-$KERNEL vmlinuz-$KERNEL xen.gz xen-4.{10,11,12,13,14,15}.gz; do VERIFY_SOURCE; done)" '.' '.' '.'	\
	"$(SOURCE_PREFIX='/var'; for SOURCE_FILE in named www lib/httpd lib/apache2 lib/ipa-client lib/pki lib/tftpboot lib/tomcat lib/tomcat8 lib/tomcat9; do VERIFY_SOURCE; done)" \							##
	"$(SOURCE_PREFIX='/usr/local'; for SOURCE_FILE in bin etc include lib lib64 libexec samba scripts sbin; do VERIFY_SOURCE; done)" );												##
	;;																												##
  esac																													##
fi																													##
if [ $BOL_BAK		 		    		    -eq $TRUE ]; then BACKUP; FINAL_RETVAL=$?;																	fi
if [ $BOL_MNT           	            		    -eq $TRUE ]; then UNMOUNT;                                                                  				                                		fi

# All Done
exit $FINAL_RETVAL
