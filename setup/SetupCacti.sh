#!/bin/bash
## VERRY Simple Script to Install Cacti

if [ $(id -u) -ne 0 ]; then
	echo "Must be ran as root!"
	exit 1
fi

export VERSION=0.1
export RUN_CMD="$(basename $0)"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=1
declare -ig FAILURE=0

declare -ag SOURCE_ARRAY=('deb http://ftp.ro.debian.org/debian/ stretch main contrib non-free' 'deb-src http://ftp.ro.debian.org/debian/ stretch main' ' ' 'deb http://security.debian.org/debian-security stretch/updates main contrib non-free' 'deb-src http://security.debian.org/debian-security stretch/updates main');
declare -ag INSTALL_ARRAY=('wget' 'patch' 'unzip' 'zip' 'bash-completion' 'php' 'php-mysql' 'php-curl' 'php-net-socket' 'php-gd' 'php-intl' 'php-pear' 'php-imap' 'php-memcache' 'libapache2-mod-php' 'php-pspell' 'php-recode' 'php-tidy' 'php-xmlrpc' 'php-snmp' 'php-mbstring' 'php-gettext' 'php-gmp' 'php-json' 'php-xml' 'php-common' 'snmp' 'snmpd' 'snmp-mibs-downloader' 'rrdtool' 'dos2unix' 'automake' 'gzip' 'help2man' 'libmysqlclient-dev' 'libtool' 'm4' 'make' 'libsnmp-dev' 'libtool-bin');
declare -ag SNMP_CONF_FILE_ARRAY=('# As the snmp packages come without MIB files due to license reasons, loading' '# of MIBs is disabled by default. If you added the MIBs you can reenable' '# loading them by commenting out the following line.' '#mibs :');

declare -ig SOURCE_ARRAY_COUNT=${#SOURCE_ARRAY[@]}
declare -ig INSTALL_ARRAY_COUNT=${#INSTALL_ARRAY[@]}
declare -ig SNMP_CONF_FILE_ARRAY_COUNT=${#SNMP_CONF_FILE_ARRAY[@]}

export APT_BIN="/usr/bin/apt-get"
export INSTALL_PREFIX="/usr/local/install"
export APT_PREFIX="/etc/apt/sources.list.d"
export CACTI_SOURCE_FILE="$APT_PREFIX/cacti.list"
export SNMP_CONF_FILE="/etc/snmp/snmp.conf"

declare -ig BOL_CREATE_SOURCE_FILE=$TRUE
declare -ig BOL_DO_APT_INSTALL=$TRUE
declare -ig BOL_SNMP_CONF_FILE=$TRUE
declare -ig BOL_SETUP_CACTI_SPINE=$TRUE
declare -ig BOL_HELP=$FALSE

declare -ig VAR_UNKNOWN=-1
declare -ig RETVAL=$FAILURE

function CreateSourceFile()
{
  if [ -f $CACTI_SOURCE_FILE ]; then rm $CACTI_SOURCE_FILE; fi

  declare -i INDEX=-1
  while [ $((INDEX)) -lt $((SOURCE_ARRAY_COUNT-1)) ]; do
    ((INDEX++))
    echo -e "${SOURCE_ARRAY[$((INDEX))]}" >>$CACTI_SOURCE_FILE
  done
  return $SUCCESS
};

function DoAptInstall()
{
  $APT_BIN update
  $APT_BIN -y upgrade

  for TEMP in ${INSTALL_ARRAY[@]}; do
    $APT_BIN -y install $TEMP
  done
  return $SUCCESS
};

function CreateSnmpConfFile()
{
  if [ -f $SNMP_CONF_FILE ]; then rm $SNMP_CONF_FILE; fi

  declare -i INDEX=-1
  while [ $((INDEX)) -lt $((SNMP_CONF_FILE_ARRAY_COUNT-1)) ]; do
    ((INDEX++))
    echo -e "${SNMP_CONF_FILE_ARRAY[$((INDEX))]}" >>$SNMP_CONF_FILE
  done
  return $SUCCESS
};

function SetupCactiSpine()
{
  if [ ! -d $INSTALL_PREFIX ]; then mkdir -p $INSTALL_PREFIX; fi
  cd $INSTALL_PREFIX
  wget https://www.cacti.net/downloads/spine/cacti-spine-latest.tar.gz
  tar xfz cacti-spine-latest.tar.gz
  cd cacti-spine*
  ./bootstrap
  ./configure --prefix=/usr
  make
  make install
  #chown root:root /usr/local/spine/bin/spine
  #chmod +s /usr/local/spine/bin/spine
  return $SUCCESS
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$version"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Log Startup Timestamp"
        printf "%-15s\t\t%-25s\n" "stop" "Log Shutdown Timestamp"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'--skip-apt-install')
	export BOL_DO_APT_INSTALL=$FALSE
	;;
'--skip-source-file')
	export BOL_CREATE_SOURCE_FILE=$FALSE
	;;
'--skip-snmp-file')
	export BOL_SNMP_CONF_FILE=$FALSE
	;;
'--skip-cacti-spine')
	export BOL_SETUP_CACTI_SPINE=$FALSE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export _BOL_VERBOSE=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        BOL_CREATE_SOURCE_FILE=$FALSE
        BOL_DO_APT_INSTALL=$FALSE
	BOL_SNMP_CONF_FILE=$FALSE
	BOL_SETUP_CACTI_SPINE=$FALSE
	do_HELP
        RETVAL=$FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
        BOL_CREATE_SOURCE_FILE=$FALSE
        BOL_DO_APT_INSTALL=$FALSE
	BOL_SNMP_CONF_FILE=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_CREATE_SOURCE_FILE -eq $TRUE ]; then
	CreateSourceFile
	RETVAL=$?
fi

if [ $BOL_DO_APT_INSTALL -eq $TRUE ]; then
	DoAptInstall
	RETVAL=$?
fi

if [ $BOL_SNMP_CONF_FILE -eq $TRUE ]; then
	CreateSnmpConfFile
	RETVAL=$?
fi

if [ $BOL_SETUP_CACTI_SPINE -eq $TRUE ]; then
	SetupCactiSpine
	RETVAL=$?
fi

exit $RETVAL



