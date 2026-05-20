#!/bin/bash

declare -x PLAYLISTITEM="<PlaylistItem>"
declare -x PATHITEM="<Path>"
declare -x CLOSE_PATH="</Path>"
declare -x CLOSE_PLAYLISTITEM="</PlaylistItem>"

if [ ${#JELLYFIN_DIR}	-eq 0 ]; then declare -x JELLYFIN_DIR="/var/lib/jellyfin/catalog/porn";			fi
if [ ${#PLAYLIST_DIR}	-eq 0 ]; then declare -x PLAYLIST_DIR="/var/lib/jellyfin/data/playlists/Playlist";	fi
if [ ${#DEVNULL} 	-eq 0 ]; then declare -x DEVNULL="/dev/null";						fi
if [ ${#OUTPUT}		-eq 0 ]; then declare -x OUTPUT="/dev/stderr";						fi

function CREATE_PLAYLIST()
{
  declare -x LETTER=$1
  LETTER=${LETTER^^}

  declare -x PLAYLIST_PREFIX="<?xml version="1.0" encoding="utf-8" standalone="yes"?>\n<Item>\n  <ContentRating>XXX</ContentRating>\n  <Added>08/01/2023 06:26:13</Added>\n  <LockData>false</LockData>\n  <LocalTitle>Playlist $LETTER</LocalTitle>\n  <Genres>\n    <Genre>Anal</Genre>\n    <Genre>Ass to Mouth</Genre>\n    <Genre>Big Butt</Genre>\n    <Genre>Big Dick</Genre>\n    <Genre>Blow Job</Genre>\n    <Genre>Brunette</Genre>\n    <Genre>Cum Shot</Genre>\n    <Genre>Cum Swap</Genre>\n    <Genre>Deep Throat</Genre>\n    <Genre>Enema</Genre>\n    <Genre>Face Fucking</Genre>\n    <Genre>Face Sitting</Genre>\n    <Genre>Facial</Genre>\n    <Genre>Fetish</Genre>\n    <Genre>Fingering</Genre>\n    <Genre>Gagging</Genre>\n    <Genre>Girl-Girl</Genre>\n    <Genre>Natural Tits</Genre>\n    <Genre>Pussy Eating</Genre>\n    <Genre>Rim Job</Genre>\n    <Genre>Shaven Pussy</Genre>\n    <Genre>Small Tits</Genre>\n    <Genre>Squirting</Genre>\n    <Genre>Tattoo</Genre>\n    <Genre>Threesome</Genre>\n    <Genre>Big Tits</Genre>\n    <Genre>Blonde</Genre>\n    <Genre>Hardcore</Genre>\n    <Genre>Lingerie</Genre>\n    <Genre>MILF</Genre>\n    <Genre>Behind The Scenes</Genre>\n    <Genre>Interview</Genre>\n    <Genre>Outdoors</Genre>\n    <Genre>Tribbing</Genre>\n    <Genre>69 (Position)</Genre>\n    <Genre>Adult Time Original</Genre>\n    <Genre>Coeds</Genre>\n    <Genre>Family Roleplay</Genre>\n    <Genre>Lesbian</Genre>\n    <Genre>Masturbation</Genre>\n    <Genre>Old Young</Genre>\n    <Genre>Step Daughter</Genre>\n    <Genre>Step Mom</Genre>\n    <Genre>Ass</Genre>\n    <Genre>Redhead</Genre>\n    <Genre>Teen</Genre>\n    <Genre>Comedy</Genre>\n    <Genre>Bdsm</Genre>\n    <Genre>Creampie</Genre>\n    <Genre>Domination</Genre>\n    <Genre>Hand Job</Genre>\n    <Genre>Original Series</Genre>\n    <Genre>Reality Porn</Genre>\n    <Genre>Spanking</Genre>\n    <Genre>Submissive</Genre>\n    <Genre>Toys</Genre>\n    <Genre>Award-Winning</Genre>\n    <Genre>Hairy Pussy</Genre>\n    <Genre>Orgy</Genre>\n    <Genre>Solo</Genre>\n    <Genre>Anal Fingering</Genre>\n    <Genre>Ball Play</Genre>\n    <Genre>Black Hair</Genre>\n    <Genre>Doggystyle (Position)</Genre>\n    <Genre>Double Anal Penetration (DAP)</Genre>\n    <Genre>Double Penetration (DP)</Genre>\n    <Genre>Double Pussy Penetration (DPP)</Genre>\n    <Genre>Gaping</Genre>\n    <Genre>Group Sex</Genre>\n    <Genre>Kissing</Genre>\n    <Genre>Rough Sex</Genre>\n    <Genre>Stockings</Genre>\n    <Genre>Piercing</Genre>\n    <Genre>Interracial</Genre>\n    <Genre>Cum On Tits</Genre>\n    <Genre>Ebony</Genre>\n    <Genre>Gangbang</Genre>\n    <Genre>Heterosexual</Genre>\n    <Genre>Pussy To Mouth</Genre>\n    <Genre>Thriller</Genre>\n    <Genre>Art</Genre>\n    <Genre>Boobs</Genre>\n    <Genre>Couple Friendly</Genre>\n    <Genre>Erotica</Genre>\n    <Genre>European</Genre>\n    <Genre>European Pornstar</Genre>\n    <Genre>Girls Kissing</Genre>\n    <Genre>Glamorous</Genre>\n    <Genre>Lesbian Makeout</Genre>\n    <Genre>Make Love</Genre>\n    <Genre>Moaning</Genre>\n    <Genre>Passionate</Genre>\n    <Genre>Romance</Genre>\n    <Genre>Romanian</Genre>\n    <Genre>Romantic</Genre>\n    <Genre>Sensual</Genre>\n    <Genre>Tits</Genre>\n    <Genre>Ukrainian</Genre>\n    <Genre>Action</Genre>\n    <Genre>Adventure</Genre>\n    <Genre>Fantasy</Genre>\n    <Genre>Feature</Genre>\n    <Genre>Adulttime Original</Genre>\n    <Genre>Short</Genre>\n    <Genre>Petite</Genre>\n    <Genre>Asian</Genre>\n    <Genre>Latina</Genre>\n  </Genres>\n  <Studios>\n    <Studio>Evil Angel</Studio>\n    <Studio>Adult Time</Studio>\n    <Studio>RealSensual</Studio>\n    <Studio>Girlsway</Studio>\n    <Studio>Mommys Girl</Studio>\n    <Studio>Defining</Studio>\n    <Studio>Punch Media</Studio>\n    <Studio>Adult Time Originals</Studio>\n    <Studio>Karagiannis-Karatzopoulos</Studio>\n    <Studio>Vivid</Studio>\n    <Studio>Fame Digital</Studio>\n    <Studio>North Pole Production</Studio>\n    <Studio>Getaway Pictures</Studio>\n    <Studio>Phiphen Pictures</Studio>\n    <Studio>SE Film Production</Studio>\n    <Studio>Porndoe Premium</Studio>\n    <Studio>A Girl Knows</Studio>\n    <Studio>Lucasfilm Ltd.</Studio>\n    <Studio>20th Century Fox</Studio>\n    <Studio>Devil's Film</Studio>\n    <Studio>Devils Film</Studio>\n  </Studios>\n  <PlaylistItems>"
  declare -x PLAYLIST_SUFFIX="  </PlaylistItems>\n  <Shares>\n    <Share>\n      <UserId>93e2badccba3412cad3454975e60abb7</UserId>\n      <CanEdit>true</CanEdit>\n    </Share>\n  </Shares>\n  <PlaylistMediaType>Video</PlaylistMediaType>\n</Item>\n"
  declare -x CURRENT_DATA_DIR="$JELLYFIN_DIR/$LETTER"
  declare -x CURRENT_LIST_DIR="$PLAYLIST_DIR $LETTER"

  if [ -f "$CURRENT_LIST_DIR"/playlist.xml ]; then mv -v "$CURRENT_LIST_DIR"/playlist.xml "$CURRENT_LIST_DIR"/playlist.xml.old; fi

  echo -e "$PLAYLIST_PREFIX" | tee "$CURRENT_LIST_DIR"/playlist.xml $OUTPUT >$DEVNULL 2>$DEVNULL

  while IFS= read LINE; do
      printf "\t%s\n\t    %s%s%s\n\t%s\n" "$PLAYLISTITEM" "$PATHITEM" "$LINE" "$CLOSE_PATH" "$CLOSE_PLAYLISTITEM" | tee -a "$CURRENT_LIST_DIR"/playlist.xml $OUTPUT >$DEVNULL 2>$DEVNULL
  done < <(ls -t1 "$CURRENT_DATA_DIR"/*.mp4; RETVAL=$?);

  echo -e "$PLAYLIST_SUFFIX" | tee -a "$CURRENT_LIST_DIR"/playlist.xml $OUTPUT >$DEVNULL 2>$DEVNULL

  return $RETVAL
};

for DATA in {a..z}; do
    CREATE_PLAYLIST $DATA
done




