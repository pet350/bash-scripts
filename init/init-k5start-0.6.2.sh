#! /bin/bash
### BEGIN INIT INFO
# Provides:          Kerberos5-Tokens
# Required-Start:    $network $remote_fs $syslog $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize Kerberos 5 Token Upon Login
# Description:       Initialize Kerberos 5 Token Upon Login
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-06-01, 2019-10-19,10-20

# Source function library.
source /lib/lsb/init-functions

if [ -f /usr/local/scripts/include/*.sh ]; then
  for INCLUDE_FILE in $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
fi

# Define Initial Prefix String Variables
export __HOME=~
export __RUN_PREFIX="/usr/bin"
export __TEMP_PREFIX="/tmp"
export __PID_PREFIX="$__TEMP_PREFIX"
export __KEYTAB_PREFIX="$__HOME/.config"

# Define Initial File Name String Variavles
export __SCRIPT_NAME="k5start"
export __ALT_BIN="$__RUN_PREFIX/kinit"
export __LDAP_BIN="$__RUN_PREFIX/ldapsearch"
export __CONVERT_BIN="$__RUN_PREFIX/convert"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.$(whoami).pid"
export __CHILD_PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.child.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __KEYTAB="$__KEYTAB_PREFIX/$(whoami).keytab"
export __ADMIN="admin@GIGAWARE.LAN"

# Define Initial Default Options
export __DAEMON_OPTIONS=""
export __KEYTAB_OPTION=""
export __PID_FILE_OPTION=""
export __LOG_OPTIONS="-L"
export __BASE_DN="cn=users,cn=accounts,dc=gigaware,dc=lan"
export __UID_OPT="uid=$(whoami)"

# Define Alt Default Options
export __ALT_KEYTAB_OPTION="-k -t $__KEYTAB"
export __ALT_PRINCIPAL="-p $(whoami)@GIGAWARE.LAN"

# Source LSB function library.
source /lib/lsb/init-functions

export VERBOSE="-q"
export RUN_CMD="$(basename $0)"
export _VER=0.6.2

# Define KEYTAB Source Location String Variables
export KT_SERVER="lxc.gigaware.lan"
export KT_SOURCE_PATH="/nfs/$KT_SERVER/opt/keys"
export KT_SOURCE_FILE="$KT_SOURCE_PATH/$(whoami).keytab"

# Define TRUE/FALSE Variables
if [ ${#TRUE}		-eq 0 ];	then	declare -ig TRUE=1;		fi
if [ ${#FALSE}		-eq 0 ];	then	declare -ig FALSE=0;		fi

# Define SUCCESS/FAILURE Variables
if [ ${#BOL_SUCCESS}	-eq 0 ];	then	declare -ig SUCCESS=0;		fi
if [ ${#BOL_FAIL}	-eq 0 ];	then	declare -ig FAIL=1;		fi

# Define BOOLEAN Variables
if [ ${#BOOLEAN} 	-eq 0 ];	then	declare -ig BOOLEAN=$FALSE;	fi
if [ ${#BOL_HELP}	-eq 0 ];	then	declare -ig BOL_HELP=$FALSE;	fi
if [ ${#BOL_START}	-eq 0 ];	then	declare -ig BOL_START=$FALSE;	fi
if [ ${#BOL_STOP}	-eq 0 ];	then	declare -ig BOL_STOP=$FALSE;	fi
if [ ${#BOL_VERBOSE}	-eq 0 ];	then	declare -ig BOL_VERBOSE=$FALSE;	fi
if [ ${#BOL_DAEMON}	-eq 0 ];	then	declare -ig BOL_DAEMON=$FALSE;	fi
if [ ${#BOL_QUIET}	-eq 0 ];	then	declare -ig BOL_QUIET=$FALSE;	fi
if [ ${#BOL_K5START}	-eq 0 ];	then	declare -ig BOL_K5START=$TRUE;	fi
if [ ${#BOL_ALT}	-eq 0 ];	then	declare -ig BOL_ALT=$FALSE;	fi
if [ ${#BOL_INFO}	-eq 0 ];	then	declare -ig BOL_INFO=$FALSE;	fi

# Define Integer Variables
declare -ig RETVAL=$FAIL
declare -ig INTERVAL=30

# Check to see If there are any command line options
if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

function PRINT_INFO()
{
  # Print String Data
  PRINT_DATE_TIME; printf "%bVersion: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$_VER"		$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bScript Name: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__SCRIPT_NAME"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bUser ID: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__UID_OPT"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bLDAP Base DN: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__BASE_DN"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bPID File: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__PID_FILE"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bKeytab File: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__KEYTAB"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bKeytab Source: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$KT_SOURCE_FILE"   $COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bInitial Binary: %b%s %b\n"		$COLOR_LT_BLUE $COLOR_YELLOW "$__EXEC_FILE"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bInitial Options: %b%s %b\n"	$COLOR_LT_BLUE $COLOR_YELLOW "$__OPTIONS"   	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bAlternate Binary: %b%s %b\n"	$COLOR_LT_BLUE $COLOR_YELLOW "$__ALT_BIN"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bAlternate Options: %b%s %b\n"	$COLOR_LT_BLUE $COLOR_YELLOW "$__ALT_OPTIONS"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bLDAP Search Binary: %b%s %b\n" 	$COLOR_LT_BLUE $COLOR_YELLOW "$__LDAP_BIN"	$COLOR_NORMAL
  PRINT_DATE_TIME; printf "%bImage Convert Binary: %b%s %b\n" 	$COLOR_LT_BLUE $COLOR_YELLOW "$__CONVERT_BIN"	$COLOR_NORMAL

  # Print Booleans
  PRINT_DATE_TIME; printf "%bBoolean Start: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_START; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean Stop: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_STOP; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean Verbose: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_VERBOSE; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean Daemon: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_DAEMON; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean Quiet: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_QUIET; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean K5Start: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_K5START; PRINT_BOOLEAN
  PRINT_DATE_TIME; printf "%bBoolean Alternate: %b"   $COLOR_LT_BLUE $COLOR_YELLOW; export BOOLEAN=$BOL_ALT; PRINT_BOOLEAN
  return $SUCCESS
};

# Print Date and Time to Logfile
function PRINT_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function PRINT_BOOLEAN()
{
  if [ $BOL_QUIET -eq $FALSE ]; then
    if [ $BOOLEAN -eq $TRUE ]; then
        printf "%b" $COLOR_GREEN; echo -e "Yes!"; printf "%b" $COLOR_NORMAL
    else
        printf "%b" $COLOR_RED; echo -e "No!"; printf "%b" $COLOR_NORMAL
    fi
  fi
  return $BOOLEAN
};


# Function to Report the Outcome of Another Process
function REPORT_STATUS()
{
  if [ $BOL_QUIET -eq $FALSE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
        printf "%b" $COLOR_GREEN; log_success_msg "Success!"; printf "%b" $COLOR_NORMAL
    else
        printf "%b" $COLOR_RED; log_failure_msg "Failure!"; printf "%b" $COLOR_NORMAL
    fi
  fi
  return $RETVAL
};

# Attempt to obtain a Keytab File if one doesn't exist
if [ ! -f $__KEYTAB ]; then
  cp --preserve=all $KT_SOURCE_FILE $__KEYTAB_PREFIX >/dev/null 2>/dev/null
else
  diff $KT_SOURCE_FILE $__KEYTAB >/dev/null 2>/dev/null
  if [ $? -ne $SUCCESS ]; then cp --preserve=all $KT_SOURCE_FILE $__KEYTAB_PREFIX >/dev/null 2>/dev/null; fi
fi

# Changed to run Alt if k5start doesn't exist
if [ ! -f $__EXEC_FILE ]; then
  export BOL_ALT=$TRUE
  export BOL_K5START=$FALSE
fi

function GET_LDAP_JPEG()
{
  declare -i FUNCTION_RETURN=$FAILURE
  declare -i BOL_FOUND_JPG=$FALSE

  SEARCH_OPTIONS="-LLL -b $__BASE_DN $__UID_OPT jpegPhoto -t $__TEMP_PREFIX"
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    PRINT_DATE_TIME
    printf "%bExecuting: %b%s" $COLOR_LT_BLUE $COLOR_YELLOW $__LDAP_BIN
    printf " %s %b \n" "$SEARCH_OPTIONS" $COLOR_NORMAL
  fi

  DATA=$($__LDAP_BIN $SEARCH_OPTIONS 2>/dev/null)
  for TEMP in $DATA; do
    if [ ${TEMP:0:8} == 'file:///' ]; then
	TEMP_FILENAME="${TEMP#*/}"
	export FILENAME="${TEMP_FILENAME#*/}"
	export AVATAR_FILE="$__HOME/.face"
	export AVATAR_FILE_JPG="$__HOME/.face.jpg"
	export AVATAR_FILE_PNG="$__HOME/.face.png"
	export AVATAR_FILE_TMP="$__HOME/.face.tmp"
	export AVATAR_FILE_ICON="$__HOME/.face.icon"
	export BOL_FOUND_JPG=$TRUE
	export FUNCTION_RETURN=$SUCCESS

	if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME
	  printf "%bFound: %bImbeded JPEG in LDAP Account! %b\n" $COLOR_LT_BLUE $COLOR_YELLOW $COLOR_NORMAL
	  PRINT_DATE_TIME
	  printf "%bSaved: %bBinary file: %s %b" $COLOR_LT_BLUE $COLOR_YELLOW $FILENAME $COLOR_NORMAL
	  RETVAL=$SUCCESS
	  REPORT_STATUS
	fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
          PRINT_DATE_TIME
          printf "%bExecuting: %bmv %s" $COLOR_LT_BLUE $COLOR_YELLOW $FILENAME
	  printf " %s " $AVATAR_FILE_TMP
	fi
	mv $FILENAME $AVATAR_FILE_TMP 2>/dev/null
	RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
	if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME; printf "%bExecuting: %b%s -geometry 256x256! %s %s%b " $COLOR_LT_BLUE $COLOR_YELLOW $__CONVERT_BIN $AVATAR_FILE_TMP $AVATAR_FILE_PNG
	fi
	$__CONVERT_BIN -geometry 256x256! $AVATAR_FILE_TMP $AVATAR_FILE_PNG  >/dev/null 2>/dev/null; printf "%b" $COLOR_NORMAL
	RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
	if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

        if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME
	  printf "%bExecuting: %b%s -geometry 96x96! %s" $COLOR_LT_BLUE $COLOR_YELLOW $__CONVERT_BIN $AVATAR_FILE_TMP
	  printf " %s " $AVATAR_FILE_JPG
	fi
        $__CONVERT_BIN -geometry 96x96! $AVATAR_FILE_TMP $AVATAR_FILE_JPG >/dev/null 2>/dev/null
	RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
	if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME
	  printf "%bExecuting: %bmv %s" $COLOR_LT_BLUE $COLOR_YELLOW $AVATAR_FILE_PNG
	  printf " %s " $AVATAR_FILE_ICON
	fi
	mv $AVATAR_FILE_PNG $AVATAR_FILE_ICON >/dev/null 2>/dev/null
	RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
        if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME
	  printf "%bExecuting: %bmv %s" $COLOR_LT_BLUE $COLOR_YELLOW $AVATAR_FILE_JPG
	  printf " %s " $AVATAR_FILE
	fi
        mv $AVATAR_FILE_JPG $AVATAR_FILE >/dev/null 2>/dev/null
        RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
        if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
	  PRINT_DATE_TIME
	  printf "%bExecuting: %bchown %s " $COLOR_LT_BLUE $COLOR_YELLOW "$(whoami):domain_users"
	  printf "%s %s " $AVATAR_FILE $AVATAR_FILE_ICON
	fi
	chown $(whoami):domain_users $AVATAR_FILE $AVATAR_FILE_ICON >/dev/null 2>/dev/null
        RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
        if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

	if [ $BOL_VERBOSE -eq $TRUE ]; then
          PRINT_DATE_TIME
          printf "%bExecuting: %bchmod 0644 %s" $COLOR_LT_BLUE $COLOR_YELLOW $AVATAR_FILE
	  printf " %s " $AVATAR_FILE_ICON
	fi
	chmod 0644 $AVATAR_FILE $AVATAR_FILE_ICON >/dev/null 2>/dev/null
        RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
        if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi

        if [ $BOL_VERBOSE -eq $TRUE ]; then
          PRINT_DATE_TIME
          printf "%bExecuting: %brm -f %s "  $COLOR_LT_BLUE $COLOR_YELLOW $AVATAR_FILE_TMP
	fi
	rm -f $AVATAR_FILE_TMP >/dev/null 2>/dev/null
	RETVAL=$?
	FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
        if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi
    fi
  done
  if [ $BOL_FOUND_JPG -eq $FALSE ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then
	PRINT_DATE_TIME
        printf "%bNot Found: %bNo Imbeded JPEG in LDAP Account! %b\n" $COLOR_LT_BLUE $COLOR_YELLOW $COLOR_NORMAL
    fi
  fi
  return $FUNCTION_RETURN
};

# Parse Command Line Options
for i in "$@"; do
case $i in
'-a' | '--alt')
	export BOL_ALT=$TRUE
	export BOL_K5START=$FALSE
	;;
'-k' | '--k5start')
        export BOL_ALT=$FALSE
        export BOL_K5START=$TRUE
        ;;
'-b' | '--both')
        export BOL_ALT=$TRUE
        export BOL_K5START=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	export VERBOSE="-v"
	;;
'-q' | '--quiet')
	export BOL_QUIET=$TRUE
	export VERBOSE="-q"
	;;
'--debug')
	export BOL_DEBUG=$TRUE
	export BOL_VERBOSE=$TRUE
	export VERBOSE="-v"
	;;
'start')
	export BOL_STOP=$FALSE
        export BOL_START=$TRUE
        ;;
'stop')
        export BOL_STOP=$TRUE
	export BOL_START=$FALSE
        ;;
'restart')
        export BOL_STOP=$TRUE
        export BOL_START=$TRUE
        ;;
'-d' | '--daemon')
	export BOL_DAEMON=$TRUE
	;;
--renew=*)
	X="${i#*=}"
	export INTERVAL=$((X))
	;;
'--version')
	echo -e "$RUN_CMD: Version $_VER\nBy: Peter Talbott"
	exit $SUCCESS
	;;
'--info')
	export BOL_INFO=$TRUE
	;;
esac
done


if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

# If Both --verbose and --quiet are included command line options
# Set --quiet as Priority and ignore --verbose
if [ $BOL_QUIET -eq $TRUE ]; then
  export BOL_VERBOSE=$FALSE
  export VERBOSE="-q"
fi

# Check To See If Keytab File Exists
if [ ! -f $__KEYTAB ]; then
  if [ $BOL_QUIET -eq $FALSE ]; then
    log_failure_msg "Error! $__KEYTAB Does Not Exist!"
  fi
  exit $FAIL
fi

# Assemble Keytab and PID File Options
export __KEYTAB_OPTION="-f $__KEYTAB"
export __PID_FILE_OPTION="-p $__PID_FILE"

# Assemble Daemon Options IF --daemon is Enabled at the Command Line
if [ $BOL_DAEMON -eq $TRUE ]; then
  export __DAEMON_OPTIONS="-a -b -K $INTERVAL $__PID_FILE_OPTION"
fi

if [ $(id -u) -eq 0 ]; then
  export __DAEMON_OPTIONS="$__DAEMON_OPTIONS -u $__ADMIN"
  export __ALT_PRINCIPAL="-p $__ADMIN"
  export __UID_OPT="uid=admin"
else
  export __DAEMON_OPTIONS="$__DAEMON_OPTIONS -u $(whoami)@GIGAWARE.LAN"
  export __ALT_PRINCIPAL="-p $(whoami)@GIGAWARE.LAN"
  export __UID_OPT="uid=$(whoami)"
fi

# Assemble All 'k5start' Options
export __OPTIONS="$__KEYTAB_OPTION $__DAEMON_OPTIONS $__LOG_OPTIONS $VERBOSE"
export __ALT_OPTIONS="$__ALT_KEYTAB_OPTION $__ALT_PRINCIPAL"

if [ $BOL_INFO -eq $TRUE ]; then PRINT_INFO; fi

if [ $BOL_STOP -eq $TRUE ]; then
	declare -i RETVAL=$SUCCESS
        if [ $BOL_QUIET -eq $FALSE ]; then
		PRINT_DATE_TIME; printf "%b" $COLOR_LT_BLUE; log_daemon_msg "Stopping"
		printf " %b%s" $COLOR_YELLOW $RUN_CMD
		printf "%b " $COLOR_NORMAL
	fi
	if [ -f $__PID_FILE ]; then
	  for DATA in $(cat $__PID_FILE); do
	    while IFS= read LINE; do
	      INDEX=-1
		for WORD in $LINE; do
		  ((INDEX++))
		  if [ $INDEX -eq 0 ]; then PID_OWNER="$WORD"; fi
		  if [ $INDEX -eq 1 ]; then PROCESS=$((WORD)); fi
		  if [ $((DATA)) -eq $((PROCESS)) ]; then
		    if [ "$(whoami)" == "$PID_OWNER" ]; then
	    		if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "kill $DATA"; fi
	    		kill $DATA
	    		export RETVAL=$?
		    fi
		  fi
		done
	    done < <(ps -aux)
	  done
	fi
	killall $__SCRIPT_NAME  2>/dev/null
        sleep 1
	REPORT_STATUS
fi

if [ $BOL_START -eq $TRUE ]; then
	declare -i RETVAL=$SUCCESS
	if [ ! -f $__PID_FILE ]; then
	   if [ $BOL_QUIET -eq $FALSE ]; then
		PRINT_DATE_TIME; printf "%b" $COLOR_LT_BLUE; log_daemon_msg "Starting"
		printf " %b%s " $COLOR_YELLOW $RUN_CMD
		printf "%b \n" $COLOR_NORMAL
	   fi
	   if [ $BOL_ALT -eq $TRUE ]; then
		if [ $BOL_VERBOSE -eq $TRUE ]; then
		   PRINT_DATE_TIME
		   printf "%bExecuting: %b%s" $COLOR_LT_BLUE $COLOR_YELLOW $__ALT_BIN
		   printf " %s %b" "$__ALT_OPTIONS" $COLOR_NORMAL
		fi
		$__ALT_BIN $__ALT_OPTIONS >/dev/null 2>/dev/null
		export RETVAL=$?
		if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi
	   fi
	   if [ $BOL_K5START -eq $TRUE ]; then
	       if [ $BOL_VERBOSE -eq $TRUE ]; then
		  PRINT_DATE_TIME
		  printf "%bExecuting: %b%s" $COLOR_LT_BLUE $COLOR_YELLOW $__EXEC_FILE
		  printf " %s %b" "$__OPTIONS" $COLOR_NORMAL
		fi
	       $__EXEC_FILE $__OPTIONS >/dev/null 2>/dev/null
               export RETVAL=$?
	       if [ $BOL_VERBOSE -eq $TRUE ]; then REPORT_STATUS; fi
	   fi
	   if [ $RETVAL -eq $SUCCESS ]; then GET_LDAP_JPEG; fi
	else
	   if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; echo -e "Already Running!"; fi
	   export RETVAL=$SUCCESS
	fi
	if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf "%bFinished: " $COLOR_LT_BLUE; REPORT_STATUS; fi
fi

if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%b\n" $COLOR_NORMAL; fi
exit $RETVAL
