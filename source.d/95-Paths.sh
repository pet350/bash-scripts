GAME_LAUNCHERS="/usr/local/games"

if [ -d "$GAME_LAUNCHERS" ]; then
    export PATH="$PATH:$GAME_LAUNCHERS"
fi

unset GAME_LAUNCHERS
