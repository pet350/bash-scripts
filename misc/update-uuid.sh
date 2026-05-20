#!/bin/bash

TEMP_FILE="/tmp/TEMP-UUID"

printf "\n%s %c%s%c\n" "uuid =" '"' "$(uuid)" '"' >$TEMP_FILE
echo "" >>$1
cat $TEMP_FILE >>$1


