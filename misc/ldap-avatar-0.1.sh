#!/bin/bash
# Script Source: https://www.dalemacartney.com/2013/12/05/loading-display-picturesavatars-red-hat-idmfreeipa-gnome3/
server=$(dig -t soa $(hostname --domain) | grep -A1 "ANSWER SECTION:" | grep -v "ANSWER" | cut -f 6 | cut -d. -f1 )
server=$(echo $server | sed "s/$/.$(hostname --domain)/g")
image=$(ldapsearch -LLL -h $server -p 389 -x uid=$(whoami) jpegPhoto -t | grep jpegPhoto| cut -d: -f3)
mv $image $HOME/.face
chmod 644 $HOME/.face
echo "Icon=$HOME/.face" >> /var/lib/AccountsService/users/$(whoami)
