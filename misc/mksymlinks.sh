#!/bin/bash

function RESULTS()
{
  if [ $1 -eq 0 ]; then
	echo -e "Success!"
  else
	echo -e "Failure!"
  fi
  return $1
};

function CHECKDIFF()
{
    FULL="$1"
    CHOP="$2"

    printf "Compairing: "
    diff "$FULL" "$CHOP" >/dev/null 2>/dev/null
    RV=$?

    if  [ $RV -eq 0 ]; then
	printf "Same"
    else
	printf "Differ"
    fi
    return $RV
};

function CREATE_SYMLINK()
{
    FULL="$1"
    CHOP="$2"

    printf "Removing: %-50s" "$CHOP"
    rm -f "$CHOP" >/dev/null 2>/dev/null
    RESULTS $?

    printf "Creating Symlink\nfrom: $-50s\nto:  %-50s" "$FULL" "$CHOP"
    ln -s "$FULL" "$CHOP" >/dev/null 2>/dev/null
    RESULTS $?

    return $?
};


while IFS= read LINE; do
  TMP_NAME="${LINE%*-[0,,9].[1.99].sh}.sh"
  echo -e "Filename:\t$LINE"
  echo -e "Stripped:\t$TMP_NAME"
  CHECKDIFF "$LINE" "$TMP_NAME"
  RV=$?
  if [ $RV -eq 0 ]; then
	CREATE_SYMLINK  "$LINE" "$TMP_NAME"
  else
	echo -e "Files Difer, not creating Symlink"
  fi
  echo -e "-----------------------\n\n"
done < <(find -iname '*-[0,,9].[1.99].sh')
