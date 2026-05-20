#!/bin/bash

echo "TESTING INDIVIDUAL (update)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -p kerberos -t nss -n >> $ACCTMP/result 2>&1 || exit 1

echo "TESTING ALL (update)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p kerberos -n >> $ACCTMP/result 2>&1 || exit 1

echo "TESTING INDIVIDUAL (reset)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -p ldap -t nss -n >> $ACCTMP/result 2>&1 && exit 1

echo "TESTING ALL (reset)" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -r -a -p ldap -n >> $ACCTMP/result 2>&1 && exit 1

exit 0
