#!/bin/bash
# global-booleans.sh
# Version 0.1
# Peter Talbott

# Simple Shell Script To Define Global Boolean Variables

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define Standard Return Values
declare -ig SUCCESS=0
declare -ig FAILURE=1
declare -ig CONDITION_NOT_MET=255

declare -ig initTimeExists=$FALSE

