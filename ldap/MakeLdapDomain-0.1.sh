#!/bin/bash
### By: Peter Talbott 2019-08-10

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit $FAILURE
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export ETC_PREFIX="/etc"
export KDC_PREFIX="$ETC_PREFIX/krb5kdc"

# Define Application Binaries
export XL_BIN="$USER_PREFIX$SBIN_PREFIX/xl"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export PS_BIN="$BIN_PREFIX/ps"
export GREP_BIN="$BIN_PREFIX/grep"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export KILL_BIN="$BIN_PREFIX/kill"
export KADMIN_BIN="$USER_PREFIX$SBIN_PREFIX/kadmin.local"
export KDB_LDAP_BIN="$USER_PREFIX$SBIN_PREFIX/kdb5_ldap_util"

# Define Boolean Variables
declare -ig BOL_MAKE_REALM=$FALSE
declare -ig BOL_MAKE_PRINCS=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig VAR_WAIT=1

# Define Application Options
export VERBOSE=""
export LDAP_URI="ldap://"
export CREATE="create"
export RANDKEY="-randkey"
export STASH_SERVER_PASSWORD="stashsrvpw"
export ADD_PRINC="addprinc"
export SUBTREES="-subtrees"
export ROOT_DN="dc=gigaware,dc=lan"
export ADMIN_DN="cn=admin,$ROOT_DN"
export REALM="GIGAWARE.LAN"
export DOMAIN="gigaware.lan"
export LDAP_SERVER_1="ldap.$DOMAIN"
export LDAP_SERVER_2="xen.$DOMAIN"
export SERVICE_KEYFILE="$KDC_PREFIX/service.keyfile"

# Define Global Arrays
declare -ag PRINC_ARRAY=("host/ldap.$DOMAIN@$REALM" "ldap/ldap.$DOMAIN@$REALM" "nfs/ldap.$DOMAIN@$REALM" \
			"host/xen.$DOMAIN@$REALM" "ldap/xen.$DOMAIN@$REALM" "nfs/xen.$DOMAIN@$REALM");
function MAKE_PRINCS()
{
  declare -i RETVAL=$FAILURE
  for TEMP in ${PRINC_ARRAY[@]}; do
    echo -e "$ADD_PRINC $RANDKEY $TEMP" | $KADMIN_BIN
    RETVAL=$?
  done
  return $RETVAL
};

function MAKE_REALM()
{
  declare -i RETVAL=$FAILURE
  $KDB_LDAP_BIN -D $ADMIN_DN $CREATE $SUBTREES $ROOT_DN -r $REALM -s -H $LDAP_URI$LDAP_SERVER_1
  RETVAL=$?
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  $KDB_LDAP_BIN -D $ADMIN_DN $STASH_SERVER_PASSWORD -f $SERVICE_KEYFILE $ADMIN_DN
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  return $RETVAL
};

for i in "$@"
do
case $i in
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'--make-realm')
	export BOL_MAKE_REALM=$TRUE
	;;
'--make-princs')
	export BOL_MAKE_PRINCS=$TRUE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
        ;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
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

if [ $BOL_MAKE_REALM -eq $TRUE ]; then
	MAKE_REALM
	RETVAL=$?
fi

if [ $BOL_MAKE_PRINCS -eq $TRUE ]; then
	MAKE_PRINCS
	RETVAL=$?
fi

exit $RETVAL
