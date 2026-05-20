#!/bin/bash

PORT_LIST="ttyS0 ttyS1 ttyS2 ttyS3 ttyS4 ttyS5 ttyS6 ttyS7"

if [ ${#1} -gt 0 ]; then
  MAX_COUNT=$1
else
  MAX_COUNT=-1
fi
COUNT=0

function SHOW_PORTS()
{
  printf "%-8s    %-14s  %-13s  %-19s %-14s\n" "Com Port" "Data Set Ready" "Clear To Send" "Data Carrier Detect" "Ring Indicator"
  for PORT in $PORT_LIST; do
    printf "/dev/%s\t" $PORT
    for SIGNAL in DSR CTS DCD RI; do
      printf "%s:%s\t\t" $SIGNAL $(/usr/bin/GetSerialSignal /dev/$PORT $SIGNAL)
      RETVAL=$?
    done
    printf "\n"
  done
  return $RETVAL
};

while [ $COUNT -ne $MAX_COUNT ]; do
  ((COUNT++))
  clear
  SHOW_PORTS
  EXIT_VAL=$?
  sleep 1
done

printf "\n"
exit $EXIT_VAL

