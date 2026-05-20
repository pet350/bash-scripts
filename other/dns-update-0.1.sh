#!/bin/bash
# Shell Script By: Peter Talbott
# 2022-01-17

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
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-01-17"

declare -i BOL_VERBOSE=$TRUE	# Temporary Set Verbose as Default

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

# script is based on samba-tool. exit if not found
export TEMP="samba-tool"; GET_BIN >/dev/null
if [ $? -eq $SUCCESS ]; then export ST_BIN=$(GET_BIN); else SHOW_HEADER; echo -e "$TEMP not found"; exit $FAILURE; fi

export TEMP="host"; GET_BIN >/dev/null
if [ $? -eq $SUCCESS ]; then export HOST_BIN=$(GET_BIN); else SHOW_HEADER; echo -e "$TEMP not found"; exit $FAILURE; fi

function USAGE()
{
  SHOW_HEADER
  echo "USAGE:"
  echo "  $RUN_CMD add ip-address dhcid|mac-address hostname"
  echo "  $RUN_CMD delete ip-address dhcid|mac-address"
  echo "  $RUN_CMD --help | -h for more help"
};

function VERBOSE_HEADER()
{
  SHOW_HEADER
  echo ''
  echo -e "Script Function:\t$SCRIPT_FUNCTION"
  echo -e "IP Address:\t\t$IP_ADDRESS"
  echo -e "MAC Address:\t\t$MAC_ADDRESS"
  echo -e "Host Name:\t\t$HOST_NAME"
  echo -e "Existing A Record:\t$A_RECORD"
  echo -e "Existing PTR Record:\t$PTR_RECORD"
  echo ''
  return $SUCCESS
};

function GET_PTR()
{
  declare INDEX=-1
  declare RETVAL=$SUCCESS
  if [ ${#IP_ADDRESS} -ne 0 ]; then
    $HOST_BIN -4 $IP_ADDRESS >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      for DATA in $($HOST_BIN -4 $IP_ADDRESS); do
        ((INDEX++))
        if [ $INDEX -eq 0 ]; then echo $DATA; fi
      done
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function GET_A_RECORD()
{
  declare INDEX=-1
  declare RETVAL=$SUCCESS
  if [ ${#HOST_NAME} -ne 0 ]; then
    $HOST_BIN -4 $HOST_NAME >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      for DATA in $($HOST_BIN -4 $HOST_NAME); do
        ((INDEX++))
        if [ $INDEX -eq 3 ]; then echo $DATA; fi
      done
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function SET_PTR()
{
  declare INDEX=-1
  export TEMP_IP=$IP_ADDRESS
  export TEMP_PTR=""
  while [ $INDEX -ne 3 ]; do
    ((INDEX++))
    LAST_OCTET=${TEMP_IP##*.} # Store Last Octet
    TEMP_IP=${TEMP_IP%.*}     # Strip Last Octet
    TEMP_PTR="$TEMP_PTR${LAST_OCTET}."
  done
  TEMP_PTR="${TEMP_PTR}in-addr.arpa"
  echo $TEMP_PTR
  return $SUCCESS
};

function SET_HOST()
{
  declare -i INDEX=-1
  for DATA in $($HOST $IP_ADDRESS); do
    ((INDEX++))
  done
  echo $DATA
  return $?
};

function DEL_RECORD()
{
  if [ ${#A_RECORD} -ne 0 ]; then
    ZONE=${HOST_NAME#*.}
    COMMAND="$ST_BIN dns delete"
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf  "Deleting Old A Record: %s from zone: %s\n" "$A_RECORD" "$ZONE"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then echo "[Debug] $ST_BIN dns delete $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
    $ST_BIN dns delete $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
    export RETVAL=$?; LOG_RESULTS
  fi

  if [ ${#PTR_RECORD} -ne 0 ]; then
    ZONE=${PTR_RECORD#*.}
    COMMAND="$ST_BIN dns delete"
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf  "Deleting Old PTR Record: %s from zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then echo "[Debug] $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
    $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
    export RETVAL=$?;LOG_RESULTS
  fi
  return $RETVAL
};

function ADD_RECORD()
{
  ZONE=${HOST_NAME#*.}
  COMMAND="$ST_BIN dns add"
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Adding New A Record: %s to zone: %s\n" "$HOST_NAME" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then echo "[Debug] $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
  $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
  export RETVAL=$?; LOG_RESULTS

  ZONE=${PTR_RECORD#*.}
  COMMAND="$ST_BIN dns add"
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf  "Adding New PTR Record: %s to zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then echo "[Debug] $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
  $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
  export RETVAL=$?;LOG_RESULTS
  return $RETVAL
};

for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --verbose)		export BOL_VERBOSE=$TRUE;;
    -h | --help)	export BOL_HELP=$TRUE;;
    -v | --version)	SHOW_HEADER; exit $SUCCESS;;
    --debug)		export BOL_DEBUG=$TRUE;;
    --config=*)		export CONFIG_FILE="${OPTIONS#*=}";;
    --USER=*)		export UPDATE_USER="${OPTIONS#*=}";;
    --pass=*)		export UPDATE_PASS="${OPTIONS#*=}";;
    --ip=*)		export IP_ADDRESS="${OPTIONS#*=}";;
    --host=*)		export HOST_NAME="${OPTIONS#*=}";;
    --mac=*)		export MAC_ADDRESS="${OPTIONS#*=}";;
    --server=*)		export SERVER="${OPTIONS#*=}";;
    --ptr=*)		export PTR_RECORD="${OPTIONS#*=}";;
    --domain=*)		export DOMAIN="${OPTIONS#*=}";;
    'add' | --add)	export SCRIPT_FUNCTION="ADD";;
    'delete' | --del)	export SCRIPT_FUNCTION="DELETE";;
  esac
done

if [ ${#CONFIG_FILE}	-eq 0	]; then export CONFIG_FILE="/etc/named/dns-update.conf";				fi
if [ -f $CONFIG_FILE		]; then . $CONFIG_FILE;									fi
if [ ${#IP_ADDRESS}	-eq 0	]; then export IP_ADDRESS=$2;								fi
if [ ${#MAC_ADDRESS}	-eq 0	]; then export MAC_ADDRESS=$3;								fi
if [ ${#HOST_NAME}	-eq 0	]; then export HOST_NAME=$4;								fi
if [ ${#PTR_RECORD}	-eq 0	]; then export PTR_RECORD=$(GET_PTR);							fi
if [ ${#A_RECORD}	-eq 0	]; then export A_RECORD=$(GET_A_RECORD);						fi
if [ ${#UPDATE_USER}	-eq 0	]; then export UPDATE_USER="dhcpduser";							fi
if [ ${#UPDATE_PASS}	-eq 0	]; then export UPDATE_PASS='Bl4ck3nd';							fi
if [ ${#SERVER}		-eq 0	]; then export SERVER="dc.gigaware.lan";						fi
if [ ${#DOMAIN}		-eq 0	]; then export DOMAIN="gigaware.lan";							fi
if [ $BOL_VERBOSE -eq $TRUE	]; then VERBOSE_HEADER;									fi

declare -i FINAL_VALUE=$SUCCESS
case $SCRIPT_FUNCTION in
  ADD)
    if [ ${#PTR_RECORD} -eq 0 ]; then PTR_RECORD=$(SET_PTR); fi
    HOST_NAME=$HOST_NAME.$DOMAIN
    DEL_RECORD
    ADD_RECORD
    FINAL_VALUE=$?
    ;;
  DELETE)
    HOST_NAME=$(SET_HOST)
    PTR_RECORD=$(SET_PTR)
    DEL_RECORD
    FINAL_VALUE=$?
    ;;
  *)
    USAGE
    FINAL_VALUE=$SUCCESS
    ;;
esac
exit $FINAL_VALUE
