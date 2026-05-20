#!/bin/bash

#set -x

# do this here, because install will put it in here
rm -f $ACCPATH/etc/auth-client-config/profile.d/acc-default

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p kerberos -n >> $ACCTMP/result 2>&1 && exit 1

sed -i "s/^WARNING: 'acc-default' not found .*/WARNING: 'acc-default' not found/" $ACCTMP/result

exit 0
