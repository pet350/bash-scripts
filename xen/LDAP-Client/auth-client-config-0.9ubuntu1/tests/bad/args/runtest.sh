#!/bin/bash

echo "TESTING ARGS (-a with -t)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -a -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (no -p)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -t nss -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (no -a or -t)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-t without arg)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-f without arg)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -f -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-f with non-existent)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -f non-existent -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-f with long path)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -f "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.toolong" -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-a with -f)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -a -f $ACCPATH/orig/nsswitch.conf -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (invalid args)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -a -Z -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ARGS (-t with commas)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-auth, >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t ,pam-password >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-auth,,pam_password >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-auth,pam-foo >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-foo,pam-password >> $ACCTMP/result 2>&1 && exit 1

exit 0
