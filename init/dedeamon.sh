#!/bin/sh
daemon --name="DoorEvent" --delay=90 --limit=60 --env="BOL_DISPLAY=0"--env="BOL_LOG_KERN=1" --env="BOL_LOG_FILE=1" --pidfile /run/DoorEvent.pid --inherit --respawn --unsafe --command=/usr/local/sbin/DoorEvent.sh
