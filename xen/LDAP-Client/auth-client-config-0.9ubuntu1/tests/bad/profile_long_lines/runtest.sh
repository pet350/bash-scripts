#!/bin/bash

#set -x

total=0

# create a long line
echo -n -e "\tsession optional        pam_foreground.so # " >> $ACCPATH/etc/auth-client-config/profile.d/long_lines

while [ $total -lt 4096 ] && [ -f "$ACCPATH/etc/auth-client-config/profile.d/long_lines" ]
do
	echo -n "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" >> $ACCPATH/etc/auth-client-config/profile.d/long_lines
	total=`stat --format='%s' $ACCPATH/etc/auth-client-config/profile.d/long_lines`
done
echo "" >> $ACCPATH/etc/auth-client-config/profile.d/long_lines

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p local_example -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
