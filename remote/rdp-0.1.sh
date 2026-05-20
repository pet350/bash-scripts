#!/bin/bash
# Shell Script By: Peter Talbott
# 2022-01-17,18

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

export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-02-08"

# Define Additional Option Array
declare -a ADD_OPT=();
declare -i ADD_OPT_LEN=${#ADD_OPT[@]}

declare -a HELP_ARRAY=( "-h" "or --help Display this message" "-v" "or --verbose Be verbose with text output\n" "--debug" "Show debug text output.\n"			\
	"--version" "Display Version info then exit.\n" "--test" "Put in test mode (No Binary Execution)\n" "------" " --Any line with (!) is a default.\n"	\
	"--user=XXX" "Set the username to login under.\n" "--pass=*" "Set the password for the user account.\n" "--domain=*" "Set the logn domain.\n"		\
	"--cert-ignore" "Ignore self signed certificate. (!)\n" "--no-cert-ignore" "Do NOT ignore certificate signature.\n" "--auto-reconnect"			\
	"Auto reconnect if connection dropps due to an error. (!)\n" "--no-auto-reconnect" "Do NOT reconnect due to network errors.\n" "--dyn-res"		\
	"Enable Dynamic Resolution (!)\n" "--no-dyn-res" "Do NOT enable Dynamic Resolution.\n" "--bpp=nn" "Set Bits Per Pixel. Default is 32.\n"		\
	"--width=nnnn" "Sets width in pixels.\n" "--height=nnnn" "Sets height in pixels.\n" "--host-check" "Check Host is Alive.\n" "--no-host-check"		\
	"Do not check if host is alive.\n" );

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

# Define Static String Variables
export TEMP="xfreerdp";	XFREERDP_BIN=$(GET_BIN); unset TEMP
export BPP_OPT='/bpp:'
export HEIGHT_OPT='/h:'
export WIDTH_OPT='/w:'
export USER_OPT='/u:'
export PASS_OPT='/p:'
export DOMAIN_OPT='/d:'
export HOST_OPT='/v:'
export DYN_RES_OPT='/dynamic-resolution'
export AUTO_RECON_OPT='+auto-reconnect'
export CERT_IGN_OPT='/cert-ignore'

for OPTIONS in $@; do
  case $OPTIONS in
    -v   | --verbose)			declare -i BOL_VERBOSE=$TRUE;;
    -d   | --debug)			declare -i BOL_DEBUG=$TRUE;;
    -V   | --version)			declare -i BOL_VERSION=$TRUE;;
    -t   | --test)			declare -i BOL_TEST=$TRUE;;
    -h   | --help)			declare -i BOL_HELP=$TRUE;;
    -ci  | --cert-ignore)		declare -i BOL_CERT_IGNORE=$TRUE;;
    -nci | --no-cert-ignore)		declare -i BOL_CERT_IGNORE=$FALSE;;
    -ar  | --auto-reconnect)		declare -i BOL_AUTO_RECONNECT=$TRUE;;
    -nar | --no-auto-reconnect)		declare -i BOL_AUTO_RECONNECT=$FALSE;;
    -dr  | --dyn-res)			declare -i BOL_DYN_RES=$TRUE;;
    -ndr | --no-dyn-res)		declare -i BOL_DYN_RES=$FALSE;;
    -hc  | --host-check)		declare -i BOL_SKIP_HOST_CHECK=$FALSE;;
    -nhc | --no-host-check)		declare -i BOL_SKIP_HOST_CHECK=$TRUE;;
    --bpp=*)				declare -i BPP="${OPTIONS#*=}";;
    --height=*)				declare -i HEIGHT="${OPTIONS#*=}";;
    --width=*)				declare -i WIDTH="${OPTIONS#*=}";;
    --user=*)				export USERNAME="${OPTIONS#*=}";;
    --pass=*)				export PASSWORD="${OPTIONS#*=}";;
    --domain=*)				export DOMAIN="${OPTIONS#*=}";;
    --host=*)				export HOST="${OPTIONS#*=}";;
    *)					ADD_OPT_LEN=${#ADD_OPT[@]};		ADD_OPT[$((ADD_OPT_LEN))]=$OPTIONS;;
  esac
done

# Set Default Values IF thier not already defined
if [ ${#BOL_SKIP_HOST_CHECK}	-eq 0 ]; then declare -i BOL_SKIP_HOST_CHECK=$FALSE;								fi
if [ ${#BOL_COLOR}		-eq 0 ]; then declare -i BOL_COLOR=$TRUE;									fi
if [ ${#BOL_VERBOSE}		-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;									fi
if [ ${#BOL_DEBUG}		-eq 0 ]; then declare -i BOL_DEBUG=$FALSE;									fi
if [ ${#BOL_VERSION}		-eq 0 ]; then declare -i BOL_VERSION=$FALSE;									fi
if [ ${#BOL_TEST}		-eq 0 ]; then declare -i BOL_TEST=$FALSE;									fi
if [ ${#BOL_HELP}		-eq 0 ]; then declare -i BOL_HELP=$FALSE;									fi
if [ ${#BOL_CERT_IGNORE}	-eq 0 ]; then declare -i BOL_CERT_IGNORE=$TRUE;									fi	# Ignore SSL Cert By Default
if [ ${#BOL_AUTO_RECONNECT}	-eq 0 ]; then declare -i BOL_AUTO_RECONNECT=$TRUE;								fi	# Auto Reconnect By Default
if [ ${#BOL_DYN_RES}		-eq 0 ]; then declare -i BOL_DYN_RES=$TRUE;									fi	# Dynamic Resolution ON By Default
if [ ${#BPP}			-eq 0 ]; then declare -i BPP=32;										fi	# 32 Bits Per Pixel By Default
if [ ${#HEIGHT}			-eq 0 ]; then declare -i HEIGHT=768;										fi	# Default Height 768
if [ ${#WIDTH}			-eq 0 ]; then declare -i WIDTH=1024;										fi	# Default Width 1024

declare -a OPTION_ARRAY=( "$HOST_OPT$HOST" "$WIDTH_OPT$WIDTH" "$HEIGHT_OPT$HEIGHT" "$BPP_OPT$BPP" "$USER_OPT$USERNAME" "$PASS_OPT$PASSWORD" "$DOMAIN_OPT$DOMAIN" );

if [ $BOL_CERT_IGNORE		-eq $TRUE ]; then declare -i OPT_LEN=${#OPTION_ARRAY[@]}; OPTION_ARRAY[$((OPT_LEN))]="$CERT_IGN_OPT";		fi
if [ $BOL_AUTO_RECONNECT	-eq $TRUE ]; then declare -i OPT_LEN=${#OPTION_ARRAY[@]}; OPTION_ARRAY[$((OPT_LEN))]="$AUTO_RECON_OPT";		fi
if [ $BOL_DYN_RES		-eq $TRUE ]; then declare -i OPT_LEN=${#OPTION_ARRAY[@]}; OPTION_ARRAY[$((OPT_LEN))]="$DYN_RES_OPT";		fi
if [ $BOL_VERSION		-eq $TRUE ]; then SHOW_HEADER;		exit $SUCCESS;								fi
if [ $BOL_HELP			-eq $TRUE ]; then DO_HELP;		exit $SUCCESS;								fi
if [ $BOL_COLOR			-eq $TRUE ]; then INIT_COLOR; INIT_COLOR_SHORTHAND;									fi
if [ $BOL_TEST			-eq $TRUE ]; then export XFREERDP_BIN=$TRUE_BIN; export PING_BIN=$TRUE_BIN;					fi
if [ $BOL_TEST -eq $TRUE ] && [ BOL_VERBOSE -eq $TRUE ]; then echo -e "Test Mode, No Binary Will Be Executed!";					fi

if [ ${#HOST}                   -eq 0 ]; then SHOW_HEADER; echo -e "\nfor Usage: $RUN_CMD --help"; exit $FAILURE;                               fi      # No Host Defined to connect to
# Test to see if $HOST is alive
$PING_BIN -c 1 $HOST >/dev/null 2>/dev/null
if [ $? -eq $SUCCESS ] || [ $BOL_SKIP_HOST_CHECK -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_SKIP_HOST_CHECK -eq $FALSE ]; then echo -e "$HOST is online! Attempting Remote Desktop Connection";	fi
  if [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_SKIP_HOST_CHECK -eq $TRUE  ]; then echo -e "Skipped checking if $HOST is online";			fi
  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Executing: $XFREERDP_BIN ${OPTION_ARRAY[@]} ${ADD_OPT[@]}"; fi
  $XFREERDP_BIN ${OPTION_ARRAY[@]} ${ADD_OPT[@]}
  RETVAL=$?
else
  echo -e "$HOST is not online"
  RETVAL=$FAILURE
fi

exit $RETVAL

