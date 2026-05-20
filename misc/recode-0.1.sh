#!/bin/bash
export TARGET_PREFIX="../../../../../../opt/movies/GHI/Hardcore Pawn Season 3"

clear
while IFS= read FILENAME; do
  export NTSC_MPEG="./${FILENAME%.avi*}.mpeg"
  export NTSC_MP4="./${FILENAME%.avi*}.mp4"
  export SOURCE="./$FILENAME"
  sleep 1
  echo -e "Source: $SOURCE"
  echo -e "MPEG: $NTSC_MPEG"
  echo -e "MP4: $NTSC_MP4"
  sleep 2
  ffmpeg -i "$SOURCE" $NTSC_OPTS "$NTSC_MPEG"
  export RETVAL=$?
  sleep 1
  if [ $RETVAL -ne 0 ]; then
     echo -e "FFMPEG Error code: $RETVAL"
     sleep 2
     exit $RETVAL;
  else
     echo -e "FFMPEG first encode Source to NTSC MPEG returned $?"
     echo -e "FFMPEG Second encode NTSC MPEG to MP4 starting"
     sleep 1
     ffmpeg -i "$NTSC_MPEG" $FFOPTS264 "$NTSC_MP4"
     export RETVAL=$?
     sleep 2
     if [ $RETVAL -eq 0 ]; then
       rm -fv "$NTSC_MPEG"
       mv -v  "$SOURCE" ..
       mv -v  "$NTSC_MP4" "$TARGET_PREFIX"
       chown 33:1001 "$TARGET_PREFIX" -vR
       chmod g+rw "$TARGET_PREFIX" -vR
       sleep 2
     else
       echo -e "FFMPEG Error code: $RETVAL"
       sleep 2
       exit $RETVAL
     fi
     echo -e "Finished Second encode of $SOURCE. Return Value $RETVAL\n\n"
  fi
done < <(ls -1 *.avi)

exit $RETVAL
