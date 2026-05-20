#! /bin/bash
# Color Test Bash Script

# Load Functions Defined in another Script I wrote
# source /usr/lib/bash/TextColors.sh

_SOURCE_ROOT="/usr/local/scripts"
_SOURCE_FILE="TextColors.sh"

source "$_SOURCE_ROOT/$_SOURCE_FILE"

# Run These Pre-Defined Functions
initialize_color
initialize_color_array

# The 'initialize_color' function defines named
# Color Variables. Example Below
echo -e "$COLOR_RED Red"
echo -e "$COLOR_GREEN Green"
echo -e "$COLOR_BLUE Blue"

# The 'initialize_color_arry' function defines
# a COLOR_ARRAY[x] Variable. Example Below
for (( _BB=0; $((_BB)) <= 15; _BB++ ))
do
	echo -e "${COLOR_ARRAY[$((_BB))]} $((_BB))"
done

# Thats all Folks!
