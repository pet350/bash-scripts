#/bin/bash
# Source Functions For Getting Package Lists
# By: Peter Talbott
# 2019/02/25

# Define Version
_VER=0.2

# Define Global TRUE/FALSE and SUCCESS/FAILURE
declare -ig TRUE=1
declare -ig FALSE=0
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Booleans
declare -ig BOL_GetPackageList=$FALSE
declare -ig BOL_GetAptPackageList=$FALSE
declare -ig BOL_ShowIndex=$FALSE

# Define Gobal Package List Arrays
declare -ag PackageListArray=();
declare -ag AptPackageListArray=();

# Define Global Integer Variables
declare -ig PackageListArrayIndex=0
declare -ig AptPackageListArrayIndex=0

# Define Paths And Binaries
export BIN_PREFIX="/usr/bin"
export DPKG_BIN="$BIN_PREFIX/dpkg"
export APT_BIN="$BIN_PREFIX/apt"

# Function To Populate PackageListArray Using 'dpkg' Method
# Will ONLY Store Bare Package Name Into Each Array Index
# Last Modified Version: 0.1
function GetPackageList()
{
  declare -i Index=-1
  declare -i BOL_StoreData=$FALSE
  for DATA in $($DPKG_BIN --get-selections); do
    if [ $BOL_StoreData -eq $TRUE ]; then
	((Index++))
	PackageListArray[$((Index))]=$TEMP_DATA
    fi
    if [ $DATA == 'install' ]; then
	BOL_StoreData=$TRUE
    else
	BOL_StoreData=$FALSE
	TEMP_DATA=$DATA
    fi
  done
  ((Index++))
  PackageListArray[$((Index))]=$TEMP_DATA
  BOL_GetPackageList=$TRUE
  return $Index
};

# Function To Populate AptPackageListArray Using 'apt' Method
# Will Store Package Name Line by Line Into Each Array Index
# Last Modified Version: 0.1
function GetAptPackageList()
{
  declare -i Index=-1
  declare -i BOL_StoreData=$FALSE
  while IFS= read -r line; do
    ((Index++))
    AptPackageListArray[$((Index))]=$line
  done < <( $APT_BIN list | grep installed)
  BOL_GetAptPackageList=$TRUE
  AptPackageListArrayIndex=$((Index))
  return $Index
};

# Basic Function to Display Contents Of PackageListArray
# Last Modified Version: 0.2
## Added 'BOL_ShowIndex' Options
function ShowPackageListArray()
{
  declare -i INDEX=-1
  if [ $BOL_GetPackageList -eq $FALSE ]; then
    GetPackageList
  fi
  for DATA in ${PackageListArray[@]}; do
    ((INDEX++))
    if [ $BOL_ShowIndex -eq $TRUE ]; then
        printf "%-6s %-4d %-5s %s\n" "INDEX:" $((INDEX)) "DATA:" "$DATA"
    else
        printf "%s\n" "$DATA"
    fi
  done
  return $SUCCESS
};

# Basic Function to Display Contents of AptPackageListArray
# Last Modified Version: 0.2
## Toatlly Revised This Function
function ShowAptPackageListArray()
{
  if [ $BOL_GetAptPackageList -eq $FALSE ]; then
    GetAptPackageList
  fi
  for (( INDEX=0; $((INDEX)) <= $((AptPackageListArrayIndex)); INDEX++ )); do
    DATA="${AptPackageListArray[$((INDEX))]}"
    if [ $BOL_ShowIndex -eq $TRUE ]; then
	printf "%-6s %-4d %-5s %s\n" "INDEX:" $((INDEX)) "DATA:" "$DATA"
    else
	printf "%s\n" "$DATA"
    fi
  done
  return $SUCCESS
};


