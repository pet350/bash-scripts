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
export VERSION="0.2"

declare -ig RETVAL=$SUCCESS

REQUIRE_ROOT_USER

# Function tests weather to use python or python3 to 'import samba'
function TEST_SAMBA_PYTHON()
{
  declare -i FUNCTION_RETURN=$FAILURE
  $PYTHON_BIN -c 'import samba' >/dev/null 2>/dev/null
  if [ $? -eq $SUCCESS ]; then
    echo -e "$PYTHON_BIN"
    FUNCTION_RETURN=$SUCCESS
  else
    $PYTHON3_BIN -c 'import samba' >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      echo -e "$PYTHON3_BIN"
      FUNCTION_RETURN=$SUCCESS
    else
      echo -e "$FALSE_BIN"
      FUNCTION_RETURN=$FAILURE
    fi
  fi
  return $FUNCTION_RETURN
};

# Define Global String Variables
export HOST_FQDN=$(hostname --fqdn)
export NETBIOS_NAME=$(hostname --short)
export PY_BIN=$(TEST_SAMBA_PYTHON)
export CRYPT_TYPE="aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha1-96,arcfour-hmac"
export RANDOM_PASSWORD="$($PY_BIN -c 'import samba; print(samba.generate_random_password(128, 255))')"
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
  SHOW_DATE_TIME; printf "%b" $CLB; printf "%-15s\n" $RUN_CMD;  printf "%b" $CN;
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Version:\t\t";	printf "%b" $CY; printf "%s%b\n" "$VERSION" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Realm:\t\t";	printf "%b" $CY; printf "%s%b\n" "$REALM" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "FQDN:\t\t";		printf "%b" $CY; printf "%s%b\n" "$HOST_FQDN" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "NetBIOS Name:\t";	printf "%b" $CY; printf "%s%b\n" "$NETBIOS_NAME" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "IPA Flat Name:\t";	printf "%b" $CY; printf "%s%b\n" "$IPA_FLAT_NAME" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "IPA NT SID:\t";	printf "%b" $CY; printf "%s%b\n" "$IPA_NT_SID" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "IPA NT Guid:\t";	printf "%b" $CY; printf "%s%b\n" "$IPA_NT_DOMAIN_GUID" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "ID Map Min:\t";	printf "%b" $CY; printf "%s%b\n" "$IDMAP_MIN" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "ID Map Max:\t";	printf "%b" $CY; printf "%s%b\n" "$IDMAP_MAX" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Encryption:\t";	printf "%b" $CY; printf "%s%b\n" "$CRYPT_TYPE" $CN
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Random PW:\t";	printf "%b" $CY; printf "%s%b\n\n" "$RANDOM_PASSWORD" $CN
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
export RETVAL=$?; export COMMAND="$NET_BIN"; printf "\n"; SHOW_DATE_TIME; LOG_RESULTS; echo ''

/usr/local/sbin/restart smbd nmbd winbind

exit $RETVAL

