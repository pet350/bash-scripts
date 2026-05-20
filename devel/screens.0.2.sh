#!/bin/bash

# To cycle through multiple screen outputs
# And turn on all that are connected
# A bit hackish...
# Origonal Code: john bowen
# Higly Modified: Peter Talbott

declare -A screensOn
inc=0
screens=$(xrandr -q | grep "[^dis]connected")
while read line
do
    screenNames[$inc]=$(echo $line | cut -d" " -f1 )
    if [[ $(grep '+' <<< $line) ]] # The "+" indicates a viewport
        then
        screensOn[${screenNames[$inc]}]=1
    else
        screensOn[${screenNames[$inc]}]=0
    fi
    inc=$(expr $inc + 1)

done <<< "$screens"

inc=0
for i in ${screenNames[*]}
do
    if [[ ${screensOn[$i]} == 0 ]]
    then
        echo "$i is Off, so we'll turn it on."
        turnOn[$inc]=$i
    fi
    inc=$(expr $inc + 1)
done

### "we've gathered info, now let's use it."
xrandr --auto
for i in ${turnOff[*]}
do
    xrandr --output $i --off
done

xrandr --output DP-2 --primary
xrandr --setmonitor AOC 1366/410x768/230+554+1080  DP-2
xrandr --setmonitor Dell 1280/338x1024/270+1920+952  DVI-1-0
xrandr --setmonitor Sanyo 1920/16x1080/9+0+0  HDMI-1-3
