#!/bin/bash

if [ ${#TRUE}		-eq 0 ]; then declare -i TRUE=1;					fi
if [ ${#FALSE}		-eq 0 ]; then declare -i FALSE=0;					fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;				fi
if [ ${#PAGE_NUMBER}	-eq 0 ]; then declare -i PAGE_NUMBER=0;					fi
if [ ${#MAX_PAGE}	-eq 0 ]; then declare -i MAX_PAGE=10;					fi

if [ ${#PROTOCOL}	-eq 0 ]; then export PROTOCOL="https://";				fi
if [ ${#DOMAIN}		-eq 0 ]; then export DOMAIN="www.pornhub.com";				fi
if [ ${#SEARCH_STRING}	-eq 0 ]; then export SEARCH_STRING="nebraska+coeds";			fi
if [ ${#SEARCH}		-eq 0 ]; then export SEARCH="/video/search?search=$SEARCH_STRING";	fi
if [ ${#PAGE}		-eq 0 ]; then export PAGE="&page=$PAGE_NUMBER";				fi
if [ ${#DL_URL}		-eq 0 ]; then export DL_URL="$PROTOCOL$DOMAIN$SEARCH$PAGE";		fi


function DL_LIST()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Attempting to get list from: $DL_URL";		fi
  curl $DL_URL 2>/dev/null | grep 'href="/view_video.php?viewkey=' | while IFS= read LINE; do
      RET_VAL=$?
      INDEX=-1
      for WORD in $LINE; do
        ((INDEX++))
        if [ ${#OLD_URL} -eq 0 ]; then export OLD_URL="$WORD"; fi
        if [ $INDEX -eq 1 ] && [ ${WORD:0:4} == 'href' ]; then
            URL="${WORD#href=*}"
            URL=${URL%*'"'}
            URL=${URL#'"'*}
            if [ $URL != $OLD_URL ]; then
              echo $PROTOCOL$DOMAIN$URL
            fi
            OLD_URL=$URL
        fi
      done
  done
  return $RETVAL
};

while [ $PAGE_NUMBER -lt $MAX_PAGE ]; do
  ((PAGE_NUMBER++))
  export PAGE="&page=$PAGE_NUMBER";
  export DL_URL="$PROTOCOL$DOMAIN$SEARCH$PAGE"
  DL_LIST
done
