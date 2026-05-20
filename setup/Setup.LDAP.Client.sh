#!/bin/bash
# Script to setup LDAP Client Authentication


declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig TRUE=1
declare -ig FALSE=0


# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

function do_HELP()
{
        printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$version"
        printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Log Startup Timestamp"
        printf "%-15s\t\t%-25s\n" "stop" "Log Shutdown Timestamp"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig VAR_UNKNOWN=$FALSE
declare -ig BOL_APT_INSTALL=$TRUE

declare -ag PACKAGE_ARRAY=('build-essential' 'ldap-auth-config' 'libnss-ldap' 'libpam-ldap' 'nscd' 'dh-python' 'libpython-stdlib:amd64' 'libpython2-stdlib:amd64' 'libpython2.7-minimal:amd64' 'libpython2.7-stdlib:amd64' 'libpython3-stdlib:amd64' 'libpython3.6:amd64' 'libpython3.6-minimal:amd64' 'libpython3.6-stdlib:amd64' 'libpython3.7-minimal:amd64' 'libpython3.7-stdlib:amd64' 'python' 'python-alabaster' 'python-apt-common' 'python-babel' 'python-babel-localedata' 'python-certifi' 'python-chardet' 'python-distutils-extra' 'python-docutils' 'python-funcsigs' 'python-idna' 'python-imagesize' 'python-jinja2' 'python-markupsafe' 'python-minimal' 'python-mock' 'python-packaging' 'python-pbr' 'python-pkg-resources' 'python-pyflakes' 'python-pygments' 'python-pyparsing' 'python-requests' 'python-roman' 'python-six' 'python-sphinx' 'python-typing' 'python-tz' 'python-urllib3' 'python2' 'python2-minimal' 'python2.7' 'python2.7-minimal' 'python3' 'python3-all' 'python3-apport' 'python3-apt' 'python3-asn1crypto' 'python3-attr' 'python3-automat' 'python3-certifi' 'python3-cffi-backend' 'python3-chardet' 'python3-click' 'python3-colorama' 'python3-commandnotfound' 'python3-configobj' 'python3-constantly' 'python3-cryptography' 'python3-dbus' 'python3-debconf' 'python3-debian' 'python3-distro-info' 'python3-distupgrade' 'python3-distutils' 'python3-distutils-extra' 'python3-gdbm:amd64' 'python3-gi' 'python3-httplib2' 'python3-hyperlink' 'python3-idna' 'python3-incremental' 'python3-lib2to3' 'python3-minimal' 'python3-mock' 'python3-netifaces' 'python3-newt:amd64' 'python3-openssl' 'python3-pam' 'python3-pbr' 'python3-pkg-resources' 'python3-problem-report' 'python3-pyasn1' 'python3-pyasn1-modules' 'python3-pycodestyle' 'python3-requests' 'python3-requests-unixsocket' 'python3-serial' 'python3-service-identity' 'python3-six' 'python3-software-properties' 'python3-systemd' 'python3-twisted' 'python3-twisted-bin:amd64' 'python3-update-manager' 'python3-urllib3' 'python3-yaml' 'python3-zope.interface' 'python3.6' 'python3.6-minimal' 'python3.7' 'python3.7-minimal');

export SOURCE_PREFIX="/usr/local/xen/LDAP-Client"
export AUTH_CLIENT="auth-client-config-0.9ubuntu1"
export CONFIG_PREFIX="/etc"
export USER_PREFIX="/usr"
export APT_BIN="/usr/bin/apt"
export PKG_LIST=""

if [ ! -d $SOURCE_PREFIX ]; then
  echo -e "Directoy $SOURCE_PREFIX Does NOT Exist!"
  exit $FAILURE
fi

for i in "$@"
do
case $i in
'-h' | '--help')
        export BOL_HELP=$TRUE
        export BOL_START=$FALSE
        export BOL_STOP=$FALSE
        ;;
'--no-apt')
	export BOL_APT_INSTALL=$FALSE
	;;
'--short-apt')
	export BOL_APT_INSTALL=$TRUE
	PACKAGE_ARRAY=('build-essential' 'ldap-auth-config' 'libnss-ldap' 'libpam-ldap' 'nscd');
	;;
*)
        (( _VAR_UNKNOWN++ ))
        echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $_BOL_HELP -eq $TRUE ]; then
        _BOL_START=$FALSE
        _BOL_STOP=$FALSE
        do_HELP
        RETVAL=$FAILURE
fi


if [ -d $SOURCE_PREFIX$CONFIG_PREFIX ]; then
  cp -vR $SOURCE_PREFIX$CONFIG_PREFIX/* $CONFIG_PREFIX
fi

if [ $BOL_APT_INSTALL -eq $TRUE ]; then $APT_BIN update; fi

for TEMP in ${PACKAGE_ARRAY[@]}; do
  PKG_LIST="$PKG_LIST $TEMP"
  if [ $BOL_APT_INSTALL -eq $TRUE ]; then $APT_BIN install $TEMP -y; fi
done

if [ $BOL_APT_INSTALL -eq $TRUE ]; then echo -e "\nInstalled Package List: $PKG_LIST\n\n"; fi

cd $SOURCE_PREFIX/$AUTH_CLIENT
./install.py --prefix=$USER_PREFIX --config-prefix=$CONFIG_PREFIX

if [ -d $SOURCE_PREFIX$CONFIG_PREFIX ]; then
  cp -R $SOURCE_PREFIX$CONFIG_PREFIX/* $CONFIG_PREFIX
fi

/usr/sbin/auth-client-config -t nss -p lac_ldap
/usr/sbin/pam-auth-update
/etc/init.d/nscd restart

if [ $BOL_APT_INSTALL -eq $TRUE ]; then
  $APT_BIN clean
  $APT_BIN auto-clean
fi

# DONE!!!
exit $SUCCESS
