# Definitions for handeling RapidDisk

if [ ${#RD_SIZE_ARRAY[@]} -eq	0 ]; then	declare -ag RD_ARRAY=();	fi

function GET_RD_SIZE()
{
  declare -i ARRAY_INDEX=-1
  declare -i TEMP_INDEX=-1
  declare -i BOL_SIZE=$FALSE
  declare -i FUNCTION_RETURN=$FAILURE
  declare -a TEMP_ARRAY=()

  while IFS= read LINE; do
    BOl_SIZE=$FALSE
    for WORD in $LINE; do
      if [ $BOL_SIZE -eq $TRUE ]; then
        ((ARRAY_INDEX++))
        TEMP_ARRAY[$((ARRAY_INDEX))]="$WORD"
        FUNCTION_RETURN=$SUCCESS
      fi
      case $WORD in
        '(KB):')
          BOL_SIZE=$TRUE
          ;;
        *)
          BOL_SIZE=$FALSE
          ;;
      esac
    done
  done < <($RAPIDDISK_BIN --list)
  TEMP_INDEX=$((${#TEMP_ARRAY[@]}-1))
  ARRAY_INDEX=-1
  #Revers Array Listing
  while [ $((TEMP_INDEX)) -ne -1 ]; do
    ((ARRAY_INDEX++))
    RD_SIZE_ARRAY[$((ARRAY_INDEX))]="${TEMP_ARRAY[$((TEMP_INDEX))]}"
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] Device: rd$((ARRAY_INDEX)) Size: ${TEMP_ARRAY[$((TEMP_INDEX))]}"; fi
    ((TEMP_INDEX--))
  done
  return $FUNCTION_RETURN
};
