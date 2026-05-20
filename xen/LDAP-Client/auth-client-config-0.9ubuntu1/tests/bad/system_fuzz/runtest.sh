#!/bin/bash

echo "TESTING ALL" >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -a -p kerberos -n >> $ACCTMP/result 2>&1 || exit 1

exit 0
