#/bin/bash
# Source Functions For Getting Package Lists
# By: Peter Talbott
# 2019/02/25

# Define Version
_VER=0.1

# Define TRUE/FALSE and SUCCESS/FAILURE
declare -ig TRUE=1
declare -ig FALSE=0
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Booleans
declare -ig BOL_GetPackageList=$FALSE
declare -ig BOL_GetAptPackageList=$FALSE

# Define Package List Arrays
declare -ag PackageListArray=();
declare -ag AptPackageListArray=();

# Define Paths And Binaries
export BIN_PREFIX="/usr/bin"
export DPKG_BIN="$BIN_PREFIX/dpkg"
export APT_BIN="$BIN_PREFIX/apt"

# Function To Populate PackageListArray Using 'dpkg' Method
# Will ONLY Store Bare Package Name Into Each Array Index
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
function GetAptPackageList()
{
  declare -i Index=-1
  declare -i BOL_StoreData=$FALSE
  while IFS= read -r line; do
    ((Index++))
    AptPackageListArray[$((Index))]=$line
  done < <( $APT_BIN list | grep installed)
  BOL_GetAptPackageList=$TRUE
  return $Index
};

# Basic Function to Display Contents Of PackageListArray
function ShowPackageListArray()
{
  if [ $BOL_GetPackageList -eq $FALSE ]; then
    GetPackageList
  fi
  for DATA in ${PackageListArray[@]}; do
    echo -e "$DATA"
  done
  return $SUCCESS
};

# Basic Function to Display Contents of AptPackageListArray
function ShowAptPackageListArray()
{
  if [ $BOL_GetAptPackageList -eq $FALSE ]; then
    GetAptPackageList
  fi
  for DATA in ${AptPackageListArray[@]}; do
    echo -e "$DATA"
  done
  return $SUCCESS
};


