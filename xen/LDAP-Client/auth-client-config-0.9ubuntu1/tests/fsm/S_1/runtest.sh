#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-account -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-auth -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-password -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t pam-session -n >> $ACCTMP/result || exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p kerberos -n >> $ACCTMP/result || exit 1

echo "TESTING INDIVIDUAL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p kerberos -t nss -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p kerberos -t pam-account -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p kerberos -t pam-auth -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p kerberos -t pam-password -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p kerberos -t pam-session -n >> $ACCTMP/result || exit 1

echo "TESTING ALL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -a -p kerberos -n >> $ACCTMP/result || exit 1

exit 0
