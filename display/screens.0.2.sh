#! /bin/bash

#xrandr --setmonitor AOC		auto 554x1080   DP-2
#xrandr --setmonitor Dell	auto 1920x952   DVI-1-0
#xrandr --setmonitor Sanyo	auto 0+0	HDMI-1-3

function init-screens()
{
	declare -ag MONITOR_NAME=( 'AOC' 'Dell' 'Sanyo' )
	declare -ag PORT_NAME=( 'DP-2' 'DVI-1-0' 'HDMI-1-3' )
	declare -ag MAX_RESOLUTION=( '1366x768' '1280x1024' '1920x1080' )
};


xrandr --auto --output DP-2 --mode 1366x768 --pos 544x1080 --primary
xrandr --auto --output DVI-1-0 --mode 1280x1024 --pos 1920x952
xrandr --auto --output HDMI-1-3 --pos 0x0

#xrandr --setmonitor AOC 1366/410x768/230+554+1080  DP-2
#xrandr --setmonitor Dell 1280/338x1024/270+1920+952  DVI-1-0
#xrandr --setmonitor Sanyo 1920/16x1080/9+0+0  HDMI-1-3
