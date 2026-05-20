!/bin/bash
#
# To cycle through multiple screens for my laptop
# A bit hackish... 
# john bowen



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
        echo "$i is Off, so we'll use this."
        turnOn[$inc]=$i
    else
        #echo "$i is On, we'll shut this off."
        #turnOff[$inc]=$i
    fi
    inc=$(expr $inc + 1)
done

# Let's make sure both screens aren't on, and that we leave at least one screen on.
if [ -z $turnOn ]
then
    echo "we're going to be leaving ${turnOff[1]} turned on"
    turnOn[0]=${turnOff[1]}
    turnOff[1]=" "
fi



### we've gathered info, now let's use it.
xrandr --auto
for i in ${turnOff[*]}
do
    xrandr --output $i --off
done
