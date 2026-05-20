#!/bin/sh

WAIT_TIME=1

dnf clean all
dnf makecache

sleep $WAIT_TIME

dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sleep $WAIT_TIME

dnf groupupdate -y core

sleep $WAIT_TIME

dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

sleep $WAIT_TIME

dnf groupupdate -y sound-and-video

sleep $WAIT_TIME

dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

sleep $WAIT_TIME

dnf install -y libdvdcss \*-firmware --skip-broken

sleep $WAIT_TIME

dnf makecache
dnf update -y

