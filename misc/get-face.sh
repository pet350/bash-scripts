#!/bin/bash


if [ ${#USER} -eq 0 ]; then
	printf "Finding username: "
	declare -x USER=$(whoami)
else
	printf "Username is already set: "
fi
echo -e $USER

unset DOMAIN
unset AT

declare -x DOMAIN=${USER#*@}
declare -x NAME=${USER%@*}

if [ ${#DOMAIN} -ne 0 ];  then
	DOMAIN=${DOMAIN^^}
	AT='@'
fi

declare -x HOME_DIR="/home/$NAME$AT$DOMAIN"
declare -x FACE="$HOME_DIR/.face"

if [ ${#WAIT} -eq 0 ]; then declare -i WAIT=3; fi

echo -e "Short username: $NAME"
echo -e "Long  username: $USER"
echo -e "Domain  name  : $DOMAIN"
echo -e "Home directory: $HOME_DIR"

jpegPhoto --get --name=$NAME --photo=$FACE --verbose
echo -e "Displaying $FACE for $WAIT seconds"
feh $FACE &
PID=$!
echo -e "feh PID: $PID"
sleep $WAIT
kill -SIGKILL $PID
