#!/bin/bash

echo "TESTING INDIVIDUAL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p fuzz_kerberos -t nss -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p fuzz_kerberos -t pam-account -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p fuzz_kerberos -t pam-auth -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p fuzz_kerberos -t pam-password -n >> $ACCTMP/result 2>&1 && exit 1
$ACCPATH/usr/sbin/auth-client-config -p fuzz_kerberos -t pam-session -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p fuzz_kerberos -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
