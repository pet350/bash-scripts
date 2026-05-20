#!/bin/bash
# snap-path.sh
# Version 0.1
# Peter Talbott

# Simple script to add /snap/bin to the path if it exists
if [ -d /snap/bin ]; then
  PATH="$PATH:/snap/bin"
fi
