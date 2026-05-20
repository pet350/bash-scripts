#!/bin/bash
function check1()
{
ps axho comm| grep $1 > /dev/null
result=$?
echo "exit code: ${result}"
if [ "${result}" -eq "0" ] ; then
echo "`date`: $SERVICE service running, everything is fine"
else
echo "`date`: $SERVICE is not running"
/etc/init.d/$1 restart
fi
};

function check2()
{
#!/bin/bash
SERVICE=/path/to/my/service
result=$(ps ax|grep -v grep|grep $SERVICE)
echo ${#result}
if  ${#result}> 0
then
        echo " Working!"
else
        echo "Not Working.....Restarting"
        /usr/bin/xvfb-run -a /opt/python27/bin/python2.7 SERVICE &
fi
};

