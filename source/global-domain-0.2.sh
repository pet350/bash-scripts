#!/bin/bash
# Glohal Domain Source File
# Version 0.2

## New in Version 0.2
## attempt to kinit if a user keytab exists
## DOMAIN_LOGIN variable
## USER_KEYTAB variable

declare -i BOL_FUNCTION=$FALSE
declare -i LINE_INDEX=-1

# Test if GET_BIN has been defined yet
while IFS= read LINE; do
    ((LINE_INDEX++))
    if [ $LINE_INDEX -eq 0 ]; then
        for WORD in $LINE; do
            case $WORD in
                'function') BOL_FUNCTION=$TRUE;;
            esac
        done
    fi
done < <(LC_ALL=C type GET_BIN)

if [ $BOL_FUNCTION -eq $TRUE ]; then
  # Define a few more binary variables
  for DATA in realm head tail curl kinit ldapadd ldapmodify ldapsearch  egrep chown sleep find whoami; do
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

  if [ ${#DOMAIN}	-eq 0 ]; then declare -x DOMAIN=$($REALM_BIN discover | $HEAD_BIN --lines=1);					fi
  if [ ${#REALM}	-eq 0 ]; then declare -x REALM=${DOMAIN^^};									fi
  if [ ${#NB_DOMAIN}	-eq 0 ]; then declare -x NB_DOMAIN=${REALM%%.*};								fi
  if [ $(id -u) 	-eq 0 ]; then declare -x TEMP_WHOAMI="administrator@$DOMAIN"; else declare -x TEMP_WHOAMI=$($WHOAMI_BIN);	fi
  declare -x TEMP=${TEMP_WHOAMI%"@$DOMAIN"*}
  declare -x DOMAIN_LOGIN="$TEMP@$REALM";
  declare -x USER_KEYTAB="/home/$DOMAIN_LOGIN/.config/$TEMP.keytab";
  if [ -f $USER_KEYTAB	      ]; then $KINIT_BIN -t $USER_KEYTAB $DOMAIN_LOGIN 2>/dev/null;						fi
fi

for X in LINE_INDEX BOL_FUNCTION TEMP LINE WORD DATA TEMP_BIN TEMP_WHOAMI; do unset $X; done

## Desired outcome:
# Populated Variables: $DOMAIN and $REALM
