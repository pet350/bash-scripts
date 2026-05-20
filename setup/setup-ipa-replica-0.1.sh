#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
if [ -f /lib/lsb/init-functions ]; then
  source /lib/lsb/init-functions
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.5"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $FAILURE
fi

# Define Integer Variables
declare -ig SLEEP_TIME=2

export REALM="GIGAWARE.LAN"
export NETBIOS_DOMAIN="GIGAWARE"
export IPA_HOSTNAME="lxc.gigaware.lan"
export DNS_ZONE="gigaware.lan"
export REV_ZONE="184.16.172.in-addr.arpa."
export IPA_IP_ADDRESS="172.16.184.2"

# Define Binary Options
export RNDC_OPTIONS="-a -b 512"
declare -ag SERVER_OPTIONS=( "--setup-adtrust" "--setup-kra" "--setup-dns" "--enable-compat" "--mkhomedir" "--add-sids" \
 "--hostname=$IPA_HOSTNAME" "--domain=$DNS_ZONE" "--realm=$REALM" "--netbios-name=$NETBIOS_DOMAIN" "--server=ipa.gigaware.lan" \
 "--forwarder=8.8.8.8" "--forwarder=8.8.4.4" "--forwarder=4.2.2.2" "--force-join" "--no-host-dns" "--skip-schema-check" \
 "--allow-zone-overlap" "--reverse-zone=$REV_ZONE" "--no-dnssec-validation" "--skip-conncheck" "--setup-ca" "--add-agents" \
 "--ntp-pool=pool.ntp.org" "--admin-password=IronMaiden666" "--ip-address=$IPA_IP_ADDRESS" "--verbose" );

export USR_PREFIX="/usr"
export BIN_PREFIX="/bin"
export CFG_PREFIX="/etc"
export SBIN_PREFIX="/sbin"
export BIND_PREFIX="$CFG_PREFIX/bind"
export DHCP_PREFIX="$CFG_PREFIX/dhcp"

# Define Binary Variables
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export UPDATE_RC_BIN="$USR_PREFIX$SBIN_PREFIX/update-rc.d"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export IPA_SERVER_INSTALL_BIN="$USR_PREFIX$SBIN_PREFIX/ipa-replica-install"
export RNDC_CONFGEN_BIN="$USR_PREFIX$SBIN_PREFIX/rndc-confgen"
export RNDC_KEY="rndc.key"
export POLICY="grant $REALM krb5-self * A; grant $REALM krb5-self * AAAA; grant $REALM krb5-self * SSHFP; grant "rndc-key" zonesub ANY;"

$IPA_SERVER_INSTALL_BIN ${SERVER_OPTIONS[@]}
# $SLEEP_BIN $SLEEP_TIME

#$RNDC_CONFGEN_BIN $RNDC_OPTIONS
#if [ ! -d $BIND_PREFIX ]; then mkdir -p $BIND_PREFIX; fi
#if [ ! -d $DHCP_PREFIX ]; then mkdir -p $DHCP_PREFIX; fi
#$SLEEP_BIN $SLEEP_TIME

#if [ ! -f $BIND_PREFIX/$RNDC_KEY ]; then
#  cd $BIND_PREFIX
#  ln -s ../$RNDC_KEY
#fi

#if [ ! -f $DHCP_PREFIX/$RNDC_KEY ]; then
#  cd $DHCP_PREFIX
#  ln -s ../$RNDC_KEY
#fi

#kinit admin
#ipa dnszone-mod $DNS_ZONE --dynamic-update=True --update-policy="$POLICY"
#ipa dnszone-mod $REV_ZONE --dynamic-update=True --update-policy="$POLICY"
