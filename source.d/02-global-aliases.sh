#!/bin/bash
# global-aliases.sh
# Version 0.1
# Peter Talbott

# Simple script to define Aliases I use all the time

case "${BASH_VERSINFO[5],,}" in
  x86_64-openwrt-linux-gnu)
    # Script IS running on OpenWRT Hardware (or VM)
    ;;
  *)
    # Script is NOT running on OpenWRT Hardware (or VM)
    export NANO_BAK_PREFIX="/tmp/.nano"
    export NANO_BAK_DIR="$NANO_BAK_PREFIX/$(whoami)@$(/bin/hostname -s)"

    if [ ! -d $NANO_BAK_PREFIX ]; then
      mkdir -p $NANO_BAK_PREFIX
      chmod 1777 $NANO_BAK_PREFIX
    fi

    if [ ! -d $NANO_BAK_DIR ]; then
      mkdir -p $NANO_BAK_DIR
      chmod 0750 $NANO_BAK_DIR
    fi

    alias nano="nano --multibuffer --nonewlines --nowrap --showcursor --constantshow --backup --backupdir=$NANO_BAK_DIR"
    alias cp="cp --preserve=all"
    alias vsh="virsh -c lxc:///system"
    alias vlxc="virsh -c lxc:///system"
    alias vqemu="virsh -c qemu:///system"
    alias virshq="virsh -c qemu:///system"
    alias virshl="virsh -c lxc:///system"
    alias virshx="virsh -c xen:///system"
    unset NANO_BAK_DIR
    unset NANO_BAK_PREFIX
    ;;
esac

# Define Aliases Reguardless of what it is running on
alias dh="df -h"
alias dush="du -sh"
alias mem="free -h"
alias ls="ls --color=auto"
alias edlin="/usr/bin/nano"
alias lh="ls -lh"
alias ping="ping -c 4"
alias md="mkdir -p"
alias rd="rmdir"
alias be="batchx264.sh --no-rename --copy-audio --debug --verbose"
alias rscp="rsync -ave ssh"
alias cons="Console.sh --force --verbose"

# End of 'alias' definisions
