#!/bin/bash

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
  for DATA in realm head tail curl ldapadd ldapmodify ldapsearch  egrep chown sleep find; do
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

  if [ ${#DOMAIN}	-eq 0 ]; then declare -x DOMAIN=$($REALM_BIN discover 2>/dev/null | $HEAD_BIN --lines=1);	fi
  if [ ${#DOMAIN}	-eq 0 ]; then declare -x DOMAIN="gigaware.lan";							fi
  if [ ${#REALM}	-eq 0 ]; then declare -x REALM=${DOMAIN^^};							fi
  if [ ${#NB_DOMAIN}	-eq 0 ]; then declare -x NB_DOMAIN=${REALM%%.*};						fi
fi

for X in LINE_INDEX BOL_FUNCTION TEMP LINE WORD DATA TEMP_BIN; do unset $X; done

## Desired outcome:
# Populated Variables: $DOMAIN and $REALM
