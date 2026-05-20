#!/bin/bash

if [ ${#GOROOT}	-eq 0 ]; then export GOROOT="/usr/local/go";	fi
if [ -d "$GOROOT" ]; then
  export PATH="$GOROOT/bin:$PATH"
else
  unset GOROOT
fi