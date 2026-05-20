#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t nss -r -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-account -r -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-auth -r -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-password -r -n >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-session -r -n >> $ACCTMP/result || exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p ldap -r -n >> $ACCTMP/result || exit 1

echo "TESTING INDIVIDUAL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p ldap -t nss -r -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p ldap -t pam-account -r -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p ldap -t pam-auth -r -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p ldap -t pam-password -r -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -d -p ldap -t pam-session -r -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL (dbonly)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -d -a -p ldap -r -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
