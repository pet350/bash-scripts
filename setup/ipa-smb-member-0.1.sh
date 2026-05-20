#!/bin/bash
# Shell Script By: Peter Talbott
# Ideas sourced from: https://freeipa.readthedocs.io/en/latest/designs/adtrust/samba-domain-member.html

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

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig RETVAL=$SUCCESS

REQUIRE_ROOT_USER

# Define Global String Variables
export HOST_FQDN=$(hostname --fqdn)
export NETBIOS_NAME=$(hostname --short)
export CRYPT_TYPE="aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha1-96,arcfour-hmac"
export RANDOM_PASSWORD="$(python3 -c 'import samba; print(samba.generate_random_password(128, 255))')"
export Q5_BIN="/usr/local/sbin/q5"

# Make sure all needed binaries exist and are defined
if [ ${#SLEEP_BIN}	    -eq 0 ]; then echo -e "Error! Binary sleep not found!";		      exit $FAILURE;  fi
if [ ${#NET_BIN}	    -eq 0 ]; then echo -e "Error! Binary net not found!";		      exit $FAILURE;  fi
if [ ${#IPA_BIN}            -eq 0 ]; then echo -e "Error! Binary ipa not found!";                     exit $FAILURE;  fi
if [ ${#IPA_GETKEYTAB_BIN}  -eq 0 ]; then echo -e "Error! Binary ipa-getkeytab not found!";           exit $FAILURE;  fi

function GET_IPA_INFO()
{
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1
  declare -i BOL_BASE_ID=$FALSE
  declare -i BOL_RANGE_SIZE=$FALSE
  declare -i FUNCTION_RETURN=$SUCCESS

  $Q5_BIN
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    for WORD in $LINE; do
      ((WORD_INDEX++))
    done
    case $LINE_INDEX in
      '0')
        export REALM="$WORD"
	;;
      '1')
        export IPA_NT_SID="$WORD"
        ;;
      '2')
	export IPA_FLAT_NAME="$WORD"
	;;
      '3')
	export IPA_NT_DOMAIN_GUID="$WORD"
	;;
    esac
  done < <($IPA_BIN trustconfig-show --raw)

  LINE_INDEX=-1
  WORD_INDEX=-1
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    BOL_BASE_ID=$FALSE
    BOL_RANGE_SIZE=$FALSE
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $BOL_BASE_ID -eq $TRUE ]; then export IDMAP_MIN="$WORD"; fi
      if [ $BOL_RANGE_SIZE -eq $TRUE ]; then export IDMAP_RANGE="$WORD"; fi
      case $WORD in
	'ipabaseid:')
	  export BOL_BASE_ID=$TRUE
	  export BOL_RANGE_SIZE=$FALSE
	  ;;
	'ipaidrangesize:')
          export BOL_BASE_ID=$FALSE
          export BOL_RANGE_SIZE=$TRUE
          ;;
	*)
          export BOL_BASE_ID=$FALSE
          export BOL_RANGE_SIZE=$FALSE
          ;;
      esac
    done
  done < <($IPA_BIN idrange-find --raw)
  export IDMAP_MAX=$((IDMAP_MIN+IDMAP_RANGE-1))
  return $FUNCTION_RETURN
};

function SHOW_INFO()
{
  echo -e "Realm:\t\t$REALM"
  echo -e "FQDN:\t\t$HOST_FQDN"
  echo -e "NetBIOS Name:\t$NETBIOS_NAME"
  echo -e "IPA Flat Name:\t$IPA_FLAT_NAME"
  echo -e "IPA NT SID:\t$IPA_NT_SID"
  echo -e "IPA NT Guid:\t$IPA_NT_DOMAIN_GUID"
  echo -e "ID Map Min:\t$IDMAP_MIN"
  echo -e "ID Map Max:\t$IDMAP_MAX"
  echo -e "Encryption:\t$CRYPT_TYPE"
  echo -e "Random PW:\t$RANDOM_PASSWORD"
  return $SUCCESS
};

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

GET_IPA_INFO
SHOW_INFO

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"$IPA_GETKEYTAB_BIN -p cifs/$HOST_FQDN -k /etc/samba/samba.keytab -e $CRYPT_TYPE -P"$CC
echo -e "$RANDOM_PASSWORD\n$RANDOM_PASSWORD\n" | $IPA_GETKEYTAB_BIN -p cifs/$HOST_FQDN -k /etc/samba/samba.keytab -e $CRYPT_TYPE -P
export RETVAL=$?; export COMMAND="$IPA_GETKEYTAB_BIN";SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"$NET_BIN setdomainsid $IPA_NT_SID"$CC
$NET_BIN setdomainsid $IPA_NT_SID
export RETVAL=$?; export COMMAND="$NET_BIN";SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"$NET_BIN getlocalsid"$CC
$NET_BIN getlocalsid
export RETVAL=$?; export COMMAND="$NET_BIN";SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"$NET_BIN getdomainsid"$CC
$NET_BIN getdomainsid
export RETVAL=$?; export COMMAND="$NET_BIN";SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"tdbtool /var/lib/samba/private/secrets.tdb store SECRETS/MACHINE_LAST_CHANGE_TIME/$NETBIOS_NAME '2\00'"$CC
tdbtool /var/lib/samba/private/secrets.tdb store SECRETS/MACHINE_LAST_CHANGE_TIME/$NETBIOS_NAME '2\00'
export RETVAL=$?; export COMMAND="tdbtool"; SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"tdbtool /var/lib/samba/private/secrets.tdb store SECRETS/MACHINE_PASSWORD/$NETBIOS_NAME '2\00'"$CC
tdbtool /var/lib/samba/private/secrets.tdb store SECRETS/MACHINE_PASSWORD/$NETBIOS_NAME '2\00'
export RETVAL=$?; export COMMAND="tdbtool"; SHOW_DATE_TIME; LOG_RESULTS; echo ''

SHOW_DATE_TIME; echo -e $CLB"Executing: "$CY"$NET_BIN changesecretpw -f"$CC
echo -e "$RANDOM_PASSWORD\n$RANDOM_PASSWORD\n" | $NET_BIN changesecretpw -f
export RETVAL=$?; export COMMAND="$NET_BIN"; SHOW_DATE_TIME; LOG_RESULTS; echo ''

/usr/local/sbin/restart smbd nmbd winbind

exit $RETVAL

