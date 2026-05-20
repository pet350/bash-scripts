#!/bin/bash

#set -x

# create a large file
total=0
touch $ACCPATH/etc/auth-client-config/profile.d/big1
touch $ACCPATH/etc/auth-client-config/profile.d/big2
while [ $total -lt $((10*1024*1024 + 1)) ] && [ -f "$ACCPATH/etc/auth-client-config/profile.d/acc-default" ]
do
	cat $ACCPATH/etc/auth-client-config/profile.d/acc-default | sed "s/kerberos/$total/g" >> $ACCPATH/etc/auth-client-config/profile.d/big1
	cp -f $ACCPATH/etc/auth-client-config/profile.d/big1 $ACCPATH/etc/auth-client-config/profile.d/big2
	cat $ACCPATH/etc/auth-client-config/profile.d/big2 >> $ACCPATH/etc/auth-client-config/profile.d/big1
	total=`stat --format='%s' $ACCPATH/etc/auth-client-config/profile.d/big1`
done
rm -f $ACCPATH/etc/auth-client-config/profile.d/big2

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p 0 -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p 0 -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p 0 -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p 0 -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p 0 -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p 0 -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
