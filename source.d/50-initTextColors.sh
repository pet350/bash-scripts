#!/bin/bash
# Script to define ANSI Escape Codes into Variables
# Peter Talbott

# This function will initialize color variables as ANSI escape codes
function INIT_COLOR()
{
  declare -i FUNCTION_RETURN=$FAILURE
  if [ $BOL_FORCE_COLOR -eq $TRUE ]; then
    export TEMP_TERM="$TERM"
    export TERM="xterm-color"
  fi
  # Only enable if terminal supports color
  case $TERM in
    'xterm-256color' | 'xterm-color')
      export COLOR_SUPPORT=$TRUE
      export FUNCTION_RETURN=$SUCCESS
      if [ ${#COLOR_NORMAL}	-eq 0 ];	then    export COLOR_NORMAL="\033[0m";		fi
      if [ ${#COLOR_BLACK}	-eq 0 ];        then    export COLOR_BLACK="\033[0;30m";	fi
      if [ ${#COLOR_RED}	-eq 0 ];        then    export COLOR_RED="\033[0;31m";		fi
      if [ ${#COLOR_GREEN}	-eq 0 ];        then    export COLOR_GREEN="\033[0;32m";	fi
      if [ ${#COLOR_ORANGE}     -eq 0 ];        then    export COLOR_ORANGE="\033[0;33m";	fi
      if [ ${#COLOR_BLUE}	-eq 0 ];        then    export COLOR_BLUE="\033[0;34m";		fi
      if [ ${#COLOR_PURPLE}     -eq 0 ];        then    export COLOR_PURPLE="\033[0;35m";	fi
      if [ ${#COLOR_CYAN}	-eq 0 ];        then    export COLOR_CYAN="\033[0;36m";		fi
      if [ ${#COLOR_LT_GRAY}	-eq 0 ];        then    export COLOR_LT_GRAY="\033[0;37m";	fi
      if [ ${#COLOR_DK_GRAY}	-eq 0 ];        then    export COLOR_DK_GRAY="\033[1;30m";	fi
      if [ ${#COLOR_LT_RED}     -eq 0 ];        then    export COLOR_LT_RED="\033[1;31m";	fi
      if [ ${#COLOR_LT_GREEN}	-eq 0 ];        then    export COLOR_LT_GREEN="\033[1;32m";	fi
      if [ ${#COLOR_YELLOW}     -eq 0 ];        then    export COLOR_YELLOW="\033[1;33m";	fi
      if [ ${#COLOR_LT_BLUE}	-eq 0 ];        then    export COLOR_LT_BLUE="\033[1;34m";	fi
      if [ ${#COLOR_LT_PURPLE}	-eq 0 ];        then    export COLOR_LT_PURPLE="\033[1;35m";	fi
      if [ ${#COLOR_LT_CYAN}	-eq 0 ];        then    export COLOR_LT_CYAN="\033[1;36m";	fi
      if [ ${#COLOR_WHITE}	-eq 0 ];        then    export COLOR_WHITE="\033[1;37m";	fi
      if [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_DEBUG -eq $TRUE ] && [ $BOL_QUIET -eq $FALSE ]; then echo -e $COLOR_LT_BLUE"Enabling "$COLOR_YELLOW"Colorized Text Output"$COLOR_NORMAL; fi
      ;;
    *)
      export	COLOR_SUPPORT=$FALSE
      export	FUNCTION_RETURN=$FAILURE
      unset	COLOR_NORMAL
      unset	COLOR_BLACK
      unset	COLOR_RED
      unset	COLOR_GREEN
      unset	COLOR_ORANGE
      unset	COLOR_BLUE
      unset	COLOR_PURPLE
      unset	COLOR_CYAN
      unset	COLOR_LT_GRAY
      unset	COLOR_DK_GRAY
      unset	COLOR_LT_RED
      unset	COLOR_LT_GREEN
      unset	COLOR_YELLOW
      unset	COLOR_LT_BLUE
      unset	COLOR_LT_PURPLE
      unset	COLOR_LT_CYAN
      unset	COLOR_WHITE
      ;;
  esac
  if [ $BOL_FORCE_COLOR -eq $TRUE ]; then
    export TERM="$TEMP_TERM"
    unset TEMP_TERM
  fi
  return $FUNCTION_RETURN
};

function INIT_COLOR_SHORTHAND()
{
  if [ ${#COLOR_SUPPORT}	-eq 0 ]; then INIT_COLOR; fi
  if [ ${#COLOR_NORMAL}         -ne 0 ]; then export CN="$COLOR_NORMAL";        else unset CN;     fi
  if [ ${#COLOR_BLACK}          -ne 0 ]; then export CK="$COLOR_BLACK";         else unset CK;     fi
  if [ ${#COLOR_RED}            -ne 0 ]; then export CR="$COLOR_RED";           else unset CR;     fi
  if [ ${#COLOR_GREEN}          -ne 0 ]; then export CG="$COLOR_GREEN";         else unset CG;     fi
  if [ ${#COLOR_ORANGE}         -ne 0 ]; then export CO="$COLOR_ORANGE";        else unset CO;     fi
  if [ ${#COLOR_BLUE}           -ne 0 ]; then export CB="$COLOR_BLUE";          else unset CB;     fi
  if [ ${#COLOR_PURPLE}         -ne 0 ]; then export CP="$COLOR_PURPLE";        else unset CP;     fi
  if [ ${#COLOR_CYAN}           -ne 0 ]; then export CC="$COLOR_CYAN";          else unset CC;     fi
  if [ ${#COLOR_YELLOW}		-ne 0 ]; then export CY="$COLOR_YELLOW";	else unset CY;	   fi
  if [ ${#COLOR_WHITE}          -ne 0 ]; then export CW="$COLOR_WHITE";         else unset CW;     fi
  if [ ${#COLOR_LT_GRAY}        -ne 0 ]; then export CLA="$COLOR_LT_GRAY";      else unset CLA;    fi
  if [ ${#COLOR_LT_RED}         -ne 0 ]; then export CLR="$COLOR_LT_RED";       else unset CLR;    fi
  if [ ${#COLOR_LT_PURPLE}      -ne 0 ]; then export CLP="$COLOR_LT_PURPLE";    else unset CLP;    fi
  if [ ${#COLOR_LT_CYAN}        -ne 0 ]; then export CLC="$COLOR_LT_CYAN";      else unset CLC;    fi
  if [ ${#COLOR_LT_BLUE}	-ne 0 ]; then export CLB="$COLOR_LT_BLUE";	else unset CLB;	   fi
  if [ ${#COLOR_LT_GREEN}	-ne 0 ]; then export CLG="$COLOR_LT_GREEN";	else unset CLG;	   fi
  if [ ${#COLOR_DK_GRAY}        -ne 0 ]; then export CDA="$COLOR_DK_GRAY";      else unset CDA;    fi
  return $SUCCESS
};


function CHECK_COLOR_SUPPORT()
{
  declare -i FUNCTION_RETURN=$FAILURE
  if [ ${#COLOR_SUPPORT} -ne 0 ]; then
    if [ $COLOR_SUPPORT -eq $TRUE ]; then FUNCTION_RETURN=$SUCCESS; fi
  fi
  return $FUNCTION_RETURN
};

# Functions for changing text color a lot easier!
function CN_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CN;  return $SUCCESS; };
function CK_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CK;  return $SUCCESS; };
function CR_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CR;  return $SUCCESS; };
function CG_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CG;  return $SUCCESS; };
function CO_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CO;  return $SUCCESS; };
function CB_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CB;  return $SUCCESS; };
function CP_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CP;  return $SUCCESS; };
function CC_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CC;  return $SUCCESS; };
function CY_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CY;  return $SUCCESS; };
function CW_TEXT()  { INIT_COLOR_SHORTHAND; printf "%b" $CW;  return $SUCCESS; };
function CLA_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLA; return $SUCCESS; };
function CLR_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLR; return $SUCCESS; };
function CLP_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLP; return $SUCCESS; };
function CLC_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLC; return $SUCCESS; };
function CLB_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLB; return $SUCCESS; };
function CLG_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CLG; return $SUCCESS; };
function CDA_TEXT() { INIT_COLOR_SHORTHAND; printf "%b" $CDA; return $SUCCESS; };

