#!/bin/bash
# Script To Test Functions Stored In pkg-tools.sh
# By: Peter Talbott


source /usr/local/src/pkg-tools.sh

BOL_ShowIndex=$FALSE
BOL_WriteIndex=$FALSE

echo -e "BOL_ShowIndex: $BOL_ShowIndex"
echo -e "BOL_WriteIndex: $BOL_WriteIndex\n"

ShowPackageListArray
ShowAptPackageListArray
StoreLists
