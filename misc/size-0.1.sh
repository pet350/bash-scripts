#!/bin/bash


declare -a SIZE_ARRAY=();
declare -a NAME_ARRAY=();
declare -a SIZE_ARRAY_HR=();
declare -a NAME_ARRAY_HR=();


function GET_ARRAYS()
{
	declare -i INDEX=-1
	declare -i SIZE_INDEX=-1
	declare -i NAME_INDEX=-1
	declare -i REMAINDER=0

	# First loop store SIZE_ARRAY and NAME_ARRAY
	for DATA in $(du -s $TARGET_PREFIX/*); do
		((INDEX++))
		REMAINDER=$(( $INDEX % 2 ))
		if [ $REMAINDER -eq 0 ]; then
			((SIZE_INDEX++))
			SIZE_ARRAY[$((SIZE_INDEX))]="$DATA"
		else
			((NAME_INDEX++))
			NAME_ARRAY[$((NAME_INDEX))]="$DATA"
		fi
	done
        declare -i INDEX=-1
        declare -i SIZE_INDEX=-1
        declare -i NAME_INDEX=-1

	# Second loop store SIZE_ARRAY_HR (Human Readable) and NAME_ARRAY_HR (Human Readable)
        for DATA in $(du -sh $TARGET_PREFIX/*); do
                ((INDEX++))
                REMAINDER=$(( $INDEX % 2 ))
                if [ $REMAINDER -eq 0 ]; then
                        ((SIZE_INDEX++))
                        SIZE_ARRAY_HR[$((SIZE_INDEX))]="$DATA"
                else
                        ((NAME_INDEX++))
                        NAME_ARRAY_HR[$((NAME_INDEX))]="$DATA"
                fi
        done
	return $SUCCESS
};


function GET_NEXT_HIGHEST()
{
        if [ ${#TEMP_HIGH} -eq 0 ]; then declare -i TEMP_HIGH=0; fi
	if [ ${#HIGHEST}   -eq 0 ]; then declare -i HIGHEST=$(GET_HIGHEST); fi
        for NESTED_DATA in ${SIZE_ARRAY[@]}; do
                if [ $NESTED_DATA -lt $HIGHEST ] && [ $NESTED_DATA -gt $((TEMP_HIGH+1)) ]; then
			TEMP_HIGH=$NESTED_DATA
		fi
        done
        echo $TEMP_HIGH
        return $SUCCESS
};

function GET_HIGHEST()
{
	declare -i TEMP_HI=0

	for NESTED_DATA in ${SIZE_ARRAY[@]}; do
		if [ $NESTED_DATA -gt $TEMP_HI ]; then export TEMP_HI=$NESTED_DATA;	fi
	done
	echo $TEMP_HI
	return $SUCCESS
};

function SORT_ARRAY()
{
	declare -i HIGHEST=$(GET_HIGHEST)

	for DATA in ${SIZE_ARRAY[@]}; do
		export HIGHEST=$(GET_NEXT_HIGHEST)
		echo $HIGHEST
		export TEMP_HIGH=$HIGHEST
	done
};



GET_ARRAYS
SORT_ARRAY


