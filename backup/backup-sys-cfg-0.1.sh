#! /bin/bash
## VERRY Simple Script to Backup System Files

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


if [ $(id -u) -ne 0 ]; then
	echo "Must be ran as root!"
	exit 1
fi

export VERSION=0.1

# Define Global TRUE/FALSE and SUCCESS/FAILURE
declare -ig TRUE=1
declare -ig FALSE=0
declare -ig SUCCESS=0
declare -ig FAILURE=1

export RUN_CMD="$(basename $0)"
export RUN_PREFIX="/usr/local/sbin"
export LN_PREFIX="../scripts/backup"
export SCRIPT_PREFIX="/usr/local/scripts/backup"
export PACKAGE_SCRIPT="MakePackageLists.sh"

# Define CRON File Strings
export CRON_PREFIX="/etc/cron.d"
export CRON_FILE="$CRON_PREFIX/${RUN_CMD%.*}_job"

# Define Booleans
declare -ig BOL_Create_Symlink=$FALSE
declare -ig BOL_Create_Cron_Job=$FALSE
declare -ig BOL_Remove_Cron_Job=$FALSE
declare -ig BOL_Remove_Symlink=$FALSE
declare -ig BOL_Copy_Uncompresses=$FALSE
declare -ig BOL_Show_Random_Times=$FALSE
declare -ig BOL_Make_Package_List=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_TAR_BACKUP=$TRUE
declare -ig BOL_RUN=$TRUE
declare -ig BOL_HELP=$FALSE

# Define Random Time Variables
declare -ig RAND_MINUTE=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)
declare -ig RAND_HOUR=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)
declare -ig RAND_DOW=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)

# Generate A Random Minute/Hour/DOW
while [ $((RAND_MINUTE)) -gt 59 ]; do _RAND_MINUTE=$(printf "%f" $(/bin/date +%N)|cut --byte=1,3); RAND_MINUTE=$((_RAND_MINUTE)); done
while [ $((RAND_HOUR)) -gt 23 ]; do _RAND_HOUR=$(printf "%f" $(/bin/date +%N)|cut --byte=1,4); RAND_HOUR=$((_RAND_HOUR)); done
while [ $((RAND_DOW)) -gt 6 ]; do _RAND_DOW=$(printf "%f" $(/bin/date +%N)|cut --byte=1); RAND_DOW=$((_RAND_DOW));  done

# Define dow (day of week) and hostname
export dow=$(date +%w)
export hostname=$(hostname -s)

# Define What to backup
export backup_files="/etc /boot /usr/local"

# Define Archive File Name
export archive_file="$dow-$hostname-cfg.tar.gz"

# Define Where to backup to.
export dest="/opt/bak/$hostname"
export uncompressed_dest="$dest/uncompressed"

# Define Misc. Integers
declare -ig VAR_UNKNOWN=0

# Set Misc. Strings
export VERBOSE=""
export BACKUP_OPT="-uR --preserve=all"

function PrintBOL()
{
   RETVAL=$SUCCESS
   if [ $BOL_TEMP -eq $FALSE ]; then
	printf "%-7s\n" "Disabled"
   elif [ $BOL_TEMP -eq $TRUE ]; then
	printf "%-7s\n" "Enabled"
   else
	RETVAL=$FAILURE
	printf "%-7s\n" "Unknown"
   fi
   return $RETVAL
};

# Check To Se If $RUN_PREFIX/$RUN_CMD Exists And Set BOL_Create_Symlink Accordingly
if [ ! -f $RUN_PREFIX/$RUN_CMD ]; then
  BOL_Create_Symlink=$TRUE
fi

# Check To Se If $CRON_FILE Exists And Set BOL_Create_Symlink Accordingly
if [ ! -f $CRON_FILE ]; then
  BOL_Create_Cron_Job=$TRUE
fi

# On Random Day Copy $backup_files to $uncompressed_dest
if [ $dow -eq $RAND_DOW ]; then
  BOL_Copy_Uncompresses=$TRUE
fi

function do_HELP()
{
   printf "%-15s %-8s %-3s %-16s\n\n" "$RUN_CMD" "Version: " "$VERSION" "HELP! Section!"
   printf "%-10s\t\t%-20s\n" "-h | --help" "Display This Message"
   printf "%-10s\t\t%-20s\n\n" "-v | --verbose" "Show Verbose Messages"
   printf "%-10s\t\t%-20s\n" "--create-cron" "Create $CRON_FILE"
   printf "%-10s\t\t%-20s\n" "--skip-cron" "Don't Create $CRON_FILE"
   printf "%-10s\t\t%-20s\n" "--Remove-cron" "Remove $CRON_FILE"
   printf "%-10s\t\t%-20s\n" "--create-link" "Create Symlink $RUN_PREFIX/$RUN_CMD to point to $LN_PREFIX/$RUN_CMD"
   printf "%-10s\t\t%-20s\n" "--skip-link" "Don't Create Symlink $RUN_PREFIX/$RUN_CMD to point to $LN_PREFIX/$RUN_CMD"
   printf "%-10s\t\t%-20s\n" "--remove-link" "Remove Symlink $RUN_PREFIX/$RUN_CMD"
   printf "%-10s\t\t%-20s\n" "--skip-tar" "Skip Running 'tar' Backup job"
   printf "%-10s\t\t%-20s\n" "--dont-skip-tar" "Do Not Skip Running 'tar' Backup job"
   printf "%-10s\t\t%-20s\n" "--skip-copy" "Skip Running 'cp' Backup job"
   printf "%-10s\t%-20s\n" "--dont-skip-copy" "Do Not Skip Running 'cp' Backup job"
   printf "%-10s\t\t%-20s\n" "--skip-package" "Skip Running $SCRIPT_PREFIX/$PACKAGE_SCRIPT"
   printf "%-10s\t%-20s\n" "--dont-skip-package" "Do Not Skip Running $SCRIPT_PREFIX/$PACKAGE_SCRIPT"
   printf "%-10s\t\t%-20s\n" "--skip-backup" "Skip running ANY/ALL Backup jobs"
   printf "%-10s\t\t%-20s\n\n" "--show-random" "Show Random Times Generated For $CRON_FILE"
   return $SUCCESS
};

function doVerboseHeader()
{
   printf "%-15s %-8s %-3s %-16s\n" "$RUN_CMD" "Version: " "$VERSION" "Verbose Header"
   printf "%-15s\t" "Create Cron Job:"; BOL_TEMP=$((BOL_Create_Cron_Job)); PrintBOL
   printf "%-15s\t" "Remove Cron Job:"; BOL_TEMP=$((BOL_Remove_Cron_Job)); PrintBOL
   printf "%-15s\t\t" "Create Symlink:"; BOL_TEMP=$((BOL_Create_Symlink)); PrintBOL
   printf "%-15s\t\t" "Remove Symlink:"; BOL_TEMP=$((BOL_Remove_Symlink)); PrintBOL
   printf "%-15s\t" "MakePackageList:"; BOL_TEMP=$((BOL_Make_Package_List)); PrintBOL
   printf "%-15s\t\t" "TAR Backup:"; BOL_TEMP=$((BOL_TAR_BACKUP)); PrintBOL
   printf "%-15s\t\t" "Copy Backup:"; BOL_TEMP=$((BOL_Copy_Uncompresses)); PrintBOL
   printf "%-15s\t\t" "Run Backup:"; BOL_TEMP=$((BOL_RUN)); PrintBOL
   printf "%-15s\t\t" "Show Random:"; BOL_TEMP=$((BOL_Show_Random_Times)); PrintBOL
   printf "\n"
   return $SUCCESS
};

# Check To See If There Are Any Command Line Options Present
for i in "$@"
do
case $i in
'--create-cron')
	export BOL_Create_Cron_Job=$TRUE
	;;
'--skip-cron')
        export BOL_Create_Cron_Job=$FALSE
        ;;
'--remove-cron')
	export BOL_Remove_Cron_Job=$TRUE
	;;
'--create-link')
	export BOL_Create_Symlink=$TRUE
	;;
'--skip-link')
        export BOL_Create_Symlink=$FALSE
        ;;
'--remove-link')
	export BOL_Remove_Symlink=$TRUE
	;;
'--skip-tar')
	export BOL_TAR_BACKUP=$FALSE
	;;
'--dont-skip-tar')
        export BOL_TAR_BACKUP=$TRUE
        ;;
'--skip-copy')
	export BOL_Copy_Uncompresses=$FALSE
	;;
'--dont-skip-copy')
	export BOL_Copy_Uncompresses=$TRUE
	;;
'--skip-package')
	export BOL_Make_Package_List=$FALSE
	;;
'--dont-skip-package')
	export BOL_Make_Package_List=$TRUE
	;;
'--skip-backup')
	export BOL_RUN=$FALSE
	;;
'--show-random')
	export BOL_Show_Random_Times=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
  BOL_RUN=$FALSE
  do_HELP
  RETVAL=$FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
  BOL_RUN=$FALSE
  RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_VERBOSE -eq $TRUE ]; then
  doVerboseHeader
fi

if [ $BOL_Make_Package_List -eq $TRUE ]; then
  $SCRIPT_PREFIX/$PACKAGE_SCRIPT &
fi

if [ $BOL_Show_Random_Times -eq $TRUE ]; then
  printf "%-10s\t%-2d\n" "Random Hour:" $((RAND_HOUR))
  printf "%-10s\t%-2d\n" "Random Minute:" $((RAND_MINUTE))
  printf "%-10s\t%-2d\n\n" "Random DOW:" $((RAND_DOW))
fi

if [ $BOL_Remove_Cron_Job -eq $TRUE ]; then
  rm -v $CRON_FILE
fi

if [ $BOL_Remove_Symlink -eq $TRUE ]; then
  rm -v $RUN_PREFIX/$RUN_CMD
fi

# Create Symlink to $RUN_PREFIX/$RUN_CMD If It Does NOT Exist
if [ $BOL_Create_Symlink -eq $TRUE ]; then
  cd "$RUN_PREFIX"
  ln -fs $VERBOSE "$LN_PREFIX/$RUN_CMD"
fi

# Create A CRON Job If It Does NOT Exist
if [ $BOL_Create_Cron_Job -eq $TRUE ]; then
  echo "## Cron File To Run $RUN_CMD Version $VERSION Daily" >$CRON_FILE
  echo "" >>$CRON_FILE
  echo "SHELL=/bin/sh" >>$CRON_FILE
  echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >>$CRON_FILE
  echo "" >>$CRON_FILE
  echo "$RAND_MINUTE $RAND_HOUR * * * root $RUN_PREFIX/$RUN_CMD --skip-package --dont-skip-copy --dont-skip-tar --skip-cron" >>$CRON_FILE
  echo "" >>$CRON_FILE
fi

if [ $BOL_RUN -eq $TRUE ]; then
  BACKUP_OPT="$BACKUP_OPT $VERBOSE"
  # Create Destinations if they do NOT exist
  if [ ! -d $uncompressed_dest ]; then
	if [ $BOL_VERBOSE -eq $TRUE ]; then
	   echo "Creating Directory $uncompressed_dest"
	fi
	mkdir -p $uncompressed_dest
  fi

  # Backup Files Using 'tar'
  if [ $BOL_TAR_BACKUP -eq $TRUE ]; then
     TAR_OPTS="czf"
     if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Creating: $dest/$archive_file"; TAR_OPTS="czfv"; fi
     tar $TAR_OPTS $dest/$archive_file $backup_files
  fi

  # Backup Files Using 'cp'
  if [ $BOL_Copy_Uncompresses -eq $TRUE ]; then
	if [ $BOL_VERBOSE -eq $TRUE ]; then
	   echo -e "Backing Up: $backup_files To: $uncompressed_dest"
	fi
	cp $BACKUP_OPT $backup_files $uncompressed_dest
	RETVAL=$?
  fi
else
  if [ $BOL_VERBOSE -eq $TRUE ]; then
	echo "Skipping Backup Jobs!"
  fi
  RETVAL=$FAILURE
fi

exit $RETVAL
