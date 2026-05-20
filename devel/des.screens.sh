Desired Screen Settings
xrandr --listmonitors
Monitors: 3
 0: AOC 1366/410x768/230+554+1080  DP-2
 1: Dell 1280/338x1024/270+1920+952  DVI-1-0
 2: Sanyo 1920/16x1080/9+0+0  HDMI-1-3

xrandr --output DP-2 --primary
xrandr --setmonitor AOC 1366/410x768/230+554+1080  DP-2
xrandr --setmonitor Dell 1280/338x1024/270+1920+952  DVI-1-0
xrandr --setmonitor Sanyo 1920/16x1080/9+0+0  HDMI-1-3
