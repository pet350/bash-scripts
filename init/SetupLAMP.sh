#!/bin/bash
# Script to Initialize MySQL RAM Drive, Apache Web Server and ZoneMinder
# By: Peter Talbott

# Source LSB function library.
source /lib/lsb/init-functions

# Current Version
VERSION=0.3

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

# Define Boolean Variables and set Default Values
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_INIT_MYSQL=$FALSE
declare -ig BOL_INIT_APACHE=$TRUE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_CLEAR_RAMDRIVE=$TRUE

# Define String Variables
export RUN_CMD="$(basename $0)"
export BIN_PREFIX="/bin"
export RM_BIN="$BIN_PREFIX/rm"
export CP_BIN="$BIN_PREFIX/cp"
export CHOWN_BIN="$BIN_PREFIX/chown"
export CHMOD_BIN="$BIN_PREFIX/chmod"
export MYSQL_CF_PATH="/var/lib/mysql.local"
export MYSQL_RAM_PATH="/var/lib/mysql"
export MYSQL_USER="mysql"
export MYSQL_GROUP="mysql"
export MYSQL_SERVICE="mysql"
export APACHE_CF_PATH="/usr/share/zoneminder/www.local"
export APACHE_RAM_PATH="/usr/share/zoneminder/www"
export APACHE_SERVICE="apache2"
export APACHE_USER="www-data"
export APACHE_GROUP="www-data"

# Define Intiger Variables
declare -ig VAR_UNKNOWN=0
declare -ig VAR_SLEEP=1

# Check That ROOT Is Not Trying To Run This Script
if [ $(id -u) -ne 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nError: Must be ran as ROOT user!"
  exit $FAILURE
fi

# Check If Any Command Line Options Are Present
if [ $# -eq 0 ]; then
  echo -e "$RUN_CMD Version $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
  exit $FAILURE
fi

function DISPLAY_BOOLEAN()
{
  if [ $BOL_TEMP -eq $TRUE ]; then printf "%-5s\n" "True";
  else printf "%-5s\n" "False"; fi
  return $SUCCESS
};

function DISPLAY_CONFIG()
{
  printf "$RUN_CMD Version $VERSION\nConfiguration!\n\n"
  export BOL_TEMP=$((BOL_INIT_MYSQL))
  printf "%-15s\t\t" "Initialize MYSQL:"
  DISPLAY_BOOLEAN
  export BOL_TEMP=$((BOL_INIT_APACHE))
  printf "%-15s\t\t" "Initialize Apache:"
  DISPLAY_BOOLEAN

  echo -e ""
  return $SUCCESS
};

function Check_MySQL_SERVICE()
{
  declare -i RETVAL=$FAILURE
  ps axho comm| grep $MYSQL_SERVICE > /dev/null
  RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
      echo -e "MySQL Service Is Running!"
    else
      echo -e "MySQL Service Is NOT Running!"
    fi
  fi
  return $RETVAL
};

function Check_Apache_SERVICE()
{
  declare -i RETVAL=$FAILURE
  ps axho comm| grep $APACHE_SERVICE > /dev/null
  RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
      echo -e "Apache Service Is Running!"
    else
      echo -e "Apache Service Is NOT Running!"
    fi
  fi
  return $RETVAL
};


# Function To Copy and Set Permissions of MySQL RAM Drive
function do_SETUP_MySQL_RAMDRIVE()
{
  declare -i VAR_MYSQL_FILES=$(ls -1 $MYSQL_RAM_PATH | wc -l)
  if [ $BOL_CLEAR_RAMDRIVE -eq $FALSE ]; then VAR_MYSQL_FILES=-1; fi
  if [ $((VAR_MYSQL_FILES)) -gt 0 ]; then $RM_BIN -R $MYSQL_RAM_PATH/*; fi
  $CP_BIN -uR $MYSQL_CF_PATH/* $MYSQL_RAM_PATH --preserve=all
  $CHOWN_BIN $MYSQL_USER:$MYSQL_GROUP $MYSQL_RAM_PATH -R
  $CHMOD_BIN o-rwx $MYSQL_RAM_PATH -R
  $CHMOD_BIN o-t $MYSQL_RAM_PATH -R
  $CHMOD_BIN g-rwx $MYSQL_RAM_PATH -R
  return $SUCCESS
};

function do_SETUP_Apache_RAMDRIVE()
{
  declare -i VAR_APACHE_FILES=$(ls -1 $APACHE_RAM_PATH | wc -l)
  if [ $BOL_CLEAR_RAMDRIVE -eq $FALSE ]; then VAR_APACHE_FILES=-1; fi
  if [ $((VAR_APACHE_FILES)) -gt 0 ]; then $RM_BIN -R $APACHE_RAM_PATH/*; fi
  $CP_BIN -uR $APACHE_CF_PATH/* $APACHE_RAM_PATH --preserve=all
  $CHOWN_BIN $APACHE_USER:$APACHE_GROUP $APACHE_RAM_PATH -R
  $CHMOD_BIN o-rwx $APACHE_RAM_PATH -R
  $CHMOD_BIN o-t $APACHE_RAM_PATH -R
  $CHMOD_BIN g-w $APACHE_RAM_PATH -R
  return $SUCCESS
};


function do_STOP()
{
  declare -i VAR_MYSQL_FILES=$(ls -1 $MYSQL_RAM_PATH | wc -l)
  declare -i RETVAL=$FAILURE

  if [ $BOL_INIT_MYSQL -eq $TRUE ]; then
    Check_MySQL_SERVICE
    if [ $? -eq $SUCCESS ]; then /etc/init.d/mysql stop; fi
    $CP_BIN -uR $MYSQL_RAM_PATH/* $MYSQL_CF_PATH --preserve=all
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "VAR_MYSQL_FILES: $VAR_MYSQL_FILES"; fi
    if [ $BOL_CLEAR_RAMDRIVE -eq $FALSE ]; then VAR_MYSQL_FILES=-1; fi
    if [ $((VAR_MYSQL_FILES)) -gt 1 ]; then $RM_BIN -R $MYSQL_RAM_PATH/*; fi
  fi

  if [ $BOL_INIT_APACHE -eq $TRUE ]; then
    /etc/init.d/apache2 stop
    sleep $VAR_SLEEP
  fi

  /etc/init.d/zoneminder stop
  RETVAL=$?
  return $RETVAL
};

function do_START()
{
  declare -i RETVAL=$FAILURE
  # Check to see if systemd.tempfiles are up and running
  systemctl status systemd-tmpfiles-setup.service >/dev/null
  if [ $? -ne $SUCCESS ]; then systemctl start systemd-tmpfiles-setup.service >/dev/null; fi
  sleep $VAR_SLEEP

  if [ $BOL_INIT_MYSQL -eq $TRUE ]; then
    # Setup and Start MySQL
    Check_MySQL_SERVICE
    if [ $? -eq $SUCCESS ]; then /etc/init.d/mysql stop; fi
    do_SETUP_MySQL_RAMDRIVE
    /etc/init.d/mysql start
    if [ $? -ne $SUCCESS ]; then exit $FAILURE; fi
  fi

  if [ $BOL_INIT_APACHE -eq $TRUE ]; then
    # Setup and Start Apache
    Check_Apache_SERVICE
    if [ $? -eq $SUCCESS ]; then /etc/init.d/apache2 stop; fi
    do_SETUP_Apache_RAMDRIVE
    /etc/init.d/apache2 start
    if [ $? -ne $SUCCESS ]; then exit $FAILURE; fi
  fi

  sleep $VAR_SLEEP
  /etc/init.d/zoneminder start
  RETVAL=$?

  return $RETVAL
};


function do_HELP()
{
  printf "$RUN_CMD Version $VERSION\nHelp Section!\n\n"
  printf "%-15s\t\t%-25s\n" "-h  or --help" "Disply This Help Message"
  printf "%-15s\t%-25s\n\n" "-v  or --verbose" "Be Verbose"
  printf "%-15s\t\t%-25s\n" "--with-mysql" "Initialize Local MYSQL Server"
  printf "%-15s\t\t%-25s\n" "--without-mysql" "Do Not Initialize Local MYSQL Server"
  printf "%-15s\t\t%-25s\n" "--with-apache" "Initialize Local Apache Server"
  printf "%-15s\t%-25s\n\n" "--without-apache" "Do Not Initialize Local Apache Server"
  printf "%-15s\t\t%-25s\n" "start" "Initialize LAMP (Apache MySQL and ZoneMinder)"
  printf "%-15s\t\t%-25s\n" "stop" "Shutdown LAMP"
  printf "%-15s\t\t%-25s\n" "restart" "Effective stop then start"
  echo -e ""
  return $SUCCESS
};


for i in "$@"
do
case $i in
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
'--with-mysql')
	export BOL_INIT_MYSQL=$TRUE
	;;
'--without-mysql')
	export BOL_INIT_MYSQL=$FALSE
	;;
'--with-apache')
        export BOL_INIT_APACHE=$TRUE
        ;;
'--without-apache')
        export BOL_INIT_APACHE=$FALSE
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
        echo -e "$RUN_CMD Version $VERSION\nUnknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        do_HELP
        exit $FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
        exit $VAR_UNKNOWN
fi

if [ $BOL_VERBOSE -eq $TRUE ]; then DISPLAY_CONFIG; fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"
        do_STOP
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
        do_START
        RETVAL=$?
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

exit $RETVAL
## Done!



