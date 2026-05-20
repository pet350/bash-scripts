#!/bin/bash
# Will Attempt To Find and Kill Any Process Containing "Unison"

EXIT_VAL=1
while IFS= read -r line; do
  index=-1
  for DATA in $line; do
    ((index++))
    if [ $index -eq 0 ]; then
      echo -e "PID: $DATA"
      kill $DATA
      EXIT_VAL=$?
    fi
  done
done< <(ps -ax | grep Unison)
exit $EXIT_VAL
