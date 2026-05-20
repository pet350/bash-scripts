#!/bin/bash
# Function to obtain current working directory
# By : Peter Talbott

function GET_CURRENT_DIR()
{
  # This was my origonal code
  # printf "%s" $(pwd -L)

  # This update works at time path and time of bash launch :
  printf "%s" $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
  return $?
};

# Example of use:
# export WORKING_DIR=$(GET_CURRENT_DIR)
