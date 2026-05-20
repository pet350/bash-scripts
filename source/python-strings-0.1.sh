#!/bin/bash
# python-strings.sh
# Version 0.1
# Peter Talbott
# Simple shell script to define string values

export DEB_LDFLAGS_MAINT_APPEND="-Wl,--as-needed"
if [ -f /usr/bin/pyversions ]; then export PYVERS="$(/usr/bin/pyversions -d)"; fi
if [ -f /usr/bin/dpkg-architecture ]; then export HOST_ARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"; fi
if [ -f /usr/bin/pkg-config ]; then export LDB_VERSION="$(pkg-config --modversion ldb)"; fi
