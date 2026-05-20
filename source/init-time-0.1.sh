#! /bin/bash

declare -ig initTimeExists=1

# Defines Simple Named Variables For Diferent Time/Date Values
function initialize_time_date()
{
	export _DOW=$(date +%A)			# Define _DOW:		(Day Of Week ie: Saturday, Sunday, Monday,... Etc..)
        export _FULL_DATE=$(date +%F)		# Define _FULL_DATE:	(Full Date; same as %Y-%m-%d)
        export _SHORT_DATE=$(date +%D)		# Define _SHORT_DATE:	(Short Date; same as %m/%d/%y)
        export _YEAR=$(date +%Y)		# Define _YEAR:		(4 Digit Format: 2017, 2018, 2019,... etc...)
        export _MONTH_LONG=$(date +%B)		# Define _MONTH_LONG:	(Janyary, February, March,... etc...)
        export _MONTH_SHORT=$(date +%b)		# Define _MONTH_SHORT:	(Jan, Feb, Mar,... etc...)
        export _MONTH=$(date +%m)		# Define _MONTH:	(01, 02, 03, ... 12, etc...)
        export _DAY=$(date +%d)			# Define _DAY:		(02, 01, 03, ... 30, etc...)
        export _TZ=$(date +%Z)			# Define _TZ:		(Time Zone Abbreviation (e.g., EDT)
	export _NANO_SEC=$(date +%N)		# Define _NANOSEC:	(NanoSeconds 000000000..999999999)
	export _HOUR=$(date +%k)		# Define _Hour		(24 Hour Clock)
	export _MINUTE=$(date +%M)		# Define _MINUTE	(00..59)
	export _SECOND=$(date +%S)		# Define _SECOND	(00..59)
	return $_NANO_SEC
};

