#!/bin/bash

export SERVER_FQDN="www.gigaware.lan"
export SERVER_PORT="3142"

echo "Acquire::http::Proxy \"http://$SERVER_FQDN:$SERVER_PORT\";" | tee /etc/apt/apt.conf.d/00-proxy
apt-get update

