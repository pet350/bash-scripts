#!/bin/bash

# Little function to list just the package name from zypper search
function lszypp()
{
  LI=-1
  WI=-1
  while IFS= read LINE; do
    ((LI++))
    WI=-1
    for WORD in $LINE; do
      ((WI++))
      if [ $LI -gt 0 ] && [ $WI -gt 0 ] && [ $WI -lt 2 ]; then
        case $WORD in
          '|'|'i'|'installed'|'repository'|'Repository') /bin/true;;
          *) echo $WORD;;
        esac
      fi
    done
  done < <(zypper search $@ 2>/dev/null; RET=$?)
  return $RET
};

