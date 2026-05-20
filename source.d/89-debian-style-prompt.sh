# Script  to set the prompt to be more debian-like
# And set it to a color prompt
# Peter Ralbott

case "$TERM" in
  'vt220' | 'xterm-color' | 'xterm-256color' | 'linux')
	color_prompt="yes"
	;;
  *)
	color_prompt="no"
	;;
esac

TEMP="$(tty)"
if [ ${#TEMP} -ne 0 ]; then
  if [ "$TEMP" == "/dev/hvc0" ]; then
	color_prompt="yes"
  fi
fi
unset TEMP

case $color_prompt in
  'yes')
    # A little bit more colorful prompt
    # Bug Fixed!
    TEMP="${debian_chroot:+($debian_chroot)}\[\033[01;36m\]\u\[\033[1;31m\]@\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    # Broken Version
    #TEMP='[\033[01;36m\]\u${debian_chroot:+($debian_chroot)}\033[1;31m@\033[01;32m\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$'

    # Default Color Prompt
    # TEMP='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$'
    ;;
  *)
    TEMP='${debian_chroot:+($debian_chroot)}\u@\h:\w\$'
    ;;
esac

PS1="[$TEMP] "

unset TEMP
unset color_prompt
