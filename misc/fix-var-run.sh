#!/bin/bash
# Simple Script to change '/var/run' to '/run' in systemd files

for X in $(ls -Nd1 /{lib,etc}/systemd/system/*.{service,socket}); do
  printf "Checking %s: " $X
  sed -i 's+/var/run+/run+g' "$X"
  if [ $? -eq 0 ]; then
    printf "Patched!\n"
  else
    printf "No need to patch!\n"
  fi
done
