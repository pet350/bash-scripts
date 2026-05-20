#!/bin/bash

function updatex264()
{
  export WORKING_DIR=$(GET_CURRENT_DIR)
  if [ ${#TRUE}		-eq 0 ]; then declare -i TRUE=1;				fi
  if [ ${#FALSE}	-eq 0 ]; then declare -i FALSE=0;				fi
  if [ ${#DEL_LINKS}	-eq 0 ]; then declare -i DEL_LINKS=$FALSE;			fi
  if [ ${#MOVIE_ROOT}	-eq 0 ]; then export MOVIE_ROOT="/opt/movies";			fi
  if [ ${#X264_DIR}	-eq 0 ]; then export X264_DIR="$MOVIE_ROOT/x264";		fi
  if [ ${#NFS_DIR}	-eq 0 ]; then export NFS_DIR="/nfs/ubuntuserver.gigaware.lan";	fi
  if [ ${#FQDN}		-eq 0 ]; then export FQDN=$(/bin/hostname --fqdn);			fi
  case ${FQDN,,} in
    ubuntuserver.gigaware.lan) 	X264_TARGET="$X264_DIR";		MOVIE_ROOT_TARGET="$MOVIE_ROOT";;
    *)				X264_TARGET="$NFS_DIR$X264_DIR";	MOVIE_ROOT_TARGET="$NFS_DIR$MOVIE_ROOT";;
  esac
  cd "$MOVIE_ROOT_TARGET"
  while IFS= read LINE; do
    if [ $DEL_LINKS -eq $TRUE ]; then rm -vf "$LINE"
    else echo -e "To enable set DEL_LINKS to 1. NOT removing symlink: $LINE.";		fi
  done < <(find "$MOVIE_ROOT_TARGET"/x264* -type l)
  cd "$X264_TARGET"
  while IFS= read LINE; do
     ln -sfv "$LINE"
  done < <(ls -Nd1 ../All/*x264*)
  for LETTER in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    cd "$X264_TARGET-$LETTER"
    echo -e "\n\nMovies Starting with $LETTER"
    while IFS= read LINE; do
      ln -svf "$LINE"
    done < <(find ../x264 -type l -iname "$LETTER*")
  done
  cd "$WORKING_DIR"
  return $?
};
