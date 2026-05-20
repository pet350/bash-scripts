#!/bin/bash
# global-booleans.sh
# Version 0.2
# Peter Talbott

# Simple Shell Script To Define Global Boolean Variables
# Revised 2020-07-21 PDT

# Define TRUE/FALSE Variables
if [ ${#TRUE}		 -eq 0 ];	then	declare -ig TRUE=1;			fi
if [ ${#FALSE}		 -eq 0 ];	then	declare -ig FALSE=0;			fi

# Define SUCCESS/FAILURE Variables
if [ ${#SUCCESS}	 -eq 0 ];	then	declare -ig SUCCESS=0;			fi
if [ ${#FAIL}		 -eq 0 ];	then	declare -ig FAIL=1;			fi
if [ ${#FAILURE}	 -eq 0 ];	then	declare -ig FAILURE=1;			fi

# Define UP and DOWN
if [ ${#UP}		 -eq 0 ];	then	declare -ig UP=1;			fi
if [ ${#DOWN}		 -eq 0 ];	then	declare -ig DOWN=0;			fi

# Define Global Boolean Variables if they don't already exist
if [ ${#BOL_VERBOSE}	 -eq 0 ];	then 	declare -ig BOL_VERBOSE=$FALSE;		fi
if [ ${#BOL_QUIET}	 -eq 0 ];	then	declare -ig BOL_QUIET=$FALSE; 		fi
if [ ${#BOL_HELP}	 -eq 0 ];	then	declare -ig BOL_HELP=$FALSE;		fi
if [ ${#BOL_TEMP}	 -eq 0 ];	then	declare -ig BOL_TEMP=$FALSE;		fi
if [ ${#BOL_DEBUG}	 -eq 0 ];	then	declare -ig BOL_DEBUG=$FALSE;		fi
if [ ${#BOL_WAIT}	 -eq 0 ];	then	declare -ig BOL_WAIT=$TRUE;		fi
if [ ${#BOL_LOG_RESULTS} -eq 0 ];	then	declare -ig BOL_LOG_RESULTS=$TRUE;	fi
if [ ${#BOL_COLOR}	 -eq 0 ];	then	declare -ig BOL_COLOR=$TRUE;		fi
if [ ${#BOL_FORCE_COLOR} -eq 0 ];	then    declare -ig BOL_FORCE_COLOR=$FALSE;     fi

# Define Global SYSCTL Boolean Variables
if [ ${#BOL_START}	 -eq 0 ];	then	declare -ig BOL_START=$FALSE;		fi
if [ ${#BOL_STOP}	 -eq 0 ];	then	declare -ig BOL_STOP=$FALSE;		fi
if [ ${#BOL_RESTART}	 -eq 0 ];	then	declare -ig BOL_RESTART=$FALSE;		fi
if [ ${#BOL_RELOAD}	 -eq 0 ];	then	declare -ig BOL_RELOAD=$FALSE;		fi
if [ ${#BOL_STATUS}	 -eq 0 ];	then	declare -ig BOL_STATUS=$FALSE;		fi
if [ ${#BOL_MASK}	 -eq 0 ];	then	declare -ig BOL_MASK=$FALSE;		fi
if [ ${#BOL_UNMASK}	 -eq 0 ];	then	declare -ig BOL_UNMASK=$FALSE;		fi
if [ ${#BOL_ENABLE}	 -eq 0 ];	then	declare -ig BOL_ENABLE=$FALSE;		fi
if [ ${#BOL_DISABLE}	 -eq 0 ];	then	declare -ig BOL_DISABLE=$FALSE;		fi
