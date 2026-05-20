#!/bin/bash

declare -ag PACKAGE_ARRAY=();
declare -ag INSTALLED_PACKAGE_ARRAY=();
declare -ag NOT_INSTALLED_PACKAGE_ARRAY=();

function GET_ALL_PACKAGES()
{
  COUNT=-1
  while IFS= read LINE; do
    INDEX=-1
    for DATA in $LINE; do
      ((INDEX++))
      if [ $INDEX -eq 0 ]; then
        PACKAGE="${DATA%/*}"
        ((COUNT++))
        PACKAGE_ARRAY[$((COUNT))]="$PACKAGE"
        #echo -e "$PACKAGE"
      fi
    done
  done < <(apt list 2>/dev/null 3>/dev/null)
};

function GET_INSTALLED_PACKAGES()
{
  COUNT=-1
  while IFS= read LINE; do
    INDEX=-1
    for DATA in $LINE; do
      ((INDEX++))
      if [ $INDEX -eq 0 ]; then
        PACKAGE="${DATA%/*}"
        ((COUNT++))
        INSTALLED_PACKAGE_ARRAY[$((COUNT))]="$PACKAGE"
        #echo -e "$PACKAGE"
      fi
    done
  done < <(apt list --installed 2>/dev/null 3>/dev/null)
};

function GET_NOT_INSTALLED_PACKAGES()
{
  COUNT=-1
  LOGFILE="/tmp/not_installed.txt"

  echo '' >$LOGFILE
  for ALL in ${PACKAGE_ARRAY[@]}; do
    BOOLEAN=$FALSE
    for INSTALLED in ${INSTALLED_PACKAGE_ARRAY[@]}; do
      if [ "$ALL" == "$INSTALLED" ] || [ $BOOLEAN -eq $TRUE ]; then BOOLEAN=$TRUE; fi
    done
    if [ $BOOLEAN -eq $FALSE ]; then
      ((COUNT++))
      NOT_INSTALLED_PACKAGE_ARRAY[$((COUNT))]="$ALL"
      printf "%-6s %s\n" $COUNT $ALL | tee -a $LOGFILE
    fi
  done
};

printf "Gatting a list of all available packages in repositories.... "
GET_ALL_PACKAGES
printf "%s total packages\n" ${#PACKAGE_ARRAY[@]}

printf "Getting a list of installed packages.... "
GET_INSTALLED_PACKAGES
printf "%s installed packages\n" ${#INSTALLED_PACKAGE_ARRAY[@]}

echo -e "Compairing lists"
GET_NOT_INSTALLED_PACKAGES

for DATA in ${NOT_INSTALLED_PACKAGE_ARRAY[@]}; do
  echo -e "$DATA"
done
