#!/bin/bash

function GETSUM()
{
   for C in $(/nfs/rodc/usr/local/sbin/postsum --get --file="$1" --bw); do
    if [ ${#C} -gt 127 ]; then
      echo $C
    fi
  done
};


while IFS= read FILE_A; do
  case ${FILE_A:0:2} in
    './')
        FILE_A=${FILE_A#*./}
        ;;
  esac
  INDEX=-1
  for TEMP in $(sha512sum "$FILE_A"); do
    ((INDEX++))
    if [ $INDEX -eq 0 ]; then
      SUM_A=$TEMP
    fi
  done
  printf "File: %s: " $FILE_A
  SUM_B=$(GETSUM "$FILE_A")
  if [ "$SUM_A" == "$SUM_B" ]; then
	printf "Checksum matches!\n"
  else
	printf "Checksum Differs!\n"
        printf "A: %s\n" $SUM_A
        printf "B: %s\n" $SUM_B
  fi
done < <(find $@)
