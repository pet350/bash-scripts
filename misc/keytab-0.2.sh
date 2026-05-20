#!/bin/bash
# keytab.sh - Generating Kerberos Keytabs
# Shell Script By: Peter Talbott

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

export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in st klist curl egrep chown sleep cat wc find true; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

function SHOW_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success. Return Value: $RETVAL"
  else
    echo -e "Failure. Return Value: $RETVAL"
  fi
};

function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  CLB_TEXT; printf "%-24s" $RUN_CMD; CY_TEXT; printf "Version: "; CC_TEXT; printf "%-4s" $VERSION; CN_TEXT; printf "\n"
  CLB_TEXT; printf "By: "; CLR_TEXT; printf "%-20s" "$AUTHOR"; CLB_TEXT; printf "Dated: "; CLR_TEXT; printf "%-20s" "$MODIFIED"; CN_TEXT; printf "\n"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

function DEBUG_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Starting: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_EXEC_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Executing: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_FOUND_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Found: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_INFO_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Information: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};


function DEBUG_DONE_MESSAGE()
{
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n"
  fi
  return $RETVAL
};

function SHOW_ALL()
{
    SHOW_HEADER
    printf "\n%s\n" "----------------------------------------------------------------------------"
    DEBUG_INFO_MESSAGE "Host: $HOST"
    DEBUG_INFO_MESSAGE "Hostname: $HOSTNAME"
    DEBUG_INFO_MESSAGE "Realm: $REALM"
    DEBUG_INFO_MESSAGE "Domain: $DOMAIN"
    DEBUG_INFO_MESSAGE "Keytab: $KEYTAB"
    DEBUG_INFO_MESSAGE "Samba Tool: $ST_BIN"
    DEBUG_INFO_MESSAGE "klist: $KLIST_BIN"
    printf "%s\n\n" "----------------------------------------------------------------------------"
    return $SUCCESS
};

for OPTIONS in $@; do
    case $OPTIONS in
        -v | --verbose)	declare -i BOL_VERBOSE=$TRUE;;
	-d | --debug)	declare -i BOL_DEBUG=$TRUE;;
	-t | --test)	declare -i BOL_TEST=$TRUE;;
	--version)	declare -i BOL_VERSION=$TRUE;;
        --host=*)	declare -x HOST="${OPTIONS#*=}";;
        --hostname=*)	declare -x HOSTNAME="${OPTIONS#*=}";;
        --realm=*)	declare -x REALM="${OPTIONS#*=}";;
        --domain=*)	declare -x DOMAIN="${OPTIONS#*=}";;
        --keytab=*)	declare -x KEYTAB="${OPTIONS#*=}";;
    esac
done

if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;					fi
if [ ${#BOL_DEBUG}	-eq 0 ]; then declare -i BOL_DEBUG=$FALSE;					fi
if [ ${#BOL_VERSION}	-eq 0 ]; then declare -i BOL_VERSION=$FALSE;					fi
if [ ${#BOL_TEST}	-eq 0 ]; then declare -i BOL_TEST=$FALSE;					fi
if [ ${#HOST}		-eq 0 ]; then declare -x HOST="${HOSTNAME%%.*}";				fi
if [ ${#ERROR_OUT}	-eq 0 ]; then declare -x ERROR_OUT="/dev/stderr";				fi
if [ ${#KEYTAB}         -eq 0 ]; then declare -x KEYTAB="/etc/krb5.keytab";             		fi
if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;                                             fi
if [ $BOL_VERSION -eq $TRUE   ]; then SHOW_HEADER; exit $SUCCESS;					fi
if [ $BOL_VERBOSE -eq $TRUE   ]; then SHOW_ALL;								fi
if [ $BOL_DEBUG	  -eq $TRUE   ]; then declare -x KRB5_TRACE=$ERROR_OUT;					fi
if [ $BOL_TEST    -eq $TRUE   ]; then declare -x ST_BIN=$TRUE_BIN;					fi

for X in "$HOST" "host/$HOST" "host/$HOSTNAME" "RestrictedKrbHost/$HOST" "RestrictedKrbHost/$HOSTNAME" "HOST/$HOSTNAME/$HOSTNAME" "HOST/$HOSTNAME"      \
         "ldap/$HOSTNAME" "GC/$HOSTNAME/$HOSTNAME" "GC/$HOSTNAME" "LDAP/$HOSTNAME" "ldap/$HOST" "ldap/$HOSTNAME/DomainDnsZones.$DOMAIN"                 \
         "ldap/$HOSTNAME/ForestDnsZones.$DOMAIN" "cifs/$HOSTNAME" "CIFS/$HOSTNAME" "NFS/$HOSTNAME" "nfs/$HOSTNAME"; do

    declare -x PRINCIPAL="$X@$REALM"
    DEBUG_START_MESSAGE "Principal: $PRINCIPAL"
    if [ $BOL_TEST -eq $TRUE ]; then DEBUG_INFO_MESSAGE "Test Mode enabled"; 				fi
    $ST_BIN domain exportkeytab $KEYTAB --realm=$REALM --principal=$PRINCIPAL
    declare -i RETVAL=$?
    DEBUG_DONE_MESSAGE "$ST_BIN domain exportkeytab $KEYTAB --realm=$REALM --principal=$PRINCIPAL Returned: $RETVAL"
    printf "\n"
done

if [ $BOL_VERBOSE -eq $TRUE ]; then CC_TEXT; $KLIST_BIN -etk "$KEYTAB"; RETVAL=$?; CN_TEXT; printf "\n"; fi

exit $RETVAL
