#!/bin/sh

for f in *.m4a; do
  ffmpeg -i "$f" -codec:v copy -codec:a libmp3lame -q:a 2 "${f%.m4a}.mp3"
done

for f in *.webm; do
  ffmpeg -i "$f" -codec:v copy -codec:a libmp3lame -q:a 2 "${f%.webm}.mp3"
done
