#!/bin/bash
# Very simple script to print the public IP address
DATA=$(curl https://www.google.com/search?q=what+is+my+ip 2>/dev/null|grep 'Client IP address:'|tail --bytes=45|head --bytes=36)
DATA="${DATA#*address:}"
DATA="${DATA%)*}"

echo -e $DATA
