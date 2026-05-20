#!/bin/sh

for DATA in $(cat list.txt); do
  youtube-dl -f 140 "$DATA"
  if [ $? -ne 0 ]; then echo -e "Error with: $DATA"; echo "$DATA" >>error.log; fi
done

for DATA in $(cat error.log); do
  youtube-dl -f 251 "$DATA"
  if [ $? -ne 0 ]; then echo -e "Error with: $DATA"; echo "$DATA" >>error2.log; fi
done
