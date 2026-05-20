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

# Define a few more binary variables
for DATA in curl ldapadd ldapmodify ldapsearch  egrep chown sleep find; do
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

################################
# Define some static variables
################################
export RUN_CMD="$(basename $0)"
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-02-08"
export WORKING_PREFIX="$(pwd)"

# Define MultiDimentional Arrays
declare -A -g ATTRIBUTE_TYPE_ARRAY=();

###############################
## Example LDIF Attribute Type Input
##############################
# olcAttributeTypes: (
#   1.3.6.1.4.1.10098.1.1.7.3
#   NAME 'goFaxDivertNumber'
#   DESC 'for fax diversion services'
#   SYNTAX 1.3.6.1.4.1.1466.115.121.1.22
#   SINGLE-VALUE
#   )
#
#######################################
#  Example LDIF Attribute Type Input
#######################################
#
# olcAttributeTypes: (
#   1.3.6.1.4.1.10098.1.1.7.11
#   NAME 'facsimileAlternateTelephoneNumber'
#   EQUALITY telephoneNumberMatch
#   SUBSTR telephoneNumberSubstringsMatch
#   SYNTAX 1.3.6.1.4.1.1466.115.121.1.50{32}
#  )
#
################################################################################
#
# olcObjectClasses: (
#   1.3.6.1.4.1.10098.1.2.1.11
#   NAME 'goFaxAccount'
#   DESC 'goFax Account objectclass (v1.0.4)'
#   SUP top
#   AUXILIARY
#   MUST ( goFaxDeliveryMode $ facsimileTelephoneNumber $ uid $ goFaxIsEnabled )
#   MAY ( goFaxPrinter $ goFaxDivertNumber $ goFaxLanguage $ goFaxFormat $ goFaxRBlocklist $ goFaxRBlockgroups $ goFaxSBlocklist $ goFaxSBlockgroups $ mail $ facsimileAlternateTelephoneNumber )
#   )
#
#############################
# The above LDIF Attribute Type input should produce
# The below AD Attribute Type output
#############################
#
#############################
## Example Correct AD Output
##############################
# dn: CN=goFaxDivertNumber,CN=Schema,CN=Configuration,DC=gigaware,DC=lan			# Array Index $DIMENTION,0
# objectClass: top										# Array Index $DIMENTION,1
# objectClass: attributeSchema									# Array Index $DIMENTION,2
# attributeID: 1.3.6.1.4.1.10098.1.1.7.3							# Array Index $DIMENTION,3
# attributeSyntax: 2.5.5.12									# Array Index $DIMENTION,4
# cn: goFaxDivertNumber										# Array Index $DIMENTION,5
# name: goFaxDivertNumber									# Array Index $DIMENTION,6
# distinguishedName: CN=goFaxDivertNumber,CN=Schema,CN=Configuration,DC=gigaware,DC=lan		# Array Index $DIMENTION,7
# description: for fax diversion services							# Array Index $DIMENTION,8
# isSingleValued: TRUE										# Array Index $DIMENTION,9
# oMSyntax: 64											# Array Index $DIMENTION,10
# instanceType: 4										# Array Index $DIMENTION,11

# Echos only the first word in the string $LINE
function GET_FIRST_WORD()
{
  declare WORD_COUNT=-1
  for WORD in $LINE; do
    ((WORD_COUNT++))
    if [ $WORD_COUNT -eq 0 ]; then echo $WORD; fi
  done
  return $WORD_COUNT
};

# Echos everything but the first word in the string $LINE
function SKIP_FIRST_WORD()
{
  declare WORD_COUNT=-1
  for WORD in $LINE; do
    ((WORD_COUNT++))
    if [ $WORD_COUNT -gt 0 ]; then printf "%s " $WORD ; fi
  done
  return $WORD_COUNT
};

# Check to see if we are olcAttributeTypes: or olcObjectClasses:
function CHECK_FUNCTION()
{
  unset DATA

  if [ $BOL_DEBUG -eq $TRUE ]; then
    echo -e "\n[Debug] *********************************"
    echo -e   "[Debug] Starting CHECK_FUNCTION function"
  fi
  for WORD in $LINE; do
      case $WORD in
          'olcAttributeTypes:')
		((ATTRIBUTE_COUNT++))
		if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Detected olcAttributeTypes:"; fi
		export BOL_ATTRIB_SCHEMA=$TRUE
		export BOL_OBJECT_CLASS=$FALSE
		;;
	  'olcObjectClasses:')
		((OBJECT_COUNT++))
		if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Detected olcObjectClasses:"; fi
		export BOL_ATTRIB_SCHEMA=$FALSE
		export BOL_OBJECT_CLASS=$TRUE
		;;
	  ')')
		if [ $BOL_DEBUG -eq $TRUE ]; then echo -e '[Debug] Detected  ) ending olcAttributeTypes: or olcObjectClasses:';	fi
		export BOL_ATTRIB_SCHEMA=$FALSE
		export BOL_OBJECT_CLASS=$FALSE
		;;

	  *)
		export DATA="$DATA $WORD"
		;;
      esac
  done
  return $SUCCESS
};

function STORE_ATTRIBUTE_TYPE()
{
  declare -a ELEMENTS=( "DN" "ATTRIBUTE_ID" "ATTRIBUTE_SYNTAX" "CN" "NAME" "DISTINGUISHED_NAME" "DESCRIPTION" "SINGLEVALUE" "OMSYNTAX" "INSTANCE_TYPE" );
  declare -i INDEX=-1

  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "\n[Debug] Starting STORE_ATTRIBUTE_TYPE function";				fi
  export       	         DN="$DN_PREFIX CN=$ATTRIBUTE_NAME,$TARGET_SUFFIX"
  export       ATTRIBUTE_ID="$ATTRIBUTE_ID_PREFIX $ATTRIBUTE_SYNTAX_NAME"
  export   ATTRIBUTE_SYNTAX="$ATTRIBUTE_SYNTAX_PREFIX $AD_SYNTAX"
  export	         CN="$CN_PREFIX $ATTRIBUTE_NAME"
  export	       NAME="$NAME_PREFIX $ATTRIBUTE_NAME"
  export DISTINGUISHED_NAME="$DISTINGUISHED_NAME_PREFIX CN=$ATTRIBUTE_NAME,$TARGET_SUFFIX"
  export        DESCRIPTION="$DESCRIPTION_PREFIX $DESCRIPTION_NAME"
  export 	SINGLEVALUE="$SINGLEVALUE_PREFIX $SINGLEVALUE_BOOLEAN"
  export 	   OMSYNTAX="$OMSYNTAX_PREFIX $OMSYNTAX_VALUE";
  export      INSTANCE_TYPE="$INSTANCE_TYPE_PREFIX $INSTANCE_TYPE_VALUE"
  if [ $BOL_DEBUG -eq $TRUE ]; then
    for ELEMENT in "$DN" "$ATTRIBUTE_ID" "$ATTRIBUTE_SYNTAX" "$CN" "$NAME" "$DISTINGUISHED_NAME" "$DESCRIPTION" "$SINGLEVALUE" "$OMSYNTAX" "$INSTANCE_TYPE"; do
       ((INDEX++))
       printf "[Debug] %-18s:\t%50s\n" "${ELEMENTS[$((INDEX))]}" "$ELEMENT"
    done
  fi
  return $SUCCESS
};

function ASSEMBLE_ATTRIBUTE_TYPE_ARRAY()
{
  declare -i DIMENTION=$((ATTRIBUTE_COUNT))
  declare -i INDEX=-1
  declare -i RETVAL=$FAILURE
  while IFS= read ELEMENT; do
    ((INDEX++))
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "Dimention :$DIMENTION, Element: $ELEMENT"; fi
    ATTRIBUTE_TYPE_ARRAY[$((DIMENTION)),$((INDEX))]="$ELEMENT"
  done < <(echo -e "$DN\n$OBJECTCLASS_TOP\n$ATTRIBUTE_SCHEMA\n$ATTRIBUTE_ID\n$ATTRIBUTE_SYNTAX\n$CN\n$NAME\n$DISTINGUISHED_NAME\n$DESCRIPTION\n$SINGLEVALUE\n$OMSYNTAX\n$INSTANCE_TYPE\n")
  if [ $INDEX -eq 11 ]; then RETVAL=$SUCCESS; fi
  return $RETVAL
};


function READ_LDIF()
{
  declare -i LINE_INDEX=-1
  declare -i ATTRIBUTE_COUNT=-1
  declare -i BOL_ATTRIB_SCHEMA=$FALSE
  declare -i BOL_OBJECT_CLASS=$FALSE
  declare -i RETVAL=$FAILURE
  declare -i ATTRIBUTE_INDEX=-1

  while IFS= read LINE; do
    ((LINE_INDEX++))
    if [ $BOL_DEBUG -eq $TRUE ]; then printf "[Debug] Line %-3s: %40s\n" $LINE_INDEX "$LINE"; fi
    case ${LINE:0:1} in		# Check the first letter of $LINE
      '#')
            # Ignore lines starting with '#'
	    if [ $BOL_DEBUG -eq $TRUE ]; then printf "[Debug] Ignoring Line %-3s, it starts with a #\n" $LINE_INDEX; fi
            ;;
        *)			# Process every line that doesnt start with '#'
            CHECK_FUNCTION
            if [ $BOL_ATTRIB_SCHEMA -eq $TRUE ]; then
		 ((ATTRIBUT_INDEX++))
		 if   [ $ATTRIBUTE_INDEX -eq 0 ]; then
			ATTRIBUTE_ID="$DATA"
		 else
			export VALUE="$(SKIP_FIRST_WORD)"
			declare -i LEN=0
			case $(GET_FIRST_WORD) in
				'NAME')
					declare -x ATTRIBUTE_NAME="${VALUE#NAME*}"
					declare -x ATTRIBUTE_NAME="${ATTRIBUTE_NAME:1}"
					declare -i LEN=${#ATTRIBUTE_NAME}
					declare -x ATTRIBUTE_NAME="${ATTRIBUTE_NAME:0:$((LEN-2))}"
					;;
				'DESC')
					declare -x DESCRIPTION_NAME="${VALUE#DESC*}"
					declare -x DESCRIPTION_NAME="${DESCRIPTION_NAME:1}"
					declare -i LEN=${#DESCRIPTION_NAME}
					declare -x DESCRIPTION_NAME="${DESCRIPTION_NAME:0:$((LEN-2))}"
					;;
				'SYNTAX')
					declare -x ATTRIBUTE_SYNTAX_NAME="${VALUE#SYNTAX*}"
					;;
				'SINGLE-VALUE')	export SINGLEVALUE_BOOLEAN="TRUE";;

			esac
		 fi
	    fi
	    STORE_ATTRIBUTE_TYPE
	    ASSEMBLE_ATTRIBUTE_TYPE_ARRAY
            ;;
    esac
  done < <(cat $FILENAME)
  return $ATTRIBUTE_COUNT
};


# Parse command line options
for OPTIONS in $@; do
  case $OPTIONS in
        --version)                      SHOW_HEADER;                            exit $SUCCESS;;
        --debug | -d)                   declare -i BOL_DEBUG=$TRUE;;
        --verbose | -v)                 declare -i BOL_VERBOSE=$TRUE;           export VERBOSE="-v";;
        --help | -h)                    declare -i BOL_HELP=$TRUE;;
        --bw)                           declare -i BOL_COLOR=$FALSE;;
        --test | -t)                    declare -i BOL_TEST=$TRUE;;
	--domain-suffix=*)		declare -x DOMAIN_SUFFIX="${OPTIONS#*=}";;
	--filename=* | --file=*)	declare -x FILENAME="${OPTIONS#*=}";;
  esac
done

# Define Initial String Variables
if [ ${#AD_SYNTAX}			-eq 0 ]; then export AD_SYNTAX="2.5.5.12";							fi
if [ ${#DN_PREFIX}			-eq 0 ]; then export DN_PREFIX="dn:";								fi
if [ ${#DOMAIN_SUFFIX}			-eq 0 ]; then export DOMAIN_SUFFIX="DC=gigaware,DC=lan";					fi
if [ ${#TARGET_SUFFIX}			-eq 0 ]; then export TARGET_SUFFIX="CN=Schema,CN=Configuration,$DOMAIN_SUFFIX";			fi
if [ ${#OBJECTCLASS_PREFIX}		-eq 0 ]; then export OBJECTCLASS_PREFIX="objectClass:";						fi
if [ ${#OBJECTCLASS_TOP}		-eq 0 ]; then export OBJECTCLASS_TOP="$OBJECTCLASS_PREFIX top";					fi
if [ ${#ATTRIBUTE_SCHEMA}		-eq 0 ]; then export ATTRIBUTE_SCHEMA="$OBJECTCLASS_PREFIX attributeSchema";			fi
if [ ${#ATTRIBUTE_ID_PREFIX}		-eq 0 ]; then export ATTRIBUTE_ID_PREFIX="attributeID:";					fi
if [ ${#ATTRIBUTE_SYNTAX_PREFIX}	-eq 0 ]; then export ATTRIBUTE_SYNTAX_PREFIX="attributeSyntax:";				fi
if [ ${#ATTRIBUTE_SYNTAX_NAME}		-eq 0 ]; then export ATTRIBUTE_SYNTAX_NAME="2.5.5.12";						fi
if [ ${#ATTRIBUTE_SYNTAX}		-eq 0 ]; then export ATTRIBUTE_SYNTAX="$ATTRIBUTE_SYNTAX_PREFIX $ATTRIBUTE_SYNTAX_NAME";	fi
if [ ${#CN_PREFIX}			-eq 0 ]; then export CN_PREFIX="cn:";								fi
if [ ${#NAME_PREFIX}			-eq 0 ]; then export NAME_PREFIX="name:";							fi
if [ ${#DISTINGUISHED_NAME_PREFIX}	-eq 0 ]; then export DISTINGUISHED_NAME_PREFIX="distinguishedName:";				fi
if [ ${#DISTINGUISHED_NAME_SUFFIX}	-eq 0 ]; then export DISTINGUISHED_NAME_SUFFIX="$TARGET_SUFFIX";				fi
if [ ${#DESCRIPTION_PREFIX}		-eq 0 ]; then export DESCRIPTION_PREFIX="description:";						fi
if [ ${#SINGLEVALUE_PREFIX}		-eq 0 ]; then export SINGLEVALUE_PREFIX="isSingleValued:";					fi
if [ ${#SINGLEVALUE_BOOLEAN}		-eq 0 ]; then export SINGLEVALUE_BOOLEAN="TRUE";						fi
if [ ${#SINGLEVALUE}			-eq 0 ]; then export SINGLEVALUE="$SINGLEVALUE_PREFIX $SINGLEVALUE_BOOLEAN";			fi
if [ ${#OMSYNTAX_PREFIX}		-eq 0 ]; then export OMSYNTAX_PREFIX="oMSyntax:";						fi
if [ ${#OMSYNTAX_VALUE}			-eq 0 ]; then export OMSYNTAX_VALUE="64";							fi
if [ ${#OMSYNTAX}			-eq 0 ]; then export OMSYNTAX="$OMSYNTAX_PREFIX $OMSYNTAX_VALUE";				fi
if [ ${#INSTANCE_TYPE_PREFIX}		-eq 0 ]; then export INSTANCE_TYPE_PREFIX="instanceType:";					fi
if [ ${#INSTANCE_TYPE_VALUE}		-eq 0 ]; then export INSTANCE_TYPE_VALUE="4";							fi
if [ ${#INSTANCE_TYPE}			-eq 0 ]; then export INSTANCE_TYPE="$INSTANCE_TYPE_PREFIX $INSTANCE_TYPE_VALUE";		fi


READ_LDIF
declare -i DIMENTION=$?
declare -i DIM_INDEX=-1
declare -i ELE_INDEX=-1
if [ ${#ELE_MAX} 	-eq 0 ]; then declare -i ELE_MAX=11;										fi

while [ $DIM_INDEX -lt $DIMENTION ]; do
    ((DIM_INDEX++))
    ELE_INDEX=-1
    while [ $ELE_INDEX -lt $ELE_MAX ]; do
        ((ELE_INDEX++))
	if [ $BOL_DEBUG -eq $TRUE ]; then printf "[Debug] Dim: %-3s : Ele: %-3s : " $DIM_INDEX $ELE_INDEX;				fi
        echo -e "${ATTRIBUTE_TYPE_ARRAY[$((DIM_INDEX)),$((ELE_INDEX))]}"
    done
    echo '-'
done

