# Network Definitions Script Include File
# To simplify script writting, I Use this file for MOST functions
# that I use on a regualar basis
# Peter Talbott
# Version 0.1


function STORE_IFCONFIG_ARRAY()
{
  declare -i LINE_INDEX=-1
  declare -i WORD_INDEX=-1
  declare -i IFACE_INDEX=-1
  declare -i BOL_INET=$FALSE
  declare -i BOL_MASK=$FALSE
  declare -i BOL_BCAST=$FALSE
  declare -i BOL_MAC=$FALSE
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -Ag IFCFG_ARRAY=();

  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1; BOL_INET=$FALSE; BOL_MASK=$FALSE; BOL_BCAST=$FALSE; BOL_MAC=$FALSE
    for WORD in $LINE; do
      ((WORD_INDEX++))
      WORD_LEN=${#WORD}
      if [ $WORD_INDEX -eq 0 ] && [ "${WORD:$((WORD_LEN-1))}" == ':' ]; then
        ((IFACE_INDEX++));
        IFCFG_ARRAY[$((IFACE_INDEX)),0]="${WORD:0:$((WORD_LEN-1))}"
	IFCFG_ARRAY[0,5]=$((IFACE_INDEX))
      elif [ $BOL_INET -eq $TRUE ];  then IFCFG_ARRAY[$((IFACE_INDEX)),1]="$WORD"
      elif [ $BOL_MASK -eq $TRUE ];  then IFCFG_ARRAY[$((IFACE_INDEX)),2]="$WORD"
      elif [ $BOL_BCAST -eq $TRUE ]; then IFCFG_ARRAY[$((IFACE_INDEX)),3]="$WORD"
      elif [ $BOL_MAC -eq $TRUE ];   then IFCFG_ARRAY[$((IFACE_INDEX)),4]="$WORD"
      fi
      case $WORD in
        'inet')
          BOL_INET=$TRUE; BOL_MASK=$FALSE; BOL_BCAST=$FALSE; BOL_MAC=$FALSE
          ;;
	'netmask')
          BOL_INET=$FALSE; BOL_MASK=$TRUE; BOL_BCAST=$FALSE; BOL_MAC=$FALSE
          ;;
	'broadcast')
          BOL_INET=$FALSE; BOL_MASK=$FALSE; BOL_BCAST=$TRUE; BOL_MAC=$FALSE
	  ;;
        'ether')
          BOL_INET=$FALSE; BOL_MASK=$FALSE; BOL_BCAST=$FALSE; BOL_MAC=$TRUE
	  ;;
        *)
          BOL_INET=$FALSE; BOL_MASK=$FALSE; BOL_BCAST=$FALSE; BOL_MAC=$FALSE
	  ;;
      esac
    done
  done < <($IFCONFIG_BIN)
  FUNCTION_RETURN=$?
  return $FUNCTION_RETURN
};

function GET_NETWORK_INFO()
{
  declare -i IFACE_COUNT=-1
  declare -i IFACE_TOTAL=-1
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i BOL_FOUND=$FALSE

  if [ ${#INFO_INDEX} -eq 0 ] || [ $((INFO_INDEX)) -gt 4 ] || [ $((INFO_INDEX)) -lt 1 ]; then
    INFO_INDEX=1
  fi
  if [ ${#IFCONFIG_BIN} -ne 0 ]; then
    if [ ${#IF_NAME} -ne 0 ]; then
      STORE_IFCONFIG_ARRAY
      IFACE_TOTAL="${IFCFG_ARRAY[0,5]}"
      IFACE_TOTAL=$((IFACE_TOTAL))
      while [ $IFACE_COUNT -ne $IFACE_TOTAL ]; do
        ((IFACE_COUNT++))
        if [ "${IFCFG_ARRAY[$((IFACE_COUNT)),0]}" == "$IF_NAME" ]; then
	  echo -e "${IFCFG_ARRAY[$((IFACE_COUNT)),$((INFO_INDEX))]}"
	  BOL_FOUND=$TRUE
	fi
      done
      if [ $BOL_FOUND -eq $FALSE ]; then echo -e "Interface: $IF_NAME Not Found!"; FUNCTION_RETURN=$FAILURE; fi
    else
      echo -e "No Interface Specified!"
      FUNCTION_RETURN=$FAILURE
    fi
  else
    echo -e "ifconfig binary not found!"
    FUNCTION_RETURN=$FAILURE
  fi
  return $FUNCTION_RETURN
};

function GET_IP()
{
  export INFO_INDEX=1
  GET_NETWORK_INFO
  return $?
};

function GET_NETMASK()
{
  export INFO_INDEX=2
  GET_NETWORK_INFO
  return $?
};

function GET_BCAST()
{
  export INFO_INDEX=3
  GET_NETWORK_INFO
  return $?
};

function GET_MAC()
{
  export INFO_INDEX=4
  GET_NETWORK_INFO
  return $?
};
