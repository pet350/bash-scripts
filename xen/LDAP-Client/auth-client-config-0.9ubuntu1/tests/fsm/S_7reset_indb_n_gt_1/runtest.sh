#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t pam-account -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t pam-auth -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t pam-password -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t pam-session -n >> $ACCTMP/result 2>&1 || exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -a -p ldap -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING INDIVIDUAL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p ldap -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p ldap -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p ldap -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p ldap -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -p ldap -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -d -a -p ldap -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
