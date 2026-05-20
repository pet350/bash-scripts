#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p kerberos -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p kerberos -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p kerberos -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p kerberos -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p kerberos -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -a -p kerberos -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING INDIVIDUAL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p kerberos -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p kerberos -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p kerberos -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p kerberos -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p kerberos -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -a -p kerberos -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
