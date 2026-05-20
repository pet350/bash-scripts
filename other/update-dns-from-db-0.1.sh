#!/bin/bash
# Shell Script By: Peter Talbott
# 2022-01-17,18

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
export MODIFIED="2022-01-17"

declare -ag DHCPDB_ADR_ARRAY=();
declare -ag DHCPDB_MAC_ARRAY=();

declare -ag MACDB_NAME_ARRAY=();
declare -ag MACDB_MAC_ARRAY=();

declare -ag MACDB_ARRAY=();


for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --debug)		export BOL_VERBOSE=$TRUE;	BOL_QUIET=$FALSE;	BOL_DEBUG=$TRUE;	SCRIPT_DEBUG="--verbose";;
    --verbose)		export BOL_VERBOSE=$TRUE;	BOL_QUIET=$FALSE;				SCRIPT_DEBUG="--verbose";;
    --quiet)		export BOL_QUIET=$TRUE;;
    --version)		export BOL_VERSION=$TRUE;;
    --once)		export BOL_ONCE=$TRUE;;
    --macdb=*)		export MACDB="${OPTIONS#*=}";;
    --dhcpdb=*)		export DHCPDB="${OPTIONS#*=}";;
    --path=*)		export MONITOR_PATH="${OPTIONS#*=}";;
  esac
done

if [ ${#MACDB}		-eq 0 ]; then export MACDB="/etc/macdb.cfg";			fi
if [ ${#DHCPDB}		-eq 0 ]; then export DHCPDB="/var/lib/tftp/dhcp.dat";		fi
if [ ${#SCRIPT_DEBUG}	-eq 0 ]; then export SCRIPT_DEBUG="--quiet";			fi
if [ ${#BOL_VERSION}	-eq 0 ]; then export BOL_VERSION=$FALSE;			fi
if [ ${#BOL_ONCE}	-eq 0 ]; then export BOL_ONCE=$FALSE;				fi
if [ ${#MONITOR_PATH}	-eq 0 ]; then export MONITOR_PATH="/var/lib/tftp";		fi
if [ ${#BOL_QUIET}	-eq 0 ]; then export BOL_QUIET=$TRUE;				fi

export DNS_UPDATE="/usr/local/sbin/dns-update.sh"

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function GETMAC()
{
  declare -i WORD_LEN=${#WORD}
  declare -i CHAR=0
  declare -i WORD_INDEX=$((WORD_LEN-1))
  declare -i START_INDEX=$((WORD_INDEX-14))
  export RAW_DATA=""
  while [ $CHAR -ne 12 ]; do
    LETTER=${WORD:$((WORD_INDEX)):1}
    case $LETTER in
      '.') /bin/true;;
      *) RAW_DATA="$LETTER$RAW_DATA"; ((CHAR++))
    esac
    ((WORD_INDEX--))
  done
  echo $RAW_DATA
  return $SUCCESS
};

function READ_DHCP_DB()
{
  declare -i BOL_IP=$FALSE
  declare -i FILE_LEN=$(cat "$DHCPDB" | wc -l)
  declare -i FILE_LEN_NO_HEADER=$((FILE_LEN-3))
  declare -i FILE_LEN_NO_FOOTER=$((FILE_LEN_NO_HEADER-6))
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1

  while IFS= read LINE; do
    WORD_INDEX=-1
    ((LINE_INDEX++))
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then DHCPDB_ADR_ARRAY[ $((LINE_INDEX)) ]=$WORD; fi
      if [ $WORD_INDEX -eq 2 ]; then DHCPDB_MAC_ARRAY[ $((LINE_INDEX)) ]=$(GETMAC); fi
    done
  done < <(cat "$DHCPDB" | tail --lines=$FILE_LEN_NO_HEADER | head --lines=$FILE_LEN_NO_FOOTER)
  return $?
};

function READ_MAC_DB()
{
  declare -i FILE_LEN=$(cat $MACDB | wc -l)
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1

  while IFS= read LINE; do
    WORD_INDEX=-1
    ((LINE_INDEX++))
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then MACDB_NAME_ARRAY[ $((LINE_INDEX)) ]=$WORD; fi
      if [ $WORD_INDEX -eq 1 ]; then MACDB_MAC_ARRAY[ $((LINE_INDEX)) ]=$WORD; fi
    done
  done < <( cat "$MACDB" )
  return $?
};

function STORE_DNS()
{
  declare -i NESTED_INDEX=-1
  declare -i INDEX=-1
  export COMMAND="DNS Update"

  for MAC_ADDRESS in ${DHCPDB_MAC_ARRAY[@]}; do
    ((INDEX++))
    NESTED_INDEX=-1
    unset NAME
    RETVAL=$SUCCESS
    IP_ADDRESS="${DHCPDB_ADR_ARRAY[$((INDEX))]}"
    for DATA in ${MACDB_MAC_ARRAY[@]}; do
      ((NESTED_INDEX++))
      MAC_DATA=${DATA,,}
      if [ $MAC_ADDRESS == $MAC_DATA ]; then
        NAME="${MACDB_NAME_ARRAY[$((NESTED_INDEX))]}"
      else
        if [ ${#NAME} -eq 0 ]; then
          NAME="DHCP-${MAC_ADDRESS^^}"
        fi
      fi
    done
    printf "Hostname: %-25s IP Address: %-15s MAC Address: %-20s\n" $NAME $IP_ADDRESS ${MAC_ADDRESS^^}
    while [ $RETVAL -ne 255 ]; do
      $DNS_UPDATE delete $IP_ADDRESS ${MAC_ADDRESS^^} $SCRIPT_DEBUG
      RETVAL=$?
    done
    $DNS_UPDATE add $IP_ADDRESS ${MAC_ADDRESS^^} $NAME $SCRIPT_DEBUG
    export RETVAL=$?
    if [ $BOL_QUIET -ne $TRUE ]; then LOG_RESULTS; fi
    echo -e "\n"
  done
  return $RETVAL
};

function MAIN_LOOP()
{
  declare -i BOL_LOOP=$TRUE
  while [ $BOL_LOOP -eq $TRUE ]; do
    READ_DHCP_DB
    READ_MAC_DB
    STORE_DNS
    if [ $BOL_ONCE -eq $TRUE ]; then
      BOL_LOOP=$FALSE
    else
      $INOTIFYWAIT_BIN -q -e modify,create,delete,move -r $MONITOR_PATH
    fi
  done
  return $?
};


if [ $BOL_HELP		-eq $TRUE ]; then DO_HELP;	exit $SUCCESS;				fi
if [ $BOL_VERSION	-eq $TRUE ]; then SHOW_HEADER;	exit $SUCCESS;				fi

MAIN_LOOP

exit $?
