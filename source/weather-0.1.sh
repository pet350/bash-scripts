if [ ${#TOWN}		-eq 0 ]; then export TOWN="jane-lew";			fi # Other towns that work; clarksburg, buckhannon
if [ ${#WEATHER_URL}	-eq 0 ]; then export WEATHER_URL="http://wttr.in";	fi
if [ ${#SHOWN_WEATHER}	-eq 0 ] &&[ ${#CURL_BIN} -ne 0 ]; then
  case $INTERACTIVE in
    Yes)
      /bin/date
      $CURL_BIN $WEATHER_URL/$TOWN
      export SHOWN_WEATHER="Yes"
      ;;
  esac
fi
