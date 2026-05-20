#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

# Define some static variables
export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-12-05"
export WORKING_PREFIX="$(pwd)"

declare -i RETVAL=$SUCCESS

# Define a few more binary variables
for DATA in xrandr curl wine wineboot winecfg wineconsole winedbg winefile winepath wineserver winetricks find; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

# Define some booleans if they aren't declared already
if [ ${#BOL_HELP}	-eq 0 ]; then declare -i BOL_HELP=$FALSE;		fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;		fi
if [ ${#BOL_DEBUG}	-eq 0 ]; then declare -i BOL_DEBUG=$FALSE;		fi
if [ ${#BOL_VERSION}	-eq 0 ]; then declare -i BOL_VERSION=$FALSE;		fi
if [ ${#BOL_ALLOW_ROOT}	-eq 0 ]; then declare -i BOL_ALLOW_ROOT=$FALSE;		fi
if [ ${#BOL_BOOT}	-eq 0 ]; then declare -i BOL_BOOT=$FALSE;		fi
if [ ${#BOL_CFG}	-eq 0 ]; then declare -i BOL_CFG=$FALSE;		fi
if [ ${#BOL_TRICKS}	-eq 0 ]; then declare -i BOL_TRICKS=$FALSE;		fi
if [ ${#BOL_ESSENTIAL}	-eq 0 ]; then declare -i BOL_ESSENTIAL=$FALSE;		fi
if [ ${#RUN_ARRAY[@]}	-eq 0 ]; then declare -a RUN_ARRAY=();			fi
if [ ${#RUN_INDEX}	-eq 0 ]; then declare -i RUN_INDEX=${#RUN_ARRAY[@]};	fi

# Self explainatory function
function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function SET_ESSENTIALS()
{
    declare -i RUN_INDEX=${#RUN_ARRAY[@]}
    for DATA in d3dx9 d3dcompiler_42 d3dcompiler_43 d3dcompiler_47 mfc40 mfc42 mfc70 mfc80 mfc90 d3dx9 d3dx10 mfc100 dotnet40 dotnet45; do
        RUN_ARRAY[$((RUN_INDEX))]=$DATA
        RUN_INDEX=${#RUN_ARRAY[@]}
    done
    return $SUCCESS
};

function SHOW_INFO()
{
  echo -e "Wine Arch:\t$WINEARCH"
  echo -e "Wine Prefix:\t$WINEPREFIX"
  echo -e "Binary:\t${RUN_ARRAY[@]}"
  echo -e "Video Output:\t$CONOUT"
  echo -e "Resolution:\t$CURRES"
  return $SUCCESS
};

case ${WORKING_PREFIX:0:18} in
   '/opt/WinePrefixes/')
       CUT_EXEC="${WORKING_PREFIX:18}"
       CUT_EXEC="${CUT_EXEC%%/*}"
       ;;
   *)
       unset CUT_EXEC
       ;;
esac
if [ ${#CUT_EXEC} -gt 0 ]; then if [ -d "/opt/WinePrefixes/$CUT_EXEC" ]; then export WINEPREFIX="/opt/WinePrefixes/$CUT_EXEC"; fi;                                      fi

function GET_CONNECTED_OUTPUT()
{
    declare -i RETVAL=$FAILURE
    declare -i LINE_INDEX=-1
    declare -i WORD_INDEX=-1
    declare -i BOL_CONN=$FALSE
    while IFS= read LINE; do
	((LINE_INDEX++))
	WORD_INDEX=-1
        for WORD in $LINE; do
            case $WORD in
                'connected') BOL_CONN=$TRUE;;
            esac
        done
	if [ $BOL_CONN -eq $TRUE ]; then
	    RETVAL=$SUCCESS
	    BOL_CONN=$FALSE
	    WORD_INDEX=-1
	    for WORD in $LINE; do
		((WORD_INDEX++))
		if [ $WORD_INDEX -eq 0 ]; then echo -e "$WORD"; fi
	    done
	fi
    done < <($XRANDR_BIN)
    return $RETVAL
};

function GETRES()
{
    declare -i WORD_INDEX=-1
    declare -i LINE_INDEX=-1
    declare -i RETVAL=$FAILURE

    while IFS= read LINE; do
        ((LINE_INDEX++))
        WORD_INDEX=-1
        for WORD in $LINE; do
	    ((WORD_INDEX++))
	    if [ $WORD_INDEX -eq 0 ]; then echo -e "$WORD"; fi
	done
    done < <($XRANDR_BIN | $GREP_BIN '*+'; RETVAL=$?)
    return $RETVAL
};

declare -a HELP_ARRAY=("--help" "(or -h) Display this help message.\n" "--verbose" "(or -v) be verbose.\n" "--debug" "(or -d) Show debug output.\n" 					\
	"--version" "(or -V) Show version.\n" "--allow-root" "Root user will be allowed.\n" "--boot" "Bootstrap (setup) new Wine Prefix.\n" "--cfg" "Run WINECFG in current Prefix.\n"	\
	"--tricks" "Run WINETRICKS in current Prefix.\n" "--essential" "Install the *Essential* Windows Dependancies.\n" "--win32" "(or -32) Windows 32 bit Prefix *Default*\n"		\
	"--win64" "(or -64) Windows 64 bit Prefix.\n" "--prefix=XXX" "Specify Windows Prefix.\n" "XXXX" "Binary to execute.\n" 								);

# Parse command line options
for OPTIONS in $@; do
    case $OPTIONS in
	-h | --help)		declare -i BOL_HELP=$TRUE;;
	-v | --verbose)		declare -i BOL_VERBOSE=$TRUE;;
	-d | --debug)		declare -i BOL_DEBUG=$TRUE;;
	--version)		declare -i BOL_VERSION=$TRUE;;
	--allow-root)		declare -i BOL_ALLOW_ROOT=$TRUE;;
	--boot)			declare -i BOL_BOOT=$TRUE;;
	--cfg)			declare -i BOL_CFG=$TRUE;;
	--tricks)		declare -i BOL_TRICKS=$TRUE;;
	--essential)		declare -i BOL_TRICKS=$TRUE;	declare -i BOL_ESSENTIAL=$TRUE;;
	'-32' | '--win32')	export WINEARCH="win32";;
	'-64' | '--win64')	export WINEARCH="win64";;
	--prefix=*)		export WINEPREFIX="${OPTIONS#*=}";;
	*)			RUN_ARRAY[$((RUN_INDEX))]=$OPTIONS; RUN_INDEX=${#RUN_ARRAY[@]};;
    esac
done

if [ ${#WINEPREFIX} -eq 0 ] && [ ${#RUN_ARRAY[@]} -gt     0 ]; then
    export EXEC="${RUN_ARRAY[0]}"
    case ${EXEC:0:18} in
	'/opt/WinePrefixes/')
	    CUT_EXEC="${EXEC:18}"
	    CUT_EXEC="${CUT_EXEC%%/*}"
	    ;;
	*)
	    unset CUT_EXEC
	    ;;
    esac
fi
if [ $BOL_HELP				      -eq $TRUE ]; then DO_HELP; exit $SUCCESS;											fi
if [ ${#CUT_EXEC} -gt 0 ]; then if [ -d "/opt/WinePrefixes/$CUT_EXEC" ]; then export WINEPREFIX="/opt/WinePrefixes/$CUT_EXEC"; fi;					fi
if [ ${#CONOUT}				      -eq     0 ]; then export CONOUT=$(GET_CONNECTED_OUTPUT);									fi
if [ ${#CURRES}				      -eq     0 ]; then export CURRES=$(GETRES);										fi
if [ ${#WINEARCH}			      -eq     0 ]; then export WINEARCH="win32";										fi
if [ ${#BINPREFIX}			      -eq     0 ]; then export BINPREFIX="/usr/bin";										fi
if [ $BOL_DEBUG				      -eq $TRUE ]; then export WINEDEBUG="-all";										fi
if [ $(id -u) -eq 0 ] &&  [ $BOL_ALLOW_ROOT  -eq $FALSE ]; then SHOW_HEADER; echo -e "Error: $RUN_CMD Version $VERSION Cannot be ran as ROOT user!"; exit $FAILURE;	fi
if [ $BOL_VERBOSE                             -eq $TRUE ]; then SHOW_HEADER; SHOW_INFO;                                                                                 fi
if [ $BOL_ESSENTIAL			      -eq $TRUE ]; then SET_ESSENTIALS;												fi
if [ ${#WINEPREFIX} -gt 0 ] && [ $BOL_BOOT    -eq $TRUE ]; then $WINEBOOT_BIN   ${RUN_ARRAY[@]}; RETVAL=$?;								fi
if [ ${#WINEPREFIX} -gt 0 ] && [ $BOL_CFG     -eq $TRUE ]; then $WINECFG_BIN    ${RUN_ARRAY[@]}; RETVAL=$?;                                                             fi
if [ ${#WINEPREFIX} -gt 0 ] && [ $BOL_TRICKS  -eq $TRUE ]; then $WINETRICKS_BIN ${RUN_ARRAY[@]}; RETVAL=$?;								fi
if [ ${#WINEPREFIX} -eq	0 ] || [ ${#RUN_ARRAY[@]} -eq 0 ]; then
if [ $BOL_CFG -eq $FALSE  ] && [ $BOL_BOOT   -eq $FALSE ]  && [ $BOL_TRICKS -eq $FALSE ]; then
                                                                SHOW_HEADER; echo -e "Nothing to do. Run: $RUN_CMD --help for more information.\n"; exit $SUCCESS; fi;  fi
if [ ${#WINEPREFIX} -gt 0 ] && [ ${#RUN_ARRAY[@]} -gt 0 ]  && [ $BOL_ESSENTIAL -eq $FALSE ] && \
   [ $BOL_BOOT -eq $FALSE ] && [ $BOL_CFG    -eq $FALSE ]  && [ $BOL_TRICKS -eq $FALSE ]; then
	$WINE_BIN "${RUN_ARRAY[@]}"
	RETVAL=$?
	# Incase WINE Crashes in a different resolution, we'll set it back to what it was prior to runnnig Wine binary
	$XRANDR_BIN --output $CONOUT --mode $CURRES
fi

exit $RETVAL
