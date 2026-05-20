#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t nss -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-account -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-auth -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-password -n >> $ACCTMP/result 2>&1 || exit 1
$ACCPATH/usr/sbin/auth-client-config -p ldap -t pam-session -n >> $ACCTMP/result 2>&1 || exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p ldap -n >> $ACCTMP/result 2>&1 || exit 1

exit 0
