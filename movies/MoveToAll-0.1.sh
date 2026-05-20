#!/bin/bash
# Simple Script To Move All Files To the "All" folder

export SOURCE_PREFIX="/opt/video/movies"
export TARGET_PREFIX="/opt/video/movies/All"

declare -ag SOURCE_ARRAY=("$SOURCE_PREFIX/Action" "$SOURCE_PREFIX/Children" "$SOURCE_PREFIX/Comedy" \
	"$SOURCE_PREFIX/Drama" "$SOURCE_PREFIX/Horror" "$SOURCE_PREFIX/Music" "$SOURCE_PREFIX/SciFi" \
	"$SOURCE_PREFIX/TiVo" "$SOURCE_PREFIX/Unsorted");

export MV_BIN="/bin/mv"
export LN_BIN="/bin/ln"

function MOVE_LOOP()
{
  while IFS= read -r line; do
    SOURCE_FILE="$SOURCE_PREFIX/$line"
    TARGET_FILE="$TARGET_PREFIX/$line"
    echo -e "Source:\t$SOURCE_FILE\nTarget:\t$TARGET_FILE"
    $MV_BIN -v "$SOURCE_FILE" "$TARGET_PREFIX"
    RETVAL=$?
    cd $SOURCE_PREFIX
    echo -e "Create Symlink from $TARGET_FILE to $SOURCE_FILE\n\n"
    $LN_BIN -s "$TARGET_FILE"
  done < <(ls -1 "$SOURCE_PREFIX")
  return $RETVAL
};

for TEMP_DATA in ${SOURCE_ARRAY[@]}; do
  export SOURCE_PREFIX="$TEMP_DATA"
  export TARGET_PREFIX="$TARGET_PREFIX"
  MOVE_LOOP
  RETVAL=$?
done

exit $RETVAL