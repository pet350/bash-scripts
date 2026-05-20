#!/bin/bash
# global-strings.sh
# Version 0.1
# Peter Talbott
# Simple shell script to define string values

# Define Standard Prefixes
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export LIB_PREFIX="/lib"
export DATA_PREFIX="/var"
export OPTIONAL_PREFIX="/opt"
export CFG_PREFIX="/etc"

# Define Executable Binaries
export APT_BIN="$USER_PREFIX$BIN_PREFIX/apt"
export FALSE_BIN="$BIN_PREFIX/false"
export GREP_BIN="$BIN_PREFIX/grep"
export LSMOD_BIN="$BIN_PREFIX/lsmod"
export MODPROBE_BIN="$SBIN_PREFIX/modprobe"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export SYSCTL_BIN="$BIN_PREFIX/systemctl"

# Define Misc String Values
export KERNEL=$(/bin/uname -r)

# Build Specific Strings
export LC_ALL=en_US.UTF-8
