#! /bin/bash
# Script to define ANSI Escape Codes into Variables
# Peter Talbott


function initialize_color()
{
	export COLOR_NORMAL="\033[0m"
	export COLOR_BLACK="\033[0;30m"
	export COLOR_RED="\033[0;31m"
	export COLOR_GREEN="\033[0;32m"
	export COLOR_ORANGE="\033[0;33m"
	export COLOR_BLUE="\033[0;34m"
	export COLOR_PURPLE="\033[0;35m"
	export COLOR_CYAN="\033[0;36m"
	export COLOR_LT_GRAY="\033[0;37m"
	export COLOR_DK_GRAY="\033[1;30m"
	export COLOR_LT_RED="\033[1;31m"
	export COLOR_LT_GREEN="\033[1;32m"
        export COLOR_YELLOW="\033[1;33m"
        export COLOR_LT_BLUE="\033[1;34m"
        export COLOR_LT_PURPLE="\033[1;35m"
        export COLOR_LT_CYAN="\033[1;36m"
        export COLOR_WHITE="\033[1;37m"
};

function initialize_color_array()
{
   _PREFIX="\033["
   _SEMI=';'
   _C=-1
   for (( _A=0; $((_A)) < 2; _A++ ))
   do
	for (( _B=30; $((_B)) <= 37; _B++ ))
	do
	    (( _C++ ))
	    _TEMP="$_PREFIX$((_A))$_SEMI$((_B))m"
	    declare -ag COLOR_ARRAY[$((_C))]="$_TEMP"
	done
   done
};

# ---------------------------------------- #
#		ANSI Chart		   #
# ---------------------------------------- #
# Black        0;30     Dark Gray     1;30 #
# Red          0;31     Light Red     1;31 #
# Green        0;32     Light Green   1;32 #
# Brown/Orange 0;33     Yellow        1;33 #
# Blue         0;34     Light Blue    1;34 #
# Purple       0;35     Light Purple  1;35 #
# Cyan         0;36     Light Cyan    1;36 #
# Light Gray   0;37     White         1;37 #
# ---------------------------------------- #

